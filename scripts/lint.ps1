#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Lint the LLM-Wiki knowledge base (see CLAUDE.md ยง9.3).

.DESCRIPTION
  Reproducible health checks for the wiki:
    1. Broken [[wikilinks]]   - link target has no matching page in the vault
    2. Orphan pages           - concept page with no inbound links and not in any MOC
    3. Index coverage gaps    - concept page on disk but not listed in index.md
    4. Stale mature pages     - status: mature with `updated:` older than -StaleMonths

  Placeholder/example links in templates/ and CLAUDE.md are ignored by design
  (they demonstrate syntax, e.g. [[concept-one]], and are not real targets).

.PARAMETER Root
  Repo root. Defaults to the parent of this script's folder.

.PARAMETER StaleMonths
  Age (months) past which a `mature` page is flagged for re-review. Default 6.

.EXAMPLE
  pwsh scripts/lint.ps1
  pwsh scripts/lint.ps1 -StaleMonths 3

.OUTPUTS
  Human-readable report to stdout. Exit code 1 if any broken links are found
  (so it can gate CI), else 0.
#>
[CmdletBinding()]
param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [int]$StaleMonths = 6
)

$ErrorActionPreference = 'Stop'

# Targets that are illustrative examples in the schema/templates, not real pages.
$ignoreTargets = @(
  '...', 'alias', 'link', 'links', 'wikilink', 'wikilinks',
  'concept-one', 'concept-two', 'related-concept-one', 'related-concept-two',
  'wiki page', 'slug'
) | ForEach-Object { $_.ToLowerInvariant() }

# Files we do NOT treat as link sources (they contain placeholder examples).
$linkSourceExclude = @('templates', '.git', '.obsidian', 'scripts')

$allMd = Get-ChildItem -Path $Root -Recurse -Filter *.md |
  Where-Object { $_.FullName -notmatch '\\(\.git|\.obsidian)\\' }

$basenames = $allMd | ForEach-Object { $_.BaseName.ToLowerInvariant() } | Sort-Object -Unique

# Valid wikilink targets = every vault file resolvable by basename OR full name
# (so embeds like [[dashboard.base]] or images resolve, not just .md pages).
$allFiles = Get-ChildItem -Path $Root -Recurse -File |
  Where-Object { $_.FullName -notmatch '\\(\.git|\.obsidian)\\' }
$validTargets = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($x in $allFiles) {
  [void]$validTargets.Add($x.Name.ToLowerInvariant())
  [void]$validTargets.Add($x.BaseName.ToLowerInvariant())
}

function Get-LinkTargets {
  param([string]$Text)
  $out = @()
  foreach ($m in [regex]::Matches($Text, '\[\[([^\]]+?)\]\]')) {
    $t = $m.Groups[1].Value
    $t = ($t -split '\|')[0]          # drop display text
    $t = ($t -split '#')[0]           # drop heading anchor
    $t = $t -replace '\\$',''         # drop trailing escape backslash
    $t = ($t -split '/')[-1]          # last path segment
    $t = $t.Trim()
    if ($t) { $out += $t }
  }
  return $out
}

$conceptFiles = $allMd | Where-Object { $_.FullName -match '\\wiki\\concepts\\' }
$mocFiles     = $allMd | Where-Object { $_.FullName -match '\\wiki\\moc\\' }

# --- gather all link targets + which page each concept is linked FROM ---
$broken = @()                 # @{ target; from }
$inbound = @{}                # basename(lower) -> count of inbound links
foreach ($b in ($conceptFiles | ForEach-Object { $_.BaseName.ToLowerInvariant() })) { $inbound[$b] = 0 }

