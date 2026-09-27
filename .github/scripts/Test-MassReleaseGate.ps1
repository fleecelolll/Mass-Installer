param(
    [string]$ReleaseRoot
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 3

$root = if ($ReleaseRoot) {
    [IO.Path]::GetFullPath($ReleaseRoot).TrimEnd('\')
} else {
    [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
}
$installer = Join-Path $root 'Installer.bat'
$app = Join-Path $root 'Mass Installer.pyw'
$runtime = Join-Path $root '.runtime'
$python = Join-Path $runtime 'python\python.exe'
$pythonw = Join-Path $runtime 'python\pythonw.exe'
$pipWheel = Join-Path $runtime 'python\pip.whl'
$sitePackages = Join-Path $runtime 'python\Lib\site-packages'
$pythonDir = Join-Path $runtime 'python'
$venv = Join-Path $root '.venv'
$cache = Join-Path $runtime 'trusted-winget-path.txt'
$marker = Join-Path $runtime 'setup-complete.txt'
$lock = Join-Path $runtime 'setup.lock'
$shortcut = Join-Path $root 'Mass Installer.lnk'
$log = Join-Path $root 'setup.log'
$cmd = Join-Path $env:SystemRoot 'System32\cmd.exe'

function Require-NormalDirectory([string]$Path, [string]$Label) {
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Label is not a normal directory: $Path"
    }
    $item
}

function Require-NormalFile([string]$Path, [string]$Label, [long]$MaximumLength = 32MB) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or -not [IO.File]::Exists($item.FullName) -or $item.Length -gt $MaximumLength) {
        throw "$Label is not a normal bounded file: $Path"
    }
    $item
}

function Invoke-Setup([switch]$ConfirmInteractively) {
    $commandLine = if ($ConfirmInteractively) {
        '(echo Y)| call "{0}" --no-pause' -f $installer
    } else {
        'call "{0}" --yes --no-pause' -f $installer
    }
    & $cmd /d /c $commandLine | ForEach-Object { Write-Host $_ }
    return $LASTEXITCODE
}

function Read-SetupOutcome {
    $text = [IO.File]::ReadAllText($log, [Text.Encoding]::UTF8)
    $resolverMatches = [regex]::Matches($text, '(?m)^FLEECE_WINGET_STATE=(trusted|exact-package-absent|present-invalid|unsupported-version)\r?$')
    $outcomeMatches = [regex]::Matches($text, '(?m)^\[[^\r\n]+\] FLEECE_SETUP_WINGET_OUTCOME=(trusted|exact-package-absent|present-invalid|unsupported-version|resolver-error)\r?$')
    if ($resolverMatches.Count -lt 1 -or $resolverMatches.Count -gt 2 -or $resolverMatches.Count -ne $outcomeMatches.Count) {
        throw "Expected one or two paired WinGet checks in setup.log; found $($resolverMatches.Count) resolver states and $($outcomeMatches.Count) setup outcomes."
    }
    $states = [string[]]::new($resolverMatches.Count)
    for ($index = 0; $index -lt $resolverMatches.Count; $index++) {
        $resolverState = $resolverMatches[$index].Groups[1].Value
        $setupState = $outcomeMatches[$index].Groups[1].Value
        if ($resolverState -cne $setupState) {
            throw "WinGet check $($index + 1): resolver state '$resolverState' did not match setup state '$setupState'."
        }
        $states[$index] = $resolverState
    }
    [pscustomobject]@{ State = $states[-1]; States = $states; Count = $states.Length; Text = $text }
}

function Assert-OutcomeSequence($Outcome, [string[]]$Expected) {
    if ($Outcome.Count -ne $Expected.Length) {
        throw "Expected WinGet outcomes '$($Expected -join ', ')'; found '$($Outcome.States -join ', ')'."
    }
    for ($index = 0; $index -lt $Expected.Length; $index++) {
        if ($Outcome.States[$index] -cne $Expected[$index]) {
            throw "WinGet check $($index + 1): expected '$($Expected[$index])', found '$($Outcome.States[$index])'."
        }
    }
}

