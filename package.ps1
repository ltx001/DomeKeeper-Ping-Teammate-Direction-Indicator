param(
    [string]$GameDir = $env:DOME_KEEPER_DIR
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Join-Path $root "src"
$modsUnpackedDir = Join-Path $sourceDir "mods-unpacked"
$distDir = Join-Path $root "dist"
$zipPath = Join-Path $distDir "Codex-TeamPingHud.zip"

New-Item -ItemType Directory -Force $distDir | Out-Null
Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue

# Compress-Archive writes backslashes into ZIP entry names on Windows. Dome
# Keeper's Mod Loader only recognizes forward-slash paths inside mod archives.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$sourcePrefix = $sourceDir.TrimEnd("\") + "\"
$zipStream = [System.IO.File]::Open(
    $zipPath,
    [System.IO.FileMode]::CreateNew,
    [System.IO.FileAccess]::Write,
    [System.IO.FileShare]::None
)
$archive = New-Object System.IO.Compression.ZipArchive(
    $zipStream,
    [System.IO.Compression.ZipArchiveMode]::Create,
    $false
)

try {
    Get-ChildItem -LiteralPath $modsUnpackedDir -Recurse -File | ForEach-Object {
        $entryName = $_.FullName.Substring($sourcePrefix.Length).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            $_.FullName,
            $entryName,
            [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
}
finally {
    $archive.Dispose()
    $zipStream.Dispose()
}

Write-Host "Packaged: $zipPath"

if (-not [string]::IsNullOrWhiteSpace($GameDir)) {
    if (-not (Test-Path -LiteralPath $GameDir)) {
        throw "Dome Keeper install directory was not found: $GameDir"
    }

    $gameModsDir = Join-Path $GameDir "mods"
    $gameZip = Join-Path $gameModsDir "Codex-TeamPingHud.zip"
    New-Item -ItemType Directory -Force $gameModsDir | Out-Null
    Copy-Item -Force $zipPath $gameZip
    Write-Host "Installed: $gameZip"
}
