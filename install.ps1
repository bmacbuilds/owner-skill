# Installs Owner on Windows: /owner and each of its commands as its own, one folder each in
# %USERPROFILE%\.claude\skills\, and nothing else on the computer.
#
#   powershell -ExecutionPolicy Bypass -File install.ps1                         the latest release
#   ... install.ps1 -From PATH        a release folder (or its owner folder) or .zip on this computer
#   ... install.ps1 -Update           replace an earlier Owner without asking
#   ... install.ps1 -Name bmac-owner   install as /bmac-owner, and its commands as /bmac-owner-...
#   ... install.ps1 -Replace          move someone else's skills with our names aside (kept as backups)
#
# It never deletes anything that is not ours, never leaves half an installation, and asks before it changes
# anything that is already there. Uninstall with uninstall.ps1.
param(
  [string]$From = "",
  [switch]$Update,
  [switch]$Replace,
  [ValidateSet("owner", "bmac-owner")][string]$Name = "owner",
  [switch]$Yes
)
$ErrorActionPreference = "Stop"
$Fallback = "bmac-owner"
$ReleaseUrl = if ($env:OWNER_RELEASE_URL) { $env:OWNER_RELEASE_URL } else {
  "https://github.com/bmacbuilds/owner-skill/archive/refs/tags/v1.0.0.zip" }
$Marker = ".owner-install"
$Commands = @("ap-processor", "cash-flow-snapshot", "close-month", "invoice-chase", "month-end-prep", "pay-the-bills", "payroll-prep", "plan-payroll", "report-builder", "report-pack", "tax-prep", "tax-season-organizer", "call-list", "crm-autopilot", "grow-pipeline", "lead-finder", "lead-triage", "outreach-composer", "reactivate", "speed-to-lead", "ad-manager", "canva-creator", "content-strategy", "growth-pulse", "marketing-monday", "review-reputation", "seo-ai-visibility", "social-content-engine", "contract-review", "grant-rfp-writer", "proposal-builder", "ticket-deflector", "hiring-screener", "inbox-manager", "inventory-planner", "job-post-builder", "restock", "business-pulse", "monday-brief", "smb-onboard", "smb-router", "brand-style", "build-agent", "build-connector")   # written by scripts/sync.py from skill.json

function Fail($why) { Write-Error "Owner was not installed: $why" -ErrorAction Continue; throw "stop" }
function Ask($question) {
  if ($Yes) { return $true }
  if ($env:OWNER_NO_PROMPT -or -not [Environment]::UserInteractive -or [Console]::IsInputRedirected) { return $false }
  $answer = Read-Host "$question [y/N]"
  return $answer -match '^(y|yes)$'
}

$Skills = Join-Path $HOME ".claude\skills"
# Staging and backups live beside the skills folder, never in it: Claude Code makes a command of every folder there.
# Same disk as the skills folder, so every move into place is a rename.
$Work = Join-Path $HOME ".claude\.owner"
$Run = Join-Path $Work "run.$PID"
$Stamp = Get-Date -Format "yyyyMMddHHmmss"
$BackupDir = Join-Path $Work "backups\$Stamp"
$Folders = @($Name) + @($Commands | ForEach-Object { "$Name-$_" })   # the skill, then each command's own
$Stage = Join-Path ([IO.Path]::GetTempPath()) ("owner." + [Guid]::NewGuid().ToString("N"))
$Placed = @(); $Backups = @(); $Done = $false
New-Item -ItemType Directory -Path $Stage | Out-Null