foreach ($f in $allMd) {
  $rel = $f.FullName.Substring($Root.Length).TrimStart('\','/')
  $isExcludedSource = $false
  foreach ($ex in $linkSourceExclude) { if ($rel -match "(^|\\)$ex(\\|$)") { $isExcludedSource = $true } }
  if ($f.BaseName -eq 'CLAUDE') { $isExcludedSource = $true }   # schema has example links
  $txt = Get-Content -Raw -LiteralPath $f.FullName
  foreach ($t in (Get-LinkTargets $txt)) {
    $tl = $t.ToLowerInvariant()
    if ($ignoreTargets -contains $tl) { continue }
    if (-not $validTargets.Contains($tl)) {
      if (-not $isExcludedSource) { $broken += [pscustomobject]@{ target = $t; from = $rel } }
      continue
    }
    if ($inbound.ContainsKey($tl)) { $inbound[$tl]++ }
  }
}

# --- MOC membership ---
$inSomeMoc = @{}
foreach ($f in $mocFiles) {
  $txt = Get-Content -Raw -LiteralPath $f.FullName
  foreach ($t in (Get-LinkTargets $txt)) { $inSomeMoc[$t.ToLowerInvariant()] = $true }
}

# --- index.md coverage ---
$indexPath = Join-Path $Root 'index.md'
$indexTargets = @{}
if (Test-Path $indexPath) {
  foreach ($t in (Get-LinkTargets (Get-Content -Raw -LiteralPath $indexPath))) { $indexTargets[$t.ToLowerInvariant()] = $true }
}

# --- frontmatter parse for stale check ---
function Get-Frontmatter {
  param([string]$Text)
  $h = @{}
  if ($Text -match '(?s)^\s*---\s*\r?\n(.*?)\r?\n---') {
    foreach ($line in ($Matches[1] -split '\r?\n')) {
      if ($line -match '^\s*([A-Za-z_]+)\s*:\s*(.*)$') { $h[$Matches[1]] = $Matches[2].Trim().Trim('"') }
    }
  }
  return $h
}

$orphans = @()
$notInIndex = @()
$stale = @()
$now = Get-Date
foreach ($f in $conceptFiles) {
  $b = $f.BaseName.ToLowerInvariant()
  if (($inbound[$b] -eq 0) -and (-not $inSomeMoc.ContainsKey($b))) { $orphans += $f.BaseName }
  if (-not $indexTargets.ContainsKey($b)) { $notInIndex += $f.BaseName }
  $fm = Get-Frontmatter (Get-Content -Raw -LiteralPath $f.FullName)
  if ($fm['status'] -eq 'mature' -and $fm['updated']) {
    $u = $null
    try { $u = [datetime]::Parse($fm['updated'], [System.Globalization.CultureInfo]::InvariantCulture) } catch { $u = $null }
    if ($u -and $u -lt $now.AddMonths(-$StaleMonths)) {
      $stale += [pscustomobject]@{ page = $f.BaseName; updated = $fm['updated'] }
    }
  }
}

# --- house style (see CLAUDE.md §8): scan wiki/ pages only ---
# templates/ and CLAUDE.md legitimately describe/illustrate the rules, so are excluded.
$houseViol = @()
$wikiPages = $allMd | Where-Object { $_.FullName -match '\\wiki\\' }
foreach ($f in $wikiPages) {
  $rel = $f.FullName.Substring($Root.Length).TrimStart('\','/')
  $txt = Get-Content -Raw -LiteralPath $f.FullName
  if ($txt -match '(?m)^(priority|roadmap_ref):')       { $houseViol += "$rel : priority/roadmap_ref in frontmatter" }
  if ($txt -match '\*\*Priority:\*\*|\*\*Roadmap:\*\*')  { $houseViol += "$rel : Priority/Roadmap in context line" }
  if ($txt -match '(?m)^#{1,6}\s.*\(20\d\d')             { $houseViol += "$rel : year in a heading" }
  if ($txt -match '(?i)\bsenior architect\b|\bveteran\b|\b15\+ year') { $houseViol += "$rel : role/persona framing" }
}

# --- report ---
"=============================================================="
" Knowledge Base Lint  -  $($conceptFiles.Count) concept pages, $($allMd.Count) md files"
" Root: $Root   Stale threshold: $StaleMonths months"
"=============================================================="
""
"[1] Broken wikilinks: $($broken.Count)"
foreach ($x in ($broken | Sort-Object target, from)) { "      [[$($x.target)]]  <- $($x.from)" }
""
"[2] Orphan pages (no inbound links, not in any MOC): $($orphans.Count)"
foreach ($o in ($orphans | Sort-Object)) { "      $o" }
""
"[3] Concept pages missing from index.md: $($notInIndex.Count)"
foreach ($n in ($notInIndex | Sort-Object)) { "      $n" }
""
"[4] Stale 'mature' pages (updated > $StaleMonths months): $($stale.Count)"
foreach ($s in ($stale | Sort-Object page)) { "      $($s.page)  (updated: $($s.updated))" }
""
"[5] House-style violations (no priority/roadmap, no year/role; see CLAUDE.md §8): $($houseViol.Count)"
foreach ($h in ($houseViol | Sort-Object)) { "      $h" }
""
"--------------------------------------------------------------"
$fail = ($broken.Count -gt 0) -or ($houseViol.Count -gt 0)
if (-not $fail) { " PASS: no broken links, no house-style violations." }
else { " FAIL: $($broken.Count) broken link(s), $($houseViol.Count) house-style violation(s)." }
"--------------------------------------------------------------"

if ($fail) { exit 1 } else { exit 0 }
