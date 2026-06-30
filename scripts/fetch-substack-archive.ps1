#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Inspect a Substack publication's archive API and report which recent posts are
  NEW (not yet ingested) vs already in raw/ (see CLAUDE.md §9.4 "Substack archive ingest").

.DESCRIPTION
  Reads the publication registry scripts/substack-sources.json, hits the chosen
  publication's archive JSON API
    https://<host>/api/v1/archive?sort=new&search=&offset=<Offset>&limit=<Limit>
  and cross-checks each returned post against the sources already captured under raw/.

  The match key is the recorded `source_url:` frontmatter value (= the post's
  canonical_url), NOT the raw filename — raw slugs are hand-chosen and differ from
  the Substack slug. URLs are normalized (protocol, leading www., trailing slash,
  query/fragment stripped) before comparison.

  This script is READ-ONLY: it does not scrape post bodies and does not write any
  raw/ files. It only tells you what is new and proposes a raw filename + the next
  sequence number for the series. The actual ingest is the LLM-driven workflow in
  CLAUDE.md §9.1 / §9.4 (firecrawl for free posts, authenticated Chrome for paid).

.PARAMETER Source
  Publication key into scripts/substack-sources.json (e.g. decodingai, theneuralmaze).

.PARAMETER Limit
  How many recent posts to fetch from the archive (default 15).

.PARAMETER Offset
  Archive pagination offset (default 0). Use with -Limit to page back further.

.PARAMETER IncludeIngested
  Also list the already-ingested posts (dimmed) below the NEW ones.

.PARAMETER Root
  Repo root. Defaults to the parent of this script's folder.

.EXAMPLE
  pwsh scripts/fetch-substack-archive.ps1 -Source decodingai

.EXAMPLE
  pwsh scripts/fetch-substack-archive.ps1 -Source theneuralmaze -Limit 25 -IncludeIngested

.OUTPUTS
  A human-readable NEW-vs-INGESTED report to stdout. Throws on config/API failure.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Source,
  [int]$Limit = 15,
  [int]$Offset = 0,
  [switch]$IncludeIngested,
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

# --- resolve the publication from the registry ---
$registryPath = Join-Path $PSScriptRoot 'substack-sources.json'
if (-not (Test-Path -LiteralPath $registryPath)) { throw "Registry not found: $registryPath" }
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json

# valid keys = registry properties except the leading-underscore meta keys
$validKeys = $registry.PSObject.Properties.Name | Where-Object { -not $_.StartsWith('_') }
if ($Source -notin $validKeys) {
  throw "Unknown source '$Source'. Valid keys: $($validKeys -join ', ')"
}
$pub = $registry.$Source
$host_   = $pub.host
$series  = $pub.series
$title   = $pub.title

# --- normalize a URL for comparison (protocol, www., trailing slash, query/fragment) ---
function Get-NormalizedUrl {
  param([string]$Url)
  if (-not $Url) { return '' }
  $u = $Url.Trim().Trim('"', "'").ToLowerInvariant()
  $u = $u -replace '^https?://', ''
  $u = $u -replace '^www\.', ''
  $u = $u -replace '[?#].*$', ''
  $u = $u.TrimEnd('/')
  return $u
}

# --- build the set of already-ingested canonical URLs from raw/ frontmatter ---
$rawDir = Join-Path $Root 'raw'
$ingested = [System.Collections.Generic.HashSet[string]]::new()
if (Test-Path -LiteralPath $rawDir) {
  Get-ChildItem -LiteralPath $rawDir -Filter '*.md' -File | ForEach-Object {
    foreach ($line in (Get-Content -LiteralPath $_.FullName)) {
      if ($line -match '^\s*source_url:\s*(.+?)\s*$') {
        [void]$ingested.Add((Get-NormalizedUrl $Matches[1]))
        break   # source_url lives in frontmatter; stop after the first hit
      }
    }
  }
}

# --- next sequence number for this series (max NN over raw/ filenames, +1) ---
$seqRegex = "^\d{4}-\d{2}-\d{2}-$([regex]::Escape($series))-(\d+)-"
$maxSeq = 0
if (Test-Path -LiteralPath $rawDir) {
  Get-ChildItem -LiteralPath $rawDir -Filter '*.md' -File | ForEach-Object {
    if ($_.Name -match $seqRegex) {
      $n = [int]$Matches[1]
      if ($n -gt $maxSeq) { $maxSeq = $n }
    }
  }
}
$nextSeq = $maxSeq + 1
$today = Get-Date -Format 'yyyy-MM-dd'

# --- fetch the archive ---
$api = "https://$host_/api/v1/archive?sort=new&search=&offset=$Offset&limit=$Limit"
Write-Host "Fetching $title archive: $api" -ForegroundColor Cyan
$posts = Invoke-RestMethod -Uri $api -Headers @{ 'Accept' = 'application/json' }
if (-not $posts) { Write-Host 'No posts returned.' -ForegroundColor Yellow; return }

# --- partition into NEW vs INGESTED, preserving archive order (newest first) ---
$new = @()
$old = @()
foreach ($p in $posts) {
  if ($ingested.Contains((Get-NormalizedUrl $p.canonical_url))) { $old += $p } else { $new += $p }
}

# --- report ---
""
Write-Host "NEW posts in $title archive ($($new.Count)):" -ForegroundColor White
if ($new.Count -eq 0) {
  Write-Host '  (none — archive head is fully ingested)' -ForegroundColor DarkGray
} else {
  $seq = $nextSeq
  foreach ($p in $new) {
    $date = ([string]$p.post_date).Substring(0, 10)
    $aud  = if ($p.audience -eq 'everyone') { 'free     ' } else { "$($p.audience)" }
    $nn   = '{0:D2}' -f $seq
    $colr = if ($p.audience -eq 'everyone') { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1}  {2}  {3}" -f $nn, $date, $aud, $p.title) -ForegroundColor $colr
    Write-Host ("        url:  {0}" -f $p.canonical_url) -ForegroundColor DarkGray
    Write-Host ("        file: {0}-{1}-{2}-{3}.md" -f $today, $series, $nn, $p.slug) -ForegroundColor DarkGray
    $seq++
  }
}

if ($IncludeIngested) {
  ""
  Write-Host "Already ingested ($($old.Count)):" -ForegroundColor White
  foreach ($p in $old) {
    $date = ([string]$p.post_date).Substring(0, 10)
    Write-Host ("  - {0}  {1}" -f $date, $p.title) -ForegroundColor DarkGray
  }
}

""
Write-Host "DONE: $($new.Count) new, $($old.Count) ingested (of $($posts.Count) fetched). Next $series seq = $('{0:D2}' -f $nextSeq)." -ForegroundColor Cyan