try {
  # 1. Claude Code. The files are harmless without it, so a missing Claude Code is a note, not a stop.
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Output "Note: Claude Code was not found on this computer. Owner runs inside it: install Claude Code from"
    Write-Output "      https://code.claude.com, then type /$Name in it."
  }

  # 2. The release, staged in a temporary folder.
  if (-not $From) {
    $From = Join-Path $Stage "release.zip"
    try { Invoke-WebRequest -Uri $ReleaseUrl -OutFile $From -UseBasicParsing } catch { Fail "the download failed ($ReleaseUrl)" }
  }
  if (Test-Path -LiteralPath $From -PathType Container) {
    $Root = (Resolve-Path -LiteralPath $From).Path
    if ((Split-Path $Root -Leaf) -eq "owner" -and (Test-Path -LiteralPath (Join-Path $Root "SKILL.md"))) { $Root = Split-Path $Root -Parent }
  } elseif (Test-Path -LiteralPath $From -PathType Leaf) {
    try { Expand-Archive -LiteralPath $From -DestinationPath (Join-Path $Stage "unpacked") } catch { Fail "$From is not a readable release" }
    $unpacked = Join-Path $Stage "unpacked"   # GitHub wraps the release in one folder
    $found = @(Get-ChildItem -LiteralPath $unpacked -Directory | Where-Object Name -eq "owner") + @(Get-ChildItem -LiteralPath $unpacked -Directory | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory | Where-Object Name -eq "owner" })
    if ($found.Count -ne 1) { Fail "$From has no single owner folder" }
    $Root = Split-Path $found[0].FullName -Parent
  } else { Fail "$From was not found" }
  if (-not (Test-Path -LiteralPath (Join-Path $Root "owner") -PathType Container)) { Fail "$From has no owner folder" }
  $PkgRoot = Join-Path $Stage "pkg"
  New-Item -ItemType Directory -Path $PkgRoot | Out-Null
  Copy-Item -Recurse -LiteralPath (Join-Path $Root "owner") (Join-Path $PkgRoot $Name)
  foreach ($s in $Commands) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root "owner-$s\SKILL.md"))) { Fail "the release is missing the /owner-$s command" }
    Copy-Item -Recurse -LiteralPath (Join-Path $Root "owner-$s") (Join-Path $PkgRoot "$Name-$s")
  }
  $Pkg = Join-Path $PkgRoot $Name

  # 3. Every required file, before anything is touched.
  foreach ($f in "SKILL.md","NOTICE","VERSION") { if (-not (Test-Path -LiteralPath (Join-Path $Pkg $f))) { Fail "the release is missing $f" } }
  foreach ($s in $Commands) { if (-not (Test-Path -LiteralPath (Join-Path $Pkg "commands\$s\COMMAND.md"))) { Fail "the release is missing the $s command's instructions" } }
  if (-not (Select-String -LiteralPath (Join-Path $Pkg "SKILL.md") -Pattern '^name: owner\r?$' -Quiet)) { Fail "the release's SKILL.md is not Owner" }
  $Version = (Get-Content -LiteralPath (Join-Path $Pkg "VERSION") -TotalCount 1).Trim()
  foreach ($f in $Folders) {
    $skill = Join-Path $PkgRoot "$f\SKILL.md"
    if ($Name -ne "owner") {   # every name, each command's pointer, every `/command; Windows line ends too
      $text = [IO.File]::ReadAllText($skill) -replace '(?m)^name: owner', "name: $Name" -replace '/\.\./owner/', "/../$Name/" -replace '`/owner', "``/$Name"
      [IO.File]::WriteAllText($skill, $text)
    }
    Set-Content -LiteralPath (Join-Path $PkgRoot "$f\$Marker") -Value "Owner $Version, installed as /$f by install.ps1. uninstall.ps1 removes only folders with this file."
  }

  # 4. What is already there, for every folder, before anything is touched.
  New-Item -ItemType Directory -Force -Path $Skills | Out-Null
  $ours = @($Folders | Where-Object { Test-Path -LiteralPath (Join-Path $Skills "$_\$Marker") })
  $theirs = @($Folders | Where-Object { (Test-Path -LiteralPath (Join-Path $Skills $_)) -and -not (Test-Path -LiteralPath (Join-Path $Skills "$_\$Marker")) })
  if ($ours.Count -and -not $Update -and -not (Ask "Owner is already installed as /$Name. Replace it with $Version?")) {
    Fail "an earlier Owner is installed as /$Name and was kept. Run again with -Update to replace it."
  }
  if ($theirs.Count) {
    $list = ($theirs | ForEach-Object { "/$_" }) -join " "
    if ($Replace -or (Ask "Other skills already use $list. Move them aside (each is kept as a backup) and install Owner?")) {
      New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
      foreach ($f in $theirs) { $Backups += $f; Move-Item -LiteralPath (Join-Path $Skills $f) (Join-Path $BackupDir $f) }
    } else {
      Fail "other skills already use $list, and they were not touched. Install Owner as /$Fallback instead with: -Name $Fallback"
    }
  }

  # 5. Into place: a failure never leaves half an installation, and whatever was there comes back.
  New-Item -ItemType Directory -Force -Path (Join-Path $Run "new"), (Join-Path $Run "old") | Out-Null
  foreach ($f in $Folders) { Copy-Item -Recurse -LiteralPath (Join-Path $PkgRoot $f) (Join-Path $Run "new\$f") }
  if ($env:OWNER_FAIL_AT -eq "copy") { Fail "test: stopping after the copy" }
  foreach ($f in $Folders) {
    $dest = Join-Path $Skills $f
    if (Test-Path -LiteralPath $dest) { Move-Item -LiteralPath $dest (Join-Path $Run "old\$f") }
    if ($env:OWNER_FAIL_AT -eq "swap" -and $Placed.Count) { Fail "test: stopping mid-swap" }
    $Placed += $f; Move-Item -LiteralPath (Join-Path $Run "new\$f") $dest
  }
  $Done = $true
  foreach ($f in $Backups) { Write-Output "Your earlier /$f skill was kept at $(Join-Path $BackupDir $f)." }

  # 6. Anything that could still answer to the same name.
  if (Test-Path -LiteralPath (Join-Path $HOME ".claude\commands\$Name.md")) { Write-Output "Note: you also have .claude\commands\$Name.md. The Owner skill takes precedence; that file was left alone." }
  if (Test-Path -LiteralPath (Join-Path (Get-Location) ".claude\skills\$Name")) { Write-Output "Note: this project has its own /$Name skill. Your personal Owner takes precedence over it." }
  if (-not (Get-Command python -ErrorAction SilentlyContinue) -and -not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    Write-Output "Note: Python 3 was not found. Owner works without it; a few of its tools need it." }

  Write-Output ""
  Write-Output "Owner $Version is installed. Open Claude Code and type /$Name"
  if ($Commands.Count) { Write-Output ("Each of its commands also works on its own: " + (($Commands | ForEach-Object { "/$Name-$_" }) -join " ")) }
  Write-Output "If /$Name opens something else, your organization may have its own: run /skills in Claude Code to check,"
  Write-Output "or install Owner as /$Fallback with: -Name $Fallback"
} catch {
  if ($_.Exception.Message -ne "stop") { Write-Error "Owner was not installed: $($_.Exception.Message)" -ErrorAction Continue }
  $global:LASTEXITCODE = 1
  $failed = $true
} finally {
  Remove-Item -Recurse -Force -LiteralPath $Stage -ErrorAction SilentlyContinue
  if (-not $Done) {   # take out what this run put in, and put back what was there, folder by folder
    foreach ($f in $Placed) { Remove-Item -Recurse -Force -LiteralPath (Join-Path $Skills $f) -ErrorAction SilentlyContinue }
    foreach ($f in $Folders) {
      $old = Join-Path $Run "old\$f"
      if ((Test-Path -LiteralPath $old) -and -not (Test-Path -LiteralPath (Join-Path $Skills $f))) { Move-Item -LiteralPath $old (Join-Path $Skills $f) }
    }
    foreach ($f in $Backups) {
      $kept = Join-Path $BackupDir $f
      if ((Test-Path -LiteralPath $kept) -and -not (Test-Path -LiteralPath (Join-Path $Skills $f))) {
        Move-Item -LiteralPath $kept (Join-Path $Skills $f); Write-Output "Your earlier /$f skill was put back."
      }
    }
    if ((Test-Path -LiteralPath $BackupDir) -and -not (Get-ChildItem -LiteralPath $BackupDir -Force)) { Remove-Item -LiteralPath $BackupDir }
  }
  Remove-Item -Recurse -Force -LiteralPath $Run -ErrorAction SilentlyContinue
  foreach ($d in (Join-Path $Work "backups"), $Work) {
    if ((Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force)) { Remove-Item -LiteralPath $d }
  }
}
if ($failed) { exit 1 }
