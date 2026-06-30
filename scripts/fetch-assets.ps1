#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Download a curated list of image URLs into a source's local asset folder
  (see CLAUDE.md §3 "Asset naming" and §9.1 Ingest).

.DESCRIPTION
  Localizes the *valuable* visuals of an ingested source — original diagrams,
  architecture/sequence figures, charts, annotated screenshots — so the wiki no
  longer depends on third-party CDNs that rot, rename, or paywall.

  Images are written to  raw/assets/<slug>/  and named  <slug>-NN.<ext>  so every
  basename is unique across the vault (Obsidian and scripts/lint.ps1 both resolve
  [[embeds]] by basename). The extension is inferred from the URL path, falling
  back to the HTTP Content-Type. Existing files are skipped, so re-runs are
  idempotent.

  Curate BEFORE calling this — pass only the keepers. Drop chrome: avatars,
  author/profile pics, logos, sponsor/ad banners, social buttons, decorative hero
  images, comment-thread images.

  For each downloaded file the script prints a ready-to-paste Obsidian embed line
  (and caption, if supplied) for the source note / concept page.

.PARAMETER Slug
  The source slug — the raw/ note's basename without date is fine, but prefer the
  full slug for unique basenames (e.g. 2026-06-30-graphrag-01-foo). Used as the
  asset sub-folder name and the filename prefix.

.PARAMETER Url
  One or more image URLs to download.

.PARAMETER UrlFile
  Path to a text file with one entry per line: `<url>` or `<url> | <caption>`.
  Blank lines and lines starting with `#` are ignored. Combine with -Url if you like.

.PARAMETER StartIndex
  First sequence number for filenames (default 1). Use this to append to a folder
  that already has NN files without renumbering.

.PARAMETER Root
  Repo root. Defaults to the parent of this script's folder.

.EXAMPLE
  pwsh scripts/fetch-assets.ps1 -Slug 2026-06-30-foo -Url "https://host/diagram.png"

.EXAMPLE
  pwsh scripts/fetch-assets.ps1 -Slug 2026-06-30-foo -UrlFile urls.txt

.OUTPUTS
  Paste-ready Markdown embed lines to stdout. Exit code 1 if any download failed.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Slug,
  [string[]]$Url = @(),
  [string]$UrlFile,
  [int]$StartIndex = 1,
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

# --- assemble the work list: @{ url; caption } ---
$items = @()
foreach ($u in $Url) {
  if ($u -and $u.Trim()) { $items += [pscustomobject]@{ url = $u.Trim(); caption = '' } }
}
if ($UrlFile) {
  if (-not (Test-Path -LiteralPath $UrlFile)) { throw "UrlFile not found: $UrlFile" }
  foreach ($line in (Get-Content -LiteralPath $UrlFile)) {
    $t = $line.Trim()
    if (-not $t -or $t.StartsWith('#')) { continue }
    $parts = $t -split '\s*\|\s*', 2
    $cap = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }
    $items += [pscustomobject]@{ url = $parts[0].Trim(); caption = $cap }
  }
}
if ($items.Count -eq 0) { throw 'Nothing to download. Pass -Url and/or -UrlFile.' }

# --- ensure the asset folder exists ---
$assetDir = Join-Path $Root (Join-Path 'raw\assets' $Slug)
if (-not (Test-Path -LiteralPath $assetDir)) {
  New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
}

# map a Content-Type to a file extension (fallback when the URL has none)
function Get-ExtFromContentType {
  param([string]$ContentType)
  switch -Regex ($ContentType) {
    'image/png'                 { return 'png' }
    'image/jpe?g'               { return 'jpg' }
    'image/gif'                 { return 'gif' }
    'image/svg'                 { return 'svg' }
    'image/webp'                { return 'webp' }
    'image/avif'                { return 'avif' }
    default                     { return 'png' }
  }
}

$i = $StartIndex
$failed = 0
$emitted = @()

foreach ($it in $items) {
  $nn = '{0:D2}' -f $i

  # infer extension from the URL path (strip query/fragment), else from Content-Type later
  $ext = ''
  try {
    $path = ([uri]$it.url).AbsolutePath
    $cand = [System.IO.Path]::GetExtension($path).TrimStart('.').ToLowerInvariant()
    if ($cand -match '^(png|jpg|jpeg|gif|svg|webp|avif)$') { $ext = ($cand -replace '^jpeg$', 'jpg') }
  } catch { }

  # provisional name; we may fix the extension after we see the response
  $name = "$Slug-$nn"
  $existing = Get-ChildItem -LiteralPath $assetDir -Filter "$name.*" -ErrorAction SilentlyContinue
  if ($existing) {
    Write-Host "skip  $($existing[0].Name) (exists)" -ForegroundColor DarkGray
    $emitted += [pscustomobject]@{ file = $existing[0].Name; caption = $it.caption }
    $i++
    continue
  }

  try {
    $tmp = Join-Path $assetDir "$name.download"
    $resp = Invoke-WebRequest -Uri $it.url -OutFile $tmp -PassThru -UseBasicParsing
    if (-not $ext) { $ext = Get-ExtFromContentType $resp.Headers['Content-Type'] }
    $final = "$name.$ext"
    Move-Item -LiteralPath $tmp -Destination (Join-Path $assetDir $final) -Force
    Write-Host "ok    $final  <- $($it.url)" -ForegroundColor Green
    $emitted += [pscustomobject]@{ file = $final; caption = $it.caption }
  } catch {
    Write-Warning "FAIL  $($it.url)  ($($_.Exception.Message))"
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    $failed++
  }
  $i++
}

# --- emit paste-ready embeds ---
""
"--- paste into the source note / concept page ---"
foreach ($e in $emitted) {
  $alt = ($e.file -replace '\.[^.]+$', '')
  if ($e.caption) {
    "![[$($e.file)|$($e.caption)]]"
    "*Figure: $($e.caption) — source [[$Slug]].*"
  } else {
    "![[$($e.file)|$alt]]"
    "*Figure: <caption> — source [[$Slug]].*"
  }
  ""
}

""
"DONE: $($emitted.Count) saved, $failed failed."
if ($failed -gt 0) { exit 1 } else { exit 0 }
