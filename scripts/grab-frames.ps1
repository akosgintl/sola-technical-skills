#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Extract diagram frames from a video into a source's local asset folder
  (see CLAUDE.md §9.1 Ingest — "Transcript + key frames").

.DESCRIPTION
  Companion to the `yt-transcribe` skill: that captures what a video *says*; this
  captures the diagrams it *shows*. Give it the timestamps where a worthwhile
  diagram/architecture slide is on screen and it writes one PNG per timestamp to
  raw/assets/<slug>/<slug>-frame-NN.png — the same durable, uniquely-named layout
  fetch-assets.ps1 uses.

  Source can be a URL (downloaded once via yt-dlp into the scratch dir) or a local
  video file. Requires yt-dlp (URLs only) and ffmpeg on PATH; if either is missing
  the script stops with a pointer to the `update-tooling` skill.

  For each frame it prints a ready-to-paste Obsidian embed line + caption stub.

.PARAMETER Slug
  The source slug — asset sub-folder name and filename prefix (use the full raw/
  note slug for unique basenames).

.PARAMETER Url
  Video URL (YouTube or any yt-dlp-supported host). Mutually exclusive with -Video.

.PARAMETER Video
  Path to a local video file. Mutually exclusive with -Url.

.PARAMETER Timestamps
  Comma-separated seek positions, ffmpeg syntax: "00:01:23,00:04:10" or "83,250".

.PARAMETER StartIndex
  First frame sequence number (default 1).

.PARAMETER Root
  Repo root. Defaults to the parent of this script's folder.

.EXAMPLE
  pwsh scripts/grab-frames.ps1 -Slug 2026-06-30-talk -Url "https://youtu.be/XXXX" -Timestamps "00:02:15,00:07:40"

.EXAMPLE
  pwsh scripts/grab-frames.ps1 -Slug 2026-06-30-talk -Video C:\dl\talk.mp4 -Timestamps "135,460"

.OUTPUTS
  Paste-ready Markdown embed lines to stdout. Exit code 1 on any extraction failure.
#>
[CmdletBinding(DefaultParameterSetName = 'Url')]
param(
  [Parameter(Mandatory = $true)][string]$Slug,
  [Parameter(Mandatory = $true, ParameterSetName = 'Url')][string]$Url,
  [Parameter(Mandatory = $true, ParameterSetName = 'Video')][string]$Video,
  [Parameter(Mandatory = $true)][string]$Timestamps,
  [int]$StartIndex = 1,
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

function Assert-Tool {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required tool '$Name' not found on PATH. Install/refresh it with the 'update-tooling' skill, then retry."
  }
}

Assert-Tool ffmpeg
if ($PSCmdlet.ParameterSetName -eq 'Url') { Assert-Tool yt-dlp }

$stamps = @($Timestamps -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($stamps.Count -eq 0) { throw 'No timestamps parsed from -Timestamps.' }

# --- resolve the video file ---
$cleanup = $null
if ($PSCmdlet.ParameterSetName -eq 'Url') {
  $scratch = Join-Path ([System.IO.Path]::GetTempPath()) "grab-frames-$([guid]::NewGuid().ToString('N'))"
  New-Item -ItemType Directory -Path $scratch -Force | Out-Null
  $cleanup = $scratch
  $outTpl = Join-Path $scratch 'video.%(ext)s'
  Write-Host "Downloading video via yt-dlp..." -ForegroundColor Cyan
  & yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best' -o $outTpl $Url
  if ($LASTEXITCODE -ne 0) { throw "yt-dlp failed (exit $LASTEXITCODE)." }
  $videoPath = (Get-ChildItem -LiteralPath $scratch -File | Select-Object -First 1).FullName
} else {
  if (-not (Test-Path -LiteralPath $Video)) { throw "Video file not found: $Video" }
  $videoPath = (Resolve-Path -LiteralPath $Video).Path
}

# --- ensure asset folder ---
$assetDir = Join-Path $Root (Join-Path 'raw\assets' $Slug)
if (-not (Test-Path -LiteralPath $assetDir)) {
  New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
}

$i = $StartIndex
$failed = 0
$emitted = @()

try {
  foreach ($ts in $stamps) {
    $nn = '{0:D2}' -f $i
    $file = "$Slug-frame-$nn.png"
    $dest = Join-Path $assetDir $file
    if (Test-Path -LiteralPath $dest) {
      Write-Host "skip  $file (exists)" -ForegroundColor DarkGray
      $emitted += [pscustomobject]@{ file = $file; ts = $ts }
      $i++
      continue
    }
    # -ss before -i = fast seek; -frames:v 1 = single frame
    & ffmpeg -loglevel error -ss $ts -i $videoPath -frames:v 1 -q:v 2 -y $dest
    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $dest)) {
      Write-Host "ok    $file  @ $ts" -ForegroundColor Green
      $emitted += [pscustomobject]@{ file = $file; ts = $ts }
    } else {
      Write-Warning "FAIL  frame @ $ts (ffmpeg exit $LASTEXITCODE)"
      $failed++
    }
    $i++
  }
} finally {
  if ($cleanup -and (Test-Path -LiteralPath $cleanup)) {
    Remove-Item -LiteralPath $cleanup -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# --- emit paste-ready embeds ---
""
"--- paste into the source note / concept page ---"
foreach ($e in $emitted) {
  "![[$($e.file)|frame @ $($e.ts)]]"
  "*Figure: <caption> (video @ $($e.ts)) — source [[$Slug]].*"
  ""
}

if ($failed -gt 0) { exit 1 } else { exit 0 }