function Assert-NoPrivatePython($Outcome) {
    foreach ($path in @($pythonDir, $python, $pythonw, $pipWheel, $sitePackages, $venv)) {
        if (Test-Path -LiteralPath $path) {
            throw "WinGet preflight failed only after private Python setup had begun: $path"
        }
    }
    if ($Outcome.Text -match 'Downloading: https://www\.python\.org/|Installing pinned PySide6-Essentials|Official embedded CPython passed local validation|PySide6-Essentials=') {
        throw 'WinGet preflight failed only after private Python/PySide setup had begun.'
    }
}

function Assert-PrivateRuntime {
    [void](Require-NormalDirectory $runtime 'Private runtime')
    [void](Require-NormalDirectory $sitePackages 'Private site-packages')
    [void](Require-NormalFile $python 'Private python.exe')
    [void](Require-NormalFile $pythonw 'Private pythonw.exe')
    [void](Require-NormalFile $pipWheel 'Private pip wheel')
    & $python -I -c "import sys, struct, PySide6; ok = sys.version_info[:3] == (3, 14, 7) and struct.calcsize('P') == 8 and PySide6.__version__ == '6.11.2'; raise SystemExit(0 if ok else 1)"
    if ($LASTEXITCODE -ne 0) { throw 'The private Python/PySide6 version contract failed.' }
    & $python -I $app --self-test
    if ($LASTEXITCODE -ne 0) { throw 'The direct isolated app self-test failed.' }
}

function Assert-TrustedCache {
    $expected = Join-Path $runtime 'trusted-winget-path.txt'
    if ([IO.Path]::GetFullPath($cache) -cne [IO.Path]::GetFullPath($expected)) {
        throw 'The trusted WinGet cache does not use its fixed runtime filename.'
    }
    $item = Require-NormalFile $cache 'Trusted WinGet cache' 32768
    if ($item.Length -lt 1) { throw 'The trusted WinGet cache is empty.' }
    $bytes = [IO.File]::ReadAllBytes($item.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw 'The trusted WinGet cache contains a UTF-8 BOM.'
    }
    $text = [Text.UTF8Encoding]::new($false, $true).GetString($bytes)
    if ($text.IndexOfAny([char[]]@("`r", "`n", "`0")) -ge 0 -or [string]::IsNullOrWhiteSpace($text)) {
        throw 'The trusted WinGet cache must contain one path without a terminator.'
    }
    $target = [IO.Path]::GetFullPath($text)
    if ($target -cne $text -or [IO.Path]::GetFileName($target) -cne 'winget.exe') {
        throw 'The trusted WinGet cache does not contain one exact absolute winget.exe path.'
    }
    [void](Require-NormalFile $target 'Trusted cached WinGet executable')
}

foreach ($path in @($marker, $shortcut, $cache, $lock, $pythonDir, $venv)) {
    if (Test-Path -LiteralPath $path) {
        throw "The clean release gate started with stale private setup state: $path"
    }
}

$firstCode = Invoke-Setup -ConfirmInteractively
if (-not (Test-Path -LiteralPath $log -PathType Leaf)) {
    throw 'Installer.bat did not produce setup.log.'
}
$first = Read-SetupOutcome

