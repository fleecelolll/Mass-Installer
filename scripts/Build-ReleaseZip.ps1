param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$output = [IO.Path]::GetFullPath($OutputPath)
$outputDirectory = [IO.Path]::GetDirectoryName($output)
if (-not [IO.Directory]::Exists($outputDirectory)) {
    throw "Output directory does not exist: $outputDirectory"
}
if ([IO.File]::Exists($output) -or [IO.Directory]::Exists($output)) {
    throw "Refusing to overwrite an existing release archive: $output"
}

Push-Location -LiteralPath $root
try {
    $dirty = @(& git status --porcelain --untracked-files=normal)
    if ($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) {
        throw 'The release source tree must be clean before packaging.'
    }
    $commit = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not resolve the release commit.' }

    $app = Join-Path $root 'Mass Installer.pyw'
    $versionMatch = [regex]::Match([IO.File]::ReadAllText($app), '(?m)^APP_VERSION = "(?<version>\d+\.\d+\.\d+)"\s*$')
    if (-not $versionMatch.Success) { throw 'The app has no unambiguous release version.' }
    $version = $versionMatch.Groups['version'].Value
    if ([IO.Path]::GetFileName($output) -cne "Mass-Installer-v$version.zip") {
        throw "The archive filename must be Mass-Installer-v$version.zip."
    }

    $fixed = @('Installer.bat', 'LICENSE', 'Mass Installer.pyw', 'READ ME.txt', 'assets/THIRD_PARTY_NOTICES.md')
    $trackedIcons = @(& git ls-files -- 'assets/app-icons/*.svg')
    if ($LASTEXITCODE -ne 0 -or $trackedIcons.Count -ne 49) {
        throw "Expected exactly 49 tracked app icons; found $($trackedIcons.Count)."
    }
    $paths = @($fixed + $trackedIcons | Sort-Object -CaseSensitive)
    if ($paths.Count -ne 54 -or (@($paths | Select-Object -Unique)).Count -ne 54) {
        throw 'The release file list is incomplete or contains duplicates.'
    }
    foreach ($relative in $paths) {
        $path = Join-Path $root ($relative.Replace('/', '\'))
        $item = Get-Item -LiteralPath $path -Force
        if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.Length -lt 1) {
            throw "Release input is missing, empty, or unsafe: $relative"
        }
    }

    Add-Type -AssemblyName System.IO.Compression
    $stamp = [DateTimeOffset]::Parse('2026-09-27T10:00:00+00:00')
    $stream = [IO.File]::Open($output, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
        try {
            foreach ($relative in $paths) {
                $entry = $archive.CreateEntry($relative, [IO.Compression.CompressionLevel]::Optimal)
                $entry.LastWriteTime = $stamp
                $source = [IO.File]::OpenRead((Join-Path $root ($relative.Replace('/', '\'))))
                try {
                    $target = $entry.Open()
                    try { $source.CopyTo($target) } finally { $target.Dispose() }
                } finally { $source.Dispose() }
            }
        } finally { $archive.Dispose() }
    } finally { $stream.Dispose() }

    $check = [IO.Compression.ZipFile]::OpenRead($output)
    try {
        $actual = @($check.Entries | ForEach-Object FullName)
        if ($actual.Count -ne $paths.Count -or (Compare-Object $paths $actual)) {
            throw 'The completed archive entry list does not match the release file list.'
        }
        foreach ($entry in $check.Entries) {
            $sourcePath = Join-Path $root ($entry.FullName.Replace('/', '\'))
            $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
            $entryStream = $entry.Open()
            try {
                $sha = [Security.Cryptography.SHA256]::Create()
                try { $entryHash = [Convert]::ToHexString($sha.ComputeHash($entryStream)) }
                finally { $sha.Dispose() }
            } finally { $entryStream.Dispose() }
            if ($entryHash -cne $sourceHash) { throw "Archive content mismatch: $($entry.FullName)" }
        }
    } finally { $check.Dispose() }

    $hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
    $size = (Get-Item -LiteralPath $output).Length
    Write-Host "Release commit: $commit"
    Write-Host "Release version: $version"
    Write-Host "Archive files: $($paths.Count)"
    Write-Host "Archive bytes: $size"
    Write-Host "Archive SHA-256: $hash"
    Write-Host "Archive path: $output"
} finally {
    Pop-Location
}
