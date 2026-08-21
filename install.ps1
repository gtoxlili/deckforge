<#
.SYNOPSIS
  deckforge installer for Windows.

.EXAMPLE
  irm https://deckforge.gtio.work/install.ps1 | iex

.NOTES
  Env:
    DECKFORGE_VERSION      pin a release tag (default: latest)
    DECKFORGE_INSTALL_DIR  install target (default: %LOCALAPPDATA%\deckforge\bin)

  Messages are English and state facts only, matching the CLI: this
  script's output is read by the agent that runs it, not only by a person.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Windows PowerShell 5.1 negotiates TLS 1.0 by default on older builds, and
# both github.com and the API refuse it. Without this the download fails
# with an unhelpful connection error.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$origin = if ($env:DECKFORGE_ORIGIN) { $env:DECKFORGE_ORIGIN } else { 'https://deckforge.gtio.work' }
$installDir = if ($env:DECKFORGE_INSTALL_DIR) { $env:DECKFORGE_INSTALL_DIR }
              else { Join-Path $env:LOCALAPPDATA 'deckforge\bin' }

function Say  ($m) { Write-Host "deckforge: $m" }
function Fail ($m) { Write-Error "deckforge: $m"; exit 1 }

switch ($env:PROCESSOR_ARCHITECTURE) {
  'AMD64' { $arch = 'amd64' }
  'ARM64' { $arch = 'amd64' }  # the amd64 build runs under Windows' x64 emulation
  default { Fail "unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
}

$version = $env:DECKFORGE_VERSION
if (-not $version) {
  Say 'resolving the latest release'
  $release = Invoke-RestMethod "$origin/v1/version"
  $version = $release.version
  if (-not $version) { Fail 'could not resolve the latest release tag from the GitHub API' }
}

$asset = "deckforge-windows-$arch.exe"
$base  = "$origin/dl"
$tmp   = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

try {
  Say "downloading $asset ($version)"
  Invoke-WebRequest "$base/$asset" -OutFile (Join-Path $tmp $asset)

  # Checksum verification is best-effort: a missing checksums file must not
  # block an install, but a MISMATCH always must.
  try {
    Invoke-WebRequest "$base/checksums.txt" -OutFile (Join-Path $tmp 'checksums.txt')
    $line = Select-String -Path (Join-Path $tmp 'checksums.txt') -Pattern ([regex]::Escape($asset)) | Select-Object -First 1
    if ($line) {
      $want = ($line.Line -split '\s+')[0]
      $got  = (Get-FileHash -Algorithm SHA256 (Join-Path $tmp $asset)).Hash.ToLower()
      if ($want -and $got -ne $want.ToLower()) { Fail "checksum mismatch: expected $want, got $got" }
    }
  } catch { Say 'checksums unavailable; not verified' }

  New-Item -ItemType Directory -Path $installDir -Force | Out-Null
  $target = Join-Path $installDir 'deckforge.exe'
  Move-Item -Force (Join-Path $tmp $asset) $target

  # A binary in a directory that is not on PATH is a binary the agent
  # cannot invoke, so PATH is extended for the current user rather than
  # left as an instruction.
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$installDir", 'User')
    Say "added $installDir to the user PATH; open a new terminal for it to take effect"
  }
  $env:Path = "$env:Path;$installDir"

  $v = & $target version
  Say "DeckForge $v ready at $target"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