switch ($first.State) {
    'trusted' {
        Assert-OutcomeSequence $first @('trusted', 'trusted')
        if ($firstCode -ne 0) { throw "Trusted WinGet setup failed with exit code $firstCode." }
        if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { throw 'Trusted setup did not publish the setup marker.' }
        if (-not (Test-Path -LiteralPath $shortcut -PathType Leaf)) { throw 'Trusted setup did not publish the app shortcut.' }
        if ($first.Text -notmatch '(?m)^\[[^\r\n]+\] Setup completed successfully\.\r?$') { throw 'Trusted setup did not log successful completion.' }
        if ($first.Text -notmatch 'Windows shortcut creation and readback passed preflight\.') { throw 'Trusted setup skipped the shortcut creation preflight.' }
        Assert-TrustedCache
        Assert-PrivateRuntime

        $originalApp = [IO.File]::ReadAllBytes($app)
        try {
            [IO.File]::WriteAllBytes($app, [Text.Encoding]::UTF8.GetBytes('def :'))
            $badSourceCommand = 'call "{0}" --yes --no-pause' -f $installer
            $badSourceOutput = @(& $cmd /d /c $badSourceCommand 2>&1)
            $badSourceCode = $LASTEXITCODE
            $badSourceText = $badSourceOutput | Out-String
            Write-Host $badSourceText
            if ($badSourceCode -ne 1) { throw "Malformed app source returned exit code $badSourceCode instead of 1." }
            if ($badSourceText -notmatch 'Checking bundled app source' -or $badSourceText -notmatch 'Mass Installer\.pyw is invalid or unreadable') {
                throw 'Malformed app source did not fail at its early source check.'
            }
            if ($badSourceText -match '\[ STEP 2 / 3 \]') {
                throw 'Malformed app source was discovered only after package setup began.'
            }
            if ($badSourceText -notmatch 'How to fix it:' -or $badSourceText -notmatch 'Re-extract the entire official release ZIP') {
                throw 'The early source failure did not display its repair instructions.'
            }
            $badSourceLog = [IO.File]::ReadAllText($log, [Text.Encoding]::UTF8)
            if ($badSourceLog -notmatch 'SyntaxError' -or $badSourceLog -notmatch 'HOW_TO_FIX: Re-extract the entire official release ZIP' -or $badSourceLog -match 'Setup completed successfully\.') {
                throw 'The early source failure log is missing the cause or repair instructions, or falsely reports success.'
            }
            Assert-OutcomeSequence (Read-SetupOutcome) @('trusted')
        } finally {
            [IO.File]::WriteAllBytes($app, $originalApp)
        }

        $testIcon = Join-Path $root 'assets\app-icons\googlechrome.svg'
        $originalIcon = [IO.File]::ReadAllBytes($testIcon)
        try {
            [IO.File]::Delete($testIcon)
            $missingIconCommand = 'call "{0}" --yes --no-pause' -f $installer
            $missingIconOutput = @(& $cmd /d /c $missingIconCommand 2>&1)
            $missingIconCode = $LASTEXITCODE
            $missingIconText = $missingIconOutput | Out-String
            Write-Host $missingIconText
            if ($missingIconCode -ne 1) { throw "Missing icon returned exit code $missingIconCode instead of 1." }
            if ($missingIconText -notmatch 'Checking bundled app icons' -or $missingIconText -notmatch 'bundled app icons are missing or invalid') {
                throw 'Missing icon did not fail at its early asset check.'
            }
            if ($missingIconText -match '\[ STEP 2 / 3 \]') {
                throw 'Missing icon was discovered only after package setup began.'
            }
            $missingIconLog = [IO.File]::ReadAllText($log, [Text.Encoding]::UTF8)
            if ($missingIconLog -notmatch 'Missing or unsafe icons: googlechrome\.svg' -or $missingIconLog -notmatch 'HOW_TO_FIX: Re-extract the entire official release ZIP, including its assets folder' -or $missingIconLog -match 'Setup completed successfully\.') {
                throw 'The early missing-icon log is missing the cause or repair instructions, or falsely reports success.'
            }
            Assert-OutcomeSequence (Read-SetupOutcome) @('trusted')
        } finally {
            [IO.File]::WriteAllBytes($testIcon, $originalIcon)
        }

        $repairCode = Invoke-Setup
        if ($repairCode -ne 0) { throw "Trusted WinGet repair failed with exit code $repairCode." }
        $repair = Read-SetupOutcome
        Assert-OutcomeSequence $repair @('trusted', 'trusted')
        if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { throw 'Repair lost the setup marker.' }
        if (-not (Test-Path -LiteralPath $shortcut -PathType Leaf)) { throw 'Repair lost the app shortcut.' }
        Assert-TrustedCache
        Assert-PrivateRuntime
    }
    'exact-package-absent' {
        Assert-OutcomeSequence $first @('exact-package-absent')
        if ($env:FLEECE_REQUIRE_TRUSTED_WINGET -ceq '1') {
            throw 'The required Windows 11 positive runner did not have a trusted supported WinGet installation.'
        }
        if ($firstCode -eq 0) { throw 'Setup reported success even though the exact Desktop App Installer package was absent.' }
        if ($firstCode -ne 1) { throw "Expected the setup failure wrapper to return 1 for exact package absence; got $firstCode." }
        $expectedError = 'Microsoft Desktop App Installer is not registered for this Windows user\. Install or update App Installer from Microsoft, then run this setup again\.'
        $errors = [regex]::Matches($first.Text, '(?m)^\[[^\r\n]+\] ERROR: .+\r?$')
        if ($errors.Count -ne 1 -or $errors[0].Value -notmatch $expectedError) {
            throw 'Exact package absence did not fail only at the expected WinGet gate.'
        }
        if ($first.Text -notmatch 'HOW_TO_FIX: Install or update App Installer from Microsoft Store' -or $first.Text -notmatch 'HOW_TO_FIX_LINK: https://apps\.microsoft\.com/detail/9nblggh4nns1') {
            throw 'Absent App Installer did not include its specific repair instructions.'
        }
        if ($first.Text -match '(?m)^\[[^\r\n]+\] Setup completed successfully\.\r?$') { throw 'Absent-package setup falsely logged success.' }
        foreach ($path in @($marker, $shortcut, $cache, $lock)) {
            if (Test-Path -LiteralPath $path) { throw "Absent-package setup published forbidden success state: $path" }
        }
        Assert-NoPrivatePython $first
    }
    'present-invalid' {
        throw 'Desktop App Installer is present but failed the trusted WinGet contract; this runner is not an expected unavailable-server case.'
    }
    'unsupported-version' {
        Assert-OutcomeSequence $first @('unsupported-version')
        if ($env:FLEECE_ALLOW_TRUSTED_OLD_WINGET -cne '1') {
            throw 'A trusted but unsupported WinGet is allowed only on the explicitly identified Windows Server 2025 runner.'
        }
        if ($firstCode -eq 0) { throw 'Setup reported success with a WinGet version below the supported minimum.' }
        if ($firstCode -ne 1) { throw "Expected the setup failure wrapper to return 1 for unsupported WinGet; got $firstCode." }
        $expectedWarning = 'WARNING: Validated Microsoft WinGet (?<Version>v?\d+\.\d+(?:\.\d+){0,2}) and its official source, but this version is older than 1\.29\.280\.'
        $warnings = [regex]::Matches($first.Text, "(?m)^$expectedWarning\r?$")
        if ($warnings.Count -ne 1) {
            throw 'Unsupported WinGet was not independently classified after package, signature, and official-source validation.'
        }
        Write-Host "Runner provides trusted but unsupported WinGet $($warnings[0].Groups['Version'].Value)."
        $expectedError = 'Microsoft Desktop App Installer is trusted, but its WinGet version is older than 1\.29\.280\. Update App Installer from Microsoft, then run this setup again\.'
        $errors = [regex]::Matches($first.Text, '(?m)^\[[^\r\n]+\] ERROR: .+\r?$')
        if ($errors.Count -ne 1 -or $errors[0].Value -notmatch $expectedError) {
            throw 'Unsupported WinGet did not fail only at the expected minimum-version gate.'
        }
        if ($first.Text -notmatch 'HOW_TO_FIX_COMMAND: winget upgrade Microsoft\.AppInstaller' -or $first.Text -notmatch 'HOW_TO_FIX_LINK: https://apps\.microsoft\.com/detail/9nblggh4nns1') {
            throw 'Outdated WinGet did not include its specific upgrade command and fallback.'
        }
        if ($first.Text -match '(?m)^\[[^\r\n]+\] Setup completed successfully\.\r?$') { throw 'Unsupported WinGet setup falsely logged success.' }
        foreach ($path in @($marker, $shortcut, $cache, $lock)) {
            if (Test-Path -LiteralPath $path) { throw "Unsupported WinGet setup published forbidden success state: $path" }
        }
        Assert-NoPrivatePython $first
    }
    default {
        throw "Unexpected WinGet state '$($first.State)'."
    }
}

if ($env:GITHUB_OUTPUT) {
    [IO.File]::AppendAllText($env:GITHUB_OUTPUT, "winget_state=$($first.State)`n", [Text.UTF8Encoding]::new($false))
}
Write-Host "Mass release gate passed with WinGet state: $($first.State)"
exit 0
