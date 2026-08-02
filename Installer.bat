@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Mass Installer Setup

set "NO_PAUSE=0"
set "ASSUME_YES=0"

:ParseArguments
if "%~1"=="" goto ArgumentsReady
if /I "%~1"=="--no-pause" goto ParseNoPause
if /I "%~1"=="--yes" goto ParseYes
echo.
echo   Unknown setup option: %~1
echo   Supported options: --yes --no-pause
echo.
exit /b 2

:ParseNoPause
set "NO_PAUSE=1"
shift
goto ParseArguments

:ParseYes
set "ASSUME_YES=1"
shift
goto ParseArguments

:ArgumentsReady

set "ROOT=%~dp0"
set "APP_FILE=%ROOT%Mass Installer.pyw"
set "LOG=%ROOT%setup.log"
set "RUNTIME=%ROOT%.runtime"
set "SETUP_LOCK=%RUNTIME%\setup.lock"
set "SETUP_LOCK_OWNER=%SETUP_LOCK%\owner.txt"
set "SETUP_MARKER=%RUNTIME%\setup-complete.txt"
set "SETUP_LOCK_HELD=0"
set "DOWNLOADS=%RUNTIME%\downloads"
set "PYTHON_DIR=%RUNTIME%\python"
set "RUNTIME_PY=%PYTHON_DIR%\python.exe"
set "RUNTIME_PYW=%PYTHON_DIR%\pythonw.exe"
set "LOCAL_SITE=%PYTHON_DIR%\Lib\site-packages"
set "PIP_WHEEL=%PYTHON_DIR%\pip.whl"
set "VENV=%ROOT%.venv"
set "VENV_PY=%VENV%\Scripts\python.exe"
set "VENV_PYW=%VENV%\Scripts\pythonw.exe"
set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "CURL_EXE=%SystemRoot%\System32\curl.exe"

set "PYTHON_VERSION=3.14.6"
set "PYSIDE_VERSION=6.11.1"
set "PYSIDE_DISTRIBUTION=PySide6-Essentials"
set "PYPI_INDEX=https://pypi.org/simple"
set "PIP_WHEEL_URL=https://files.pythonhosted.org/packages/5d/95/6b5cb3461ea5673ba0995989746db58eb18b91b54dbf331e72f569540946/pip-26.1.2-py3-none-any.whl"
set "PIP_WHEEL_SHA256=382FF9F685EE3BC25864F820AA50505825F10F5458FFFF07E30A6D96E5715CAB"

set "NATIVE_ARCH=%PROCESSOR_ARCHITECTURE%"
if defined PROCESSOR_ARCHITEW6432 set "NATIVE_ARCH=%PROCESSOR_ARCHITEW6432%"
if /I "%NATIVE_ARCH%"=="AMD64" goto ArchitectureX64
if /I "%NATIVE_ARCH%"=="ARM64" goto ArchitectureArm64
set "FAIL_MESSAGE=This installer currently supports 64-bit and ARM64 Windows only."
goto Failed

:ArchitectureX64
set "ARCH=x64"
set "PYTHON_URL=https://www.python.org/ftp/python/3.14.6/python-3.14.6-embed-amd64.zip"
set "PYTHON_SHA256=DF901E84A896FF1EE720AD03377E0C8D8C2244FDA79808AEEAFF6316DF1CB75C"
goto ArchitectureReady

:ArchitectureArm64
set "ARCH=arm64"
set "PYTHON_URL=https://www.python.org/ftp/python/3.14.6/python-3.14.6-embed-arm64.zip"
set "PYTHON_SHA256=0A7E80914709A9F3EBFCCDB9D1D02A37E4DDB69BB7F80D6DF1A7E95D54AF9E58"

:ArchitectureReady
if not exist "%POWERSHELL_EXE%" (
    set "FAIL_MESSAGE=Trusted Windows PowerShell is missing from the system folder."
    goto Failed
)
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >>"%LOG%" 2>&1
if not exist "%RUNTIME%" (
    set "FAIL_MESSAGE=Could not create the private runtime folder."
    goto Failed
)
call :AcquireSetupLock
if errorlevel 1 goto SetupAlreadyRunning
call :EnsureAppClosed
if errorlevel 1 (
    set "FAIL_MESSAGE=Mass Installer is open. Close the app before installing or repairing its files."
    goto Failed
)
if exist "%SETUP_MARKER%" del /f /q "%SETUP_MARKER%" >nul 2>nul
if exist "%SETUP_MARKER%" (
    set "FAIL_MESSAGE=The old setup completion marker could not be cleared."
    goto Failed
)
if not exist "%DOWNLOADS%" mkdir "%DOWNLOADS%" >>"%LOG%" 2>&1
if not exist "%DOWNLOADS%" (
    set "FAIL_MESSAGE=Could not create the private download folder."
    goto Failed
)

>>"%LOG%" echo.
>>"%LOG%" echo ============================================================
>>"%LOG%" echo Setup started: %DATE% %TIME%
>>"%LOG%" echo Project root: "%ROOT%"
>>"%LOG%" echo Native architecture: %NATIVE_ARCH%
>>"%LOG%" echo ============================================================

cls
echo.
echo  ==================================================
echo                 MASS INSTALLER SETUP
echo  ==================================================
echo.
echo   App-specific components stay inside this folder.
echo   Setup does not need administrator access.
echo.
echo      Python environment     runs the app
echo      PySide6                the app window
echo      WinGet                 installs selected apps
echo.
echo   Apps selected later are installed through Windows.
echo   They remain installed if this folder is deleted.
echo.
echo   Keep this window open until every check passes.
echo   The first setup can take a few minutes.
echo.
echo  ==================================================

if not exist "%APP_FILE%" (
    set "FAIL_MESSAGE=Mass Installer.pyw is missing from this folder."
    goto Failed
)

echo.
echo   [ STEP 1 / 3 ]   Private Python environment
echo.
call :ValidateVenv
if not errorlevel 1 (
    echo      Existing environment is valid. Keeping it.
    call :Log "Existing virtual environment passed validation."
    set "ENV_MODE=venv"
    set "APP_PY=%VENV_PY%"
    set "APP_PYW=%VENV_PYW%"
    goto PythonEnvironmentReady
)

call :ValidateEmbeddedPython
if not errorlevel 1 (
    if exist "%VENV%" rmdir /s /q "%VENV%" >>"%LOG%" 2>&1
    if exist "%VENV%" (
        set "FAIL_MESSAGE=An invalid old .venv folder could not be removed."
        goto Failed
    )
    echo      Existing private Python is valid. Keeping it.
    call :Log "Existing embedded CPython passed validation."
    set "ENV_MODE=embedded"
    set "APP_PY=%RUNTIME_PY%"
    set "APP_PYW=%RUNTIME_PYW%"
    goto PythonEnvironmentReady
)

call :FindBasePython
if not defined BASE_PY goto OfferEmbeddedPython

call :DescribePython "%BASE_PY%"
echo      Creating the app's private environment...
call :CreateVenv
if not errorlevel 1 (
    set "ENV_MODE=venv"
    set "APP_PY=%VENV_PY%"
    set "APP_PYW=%VENV_PYW%"
    goto PythonEnvironmentReady
)

call :Log "A compatible base Python was found, but virtual environment creation failed."
echo      The private environment could not be created with it.
echo      Setup can use a fully private Python instead.
echo.

:OfferEmbeddedPython
if defined BASE_PY goto ExplainEmbeddedPython
echo      No compatible 64-bit CPython was found.
echo.
echo      This app supports Python 3.10 through 3.14.
echo      An older or unsupported version may stop it from working.

:ExplainEmbeddedPython
echo      Setup can place Python %PYTHON_VERSION% privately inside
echo      this folder. It will not replace your current Python,
echo      change PATH, change file associations, or need admin.
echo.
if "%ASSUME_YES%"=="1" (
    echo      Install private Python %PYTHON_VERSION% now? [Y/N]: Y
) else (
    choice /C YN /N /M "      Install private Python %PYTHON_VERSION% now? [Y/N]: "
    if errorlevel 2 goto Cancelled
)

echo.
echo      Downloading and preparing private Python...
call :InstallEmbedPy
if errorlevel 1 (
    set "FAIL_MESSAGE=Private Python could not be installed or verified."
    goto Failed
)
if exist "%VENV%" rmdir /s /q "%VENV%" >>"%LOG%" 2>&1
if exist "%VENV%" (
    set "FAIL_MESSAGE=An invalid old .venv folder could not be removed."
    goto Failed
)
set "ENV_MODE=embedded"
set "APP_PY=%RUNTIME_PY%"
set "APP_PYW=%RUNTIME_PYW%"

:PythonEnvironmentReady
call :ValidateSelectedEnvironment
if errorlevel 1 (
    set "FAIL_MESSAGE=The private Python environment did not pass validation."
    goto Failed
)
echo      Done.

echo.
echo   [ STEP 2 / 3 ]   App components
echo.
echo      Installing or repairing trusted packages from PyPI...
echo      Existing components are reused whenever possible.
call :InstallPythonPackages
if errorlevel 1 (
    set "FAIL_MESSAGE=PySide6 could not be installed and verified."
    goto Failed
)
echo      Done.

echo.
echo   [ STEP 3 / 3 ]   Final checks
echo.
echo      Checking Windows Package Manager...
call :ValidateWinget
if errorlevel 1 (
    set "FAIL_MESSAGE=WinGet is missing or could not start. Install or update App Installer from Microsoft, then run this setup again."
    goto Failed
)
echo      Testing every required component...
call :VerifyEverything
if errorlevel 1 (
    set "FAIL_MESSAGE=One or more final component checks failed."
    goto Failed
)
call :WriteSetupMarker
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup finished its checks but could not save the completion marker."
    goto Failed
)
echo      Every check passed.

if exist "%DOWNLOADS%" rmdir /s /q "%DOWNLOADS%" >>"%LOG%" 2>&1
call :Log "Setup completed successfully."
call :ReleaseSetupLock

echo.
echo  ==================================================
echo                ALL SET, YOU ARE READY
echo  ==================================================
echo.
echo   Double-click "Mass Installer.pyw" to start.
echo.
echo   Run this installer again whenever you want to
echo   repair the app's private local files.
echo.
echo   Setup details were saved to:
echo   "%LOG%"
echo.
call :PauseIfNeeded
exit /b 0

:SetupAlreadyRunning
echo.
echo  ==================================================
echo                 SETUP ALREADY RUNNING
echo  ==================================================
echo.
echo   Another Mass Installer setup is already running.
echo   Let that window finish, then try again.
echo.
call :PauseIfNeeded
exit /b 1

:Cancelled
call :Log "Setup cancelled by the user before private Python installation."
call :ReleaseSetupLock
echo.
echo  ==================================================
echo                     SETUP CANCELLED
echo  ==================================================
echo.
echo   No application was installed through Mass Installer.
echo   Run Installer.bat again whenever you are ready.
echo.
call :PauseIfNeeded
exit /b 1

:Failed
if not defined FAIL_MESSAGE set "FAIL_MESSAGE=Setup stopped because an unexpected error occurred."
call :Log "ERROR: %FAIL_MESSAGE%"
call :ReleaseSetupLock
echo.
echo  ==================================================
echo                     SETUP STOPPED
echo  ==================================================
echo.
echo   %FAIL_MESSAGE%
echo.
echo   No success was reported because all checks did not pass.
echo   The detailed log is here:
echo.
echo   "%LOG%"
echo.
echo   Fix the listed problem, then run Installer.bat again.
echo.
call :PauseIfNeeded
exit /b 1


:AcquireSetupLock
2>nul mkdir "%SETUP_LOCK%"
if not errorlevel 1 goto SetupLockCreated
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $lock=$env:SETUP_LOCK; $owner=$env:SETUP_LOCK_OWNER; if(Test-Path -LiteralPath $owner){$text=(Get-Content -LiteralPath $owner -Raw).Trim(); if($text -match '^\d+$'){$process=Get-CimInstance Win32_Process -Filter ('ProcessId=' + $text) -ErrorAction SilentlyContinue; if($process -and $process.Name -ieq 'cmd.exe'){exit 2}}} else {$age=(Get-Date)-(Get-Item -LiteralPath $lock).CreationTime; if($age.TotalSeconds -lt 30){exit 2}}; if(Test-Path -LiteralPath $owner){Remove-Item -LiteralPath $owner -Force}; Remove-Item -LiteralPath $lock -Force" >nul 2>nul
if errorlevel 1 exit /b 1
2>nul mkdir "%SETUP_LOCK%"
if errorlevel 1 exit /b 1

:SetupLockCreated
set "SETUP_LOCK_HELD=1"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $self=Get-CimInstance Win32_Process -Filter ('ProcessId=' + $PID); if(-not $self -or -not $self.ParentProcessId){throw 'Could not identify the setup process.'}; Set-Content -LiteralPath $env:SETUP_LOCK_OWNER -Value ([string]$self.ParentProcessId) -Encoding ASCII -NoNewline" >>"%LOG%" 2>&1
if not errorlevel 1 exit /b 0
del /f /q "%SETUP_LOCK_OWNER%" >nul 2>nul
rmdir "%SETUP_LOCK%" >nul 2>nul
set "SETUP_LOCK_HELD=0"
exit /b 1

:EnsureAppClosed
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try{$mutex=[Threading.Mutex]::OpenExisting('Local\FleeceMassInstallerApp'); $mutex.Dispose(); exit 1}catch [Threading.WaitHandleCannotBeOpenedException]{exit 0}catch{exit 1}" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:WriteSetupMarker
if /I not "%ENV_MODE%"=="venv" if /I not "%ENV_MODE%"=="embedded" exit /b 1
>"%SETUP_MARKER%.new" echo %ENV_MODE%
if errorlevel 1 exit /b 1
move /y "%SETUP_MARKER%.new" "%SETUP_MARKER%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
if not exist "%SETUP_MARKER%" exit /b 1
exit /b 0

:ReleaseSetupLock
if not "%SETUP_LOCK_HELD%"=="1" exit /b 0
del /f /q "%SETUP_LOCK_OWNER%" >nul 2>nul
rmdir "%SETUP_LOCK%" >nul 2>nul
set "SETUP_LOCK_HELD=0"
exit /b 0


:FindBasePython
set "BASE_PY="
where py.exe >nul 2>nul
if errorlevel 1 goto FindPathPython
for %%V in (3.14 3.13 3.12 3.11 3.10) do call :TryPyTag %%V
if defined BASE_PY exit /b 0

:FindPathPython
for /f "delims=" %%P in ('where python.exe 2^>nul ^| findstr /V /I /C:"Microsoft\WindowsApps"') do call :TryPythonPath "%%P"
if defined BASE_PY exit /b 0
for /f "delims=" %%P in ('where python3.exe 2^>nul ^| findstr /V /I /C:"Microsoft\WindowsApps"') do call :TryPythonPath "%%P"
if defined BASE_PY exit /b 0

for %%P in (
    "%LocalAppData%\Programs\Python\Python314\python.exe"
    "%LocalAppData%\Programs\Python\Python313\python.exe"
    "%LocalAppData%\Programs\Python\Python312\python.exe"
    "%LocalAppData%\Programs\Python\Python311\python.exe"
    "%LocalAppData%\Programs\Python\Python310\python.exe"
    "%ProgramFiles%\Python314\python.exe"
    "%ProgramFiles%\Python313\python.exe"
    "%ProgramFiles%\Python312\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%ProgramFiles%\Python310\python.exe"
) do call :TryPythonPath "%%~fP"
exit /b 0

:TryPyTag
if defined BASE_PY exit /b 0
py -0p 2>nul | findstr /I /C:":%~1" >nul
if errorlevel 1 exit /b 1
set "CANDIDATE_FILE=%RUNTIME%\python-candidate.txt"
py -%~1 -I -c "import sys; print(sys.executable)" >"%CANDIDATE_FILE%" 2>>"%LOG%"
if errorlevel 1 exit /b 1
set "CANDIDATE="
set /p "CANDIDATE="<"%CANDIDATE_FILE%"
del /f /q "%CANDIDATE_FILE%" >nul 2>nul
if not defined CANDIDATE exit /b 1
call :TryPythonPath "%CANDIDATE%"
exit /b %ERRORLEVEL%

:TryPythonPath
if defined BASE_PY exit /b 0
if "%~1"=="" exit /b 1
if not exist "%~1" exit /b 1
call :ValidatePython "%~1"
if errorlevel 1 exit /b 1
set "BASE_PY=%~1"
call :Log "Found compatible base CPython: %~1"
exit /b 0

:ValidatePython
if "%~1"=="" exit /b 1
if not exist "%~1" exit /b 1
"%~1" -I -c "import sys, struct, venv, ensurepip; ok = sys.implementation.name == 'cpython' and (3, 10) <= sys.version_info[:2] < (3, 15) and struct.calcsize('P') == 8; raise SystemExit(0 if ok else 1)" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:ValidateEmbeddedPython
call :ValidateEmbeddedPythonAt "%PYTHON_DIR%"
exit /b %ERRORLEVEL%

:ValidateEmbeddedPythonAt
if "%~1"=="" exit /b 1
if not exist "%~1\python.exe" exit /b 1
if not exist "%~1\pythonw.exe" exit /b 1
if not exist "%~1\Lib\site-packages" exit /b 1
if not exist "%~1\pip.whl" exit /b 1
call :VerifyFileHash "%~1\pip.whl" "%PIP_WHEEL_SHA256%"
if errorlevel 1 exit /b 1
"%~1\python.exe" -I -c "import sys, struct, site; ok = sys.implementation.name == 'cpython' and sys.version_info[:3] == (3, 14, 6) and struct.calcsize('P') == 8 and any(p.lower().endswith(r'lib\site-packages') for p in sys.path); raise SystemExit(0 if ok else 1)" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
"%~1\python.exe" -I -c "import sys; sys.path.insert(0, sys.argv[1]); from pip._internal.cli.main import main; raise SystemExit(main(sys.argv[2:]))" "%~1\pip.whl" --version >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:DescribePython
"%~1" -I -c "import sys, platform; print('Selected CPython ' + platform.python_version() + ' at ' + sys.executable)" >>"%LOG%" 2>&1
set "PYTHON_VERSION_FILE=%RUNTIME%\python-version.txt"
"%~1" -I -c "import platform; print(platform.python_version())" >"%PYTHON_VERSION_FILE%" 2>>"%LOG%"
set "PYTHON_DISPLAY_VERSION="
if exist "%PYTHON_VERSION_FILE%" set /p "PYTHON_DISPLAY_VERSION="<"%PYTHON_VERSION_FILE%"
del /f /q "%PYTHON_VERSION_FILE%" >nul 2>nul
if defined PYTHON_DISPLAY_VERSION echo      Using compatible Python %PYTHON_DISPLAY_VERSION%.
exit /b 0

:InstallEmbedPy
call :ValidateEmbeddedPython
if not errorlevel 1 exit /b 0

set "PYTHON_ARCHIVE=%DOWNLOADS%\python-%PYTHON_VERSION%-embed-%ARCH%.zip"
set "PYTHON_NEW=%RUNTIME%\python.new"
set "PIP_DOWNLOAD=%DOWNLOADS%\pip.whl"
call :DownloadAndVerify "%PYTHON_URL%" "%PYTHON_ARCHIVE%" "%PYTHON_SHA256%"
if errorlevel 1 exit /b 1
call :DownloadAndVerify "%PIP_WHEEL_URL%" "%PIP_DOWNLOAD%" "%PIP_WHEEL_SHA256%"
if errorlevel 1 exit /b 1

if exist "%PYTHON_NEW%" rmdir /s /q "%PYTHON_NEW%" >>"%LOG%" 2>&1
set "ARCHIVE_FILE=%PYTHON_ARCHIVE%"
set "NEW_DIR=%PYTHON_NEW%"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath $env:ARCHIVE_FILE -DestinationPath $env:NEW_DIR -Force; $pth=Get-ChildItem -LiteralPath $env:NEW_DIR -Filter 'python*._pth' -File | Select-Object -First 1; if(-not $pth){throw 'Python archive did not contain its path configuration.'}; $lines=@(Get-Content -LiteralPath $pth.FullName | Where-Object { $_ -notmatch '^\s*#?\s*import site\s*$' -and $_ -notmatch '^\s*Lib\\site-packages\s*$' }); $lines += 'Lib\site-packages'; $lines += 'import site'; Set-Content -LiteralPath $pth.FullName -Value $lines -Encoding ASCII; New-Item -ItemType Directory -Path (Join-Path $env:NEW_DIR 'Lib\site-packages') -Force | Out-Null; Copy-Item -LiteralPath $env:PIP_DOWNLOAD -Destination (Join-Path $env:NEW_DIR 'pip.whl') -Force" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1

call :ValidateEmbeddedPythonAt "%PYTHON_NEW%"
set "TEMP_VALIDATE_CODE=%ERRORLEVEL%"
if not "%TEMP_VALIDATE_CODE%"=="0" exit /b 1

call :ReplaceDirectory "%PYTHON_NEW%" "%PYTHON_DIR%"
if errorlevel 1 exit /b 1
del /f /q "%PYTHON_ARCHIVE%" "%PIP_DOWNLOAD%" >nul 2>nul
call :ValidateEmbeddedPython
if errorlevel 1 exit /b 1
call :Log "Official embedded CPython passed local validation."
exit /b 0

:ValidateSelectedEnvironment
if /I "%ENV_MODE%"=="venv" goto ValidateSelectedVenv
if /I "%ENV_MODE%"=="embedded" goto ValidateSelectedEmbedded
exit /b 1

:ValidateSelectedVenv
call :ValidateVenv
exit /b %ERRORLEVEL%

:ValidateSelectedEmbedded
call :ValidateEmbeddedPython
exit /b %ERRORLEVEL%

:ValidateVenv
if not exist "%VENV_PY%" exit /b 1
if not exist "%VENV_PYW%" exit /b 1
"%VENV_PY%" -I -c "import sys, struct; ok = sys.implementation.name == 'cpython' and (3, 10) <= sys.version_info[:2] < (3, 15) and struct.calcsize('P') == 8 and sys.prefix != sys.base_prefix; raise SystemExit(0 if ok else 1)" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:CreateVenv
if not defined BASE_PY exit /b 1
call :ValidatePython "%BASE_PY%"
if errorlevel 1 exit /b 1

if exist "%VENV%" rmdir /s /q "%VENV%" >>"%LOG%" 2>&1
if exist "%VENV%" exit /b 1

call :Log "Creating virtual environment with: %BASE_PY%"
"%BASE_PY%" -I -m venv --copies "%VENV%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
call :ValidateVenv
exit /b %ERRORLEVEL%

:InstallPythonPackages
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
if /I "%ENV_MODE%"=="venv" goto InstallVenvPackages
if /I "%ENV_MODE%"=="embedded" goto InstallEmbeddedPackages
exit /b 1

:InstallVenvPackages
call :HasPinnedPySide
if errorlevel 1 goto CheckVenvPip
call :VerifyPythonPackages
if not errorlevel 1 exit /b 0

:CheckVenvPip
"%APP_PY%" -I -m pip --version >>"%LOG%" 2>&1
if not errorlevel 1 goto InstallPinnedVenvPackage
call :Log "pip was missing; attempting ensurepip repair."
"%APP_PY%" -I -m ensurepip --upgrade >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1

:InstallPinnedVenvPackage
call :Log "Installing pinned %PYSIDE_DISTRIBUTION% %PYSIDE_VERSION% from official PyPI."
"%APP_PY%" -I -m pip --isolated --disable-pip-version-check install --upgrade --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" "%PYSIDE_DISTRIBUTION%==%PYSIDE_VERSION%" >>"%LOG%" 2>&1
set "PACKAGE_INSTALL_CODE=%ERRORLEVEL%"
goto CheckInstalledPackages

:InstallEmbeddedPackages
call :ValidateEmbeddedPython
if errorlevel 1 exit /b 1
call :HasPinnedPySide
if errorlevel 1 goto InstallFullEmbeddedPackages
call :VerifyPythonPackages
if not errorlevel 1 exit /b 0

:InstallFullEmbeddedPackages
call :Log "Installing pinned %PYSIDE_DISTRIBUTION% %PYSIDE_VERSION% into embedded CPython from official PyPI."
"%APP_PY%" -I -c "import sys; sys.path.insert(0, sys.argv[1]); from pip._internal.cli.main import main; raise SystemExit(main(sys.argv[2:]))" "%PIP_WHEEL%" --isolated --disable-pip-version-check install --upgrade --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" --target "%LOCAL_SITE%" "%PYSIDE_DISTRIBUTION%==%PYSIDE_VERSION%" >>"%LOG%" 2>&1
set "PACKAGE_INSTALL_CODE=%ERRORLEVEL%"

:CheckInstalledPackages
if not "%PACKAGE_INSTALL_CODE%"=="0" goto RepairPythonPackages
call :VerifyPythonPackages
if not errorlevel 1 exit /b 0

:RepairPythonPackages
echo      A component check failed. Repairing local packages...
call :Log "Initial package validation failed; forcing a clean package reinstall."
if /I "%ENV_MODE%"=="venv" goto RepairVenvPackages
if /I "%ENV_MODE%"=="embedded" goto RepairEmbeddedPackages
exit /b 1

:RepairVenvPackages
"%APP_PY%" -I -m pip --isolated --disable-pip-version-check install --upgrade --force-reinstall --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" "%PYSIDE_DISTRIBUTION%==%PYSIDE_VERSION%" >>"%LOG%" 2>&1
goto RepairPackagesFinished

:RepairEmbeddedPackages
"%APP_PY%" -I -c "import sys; sys.path.insert(0, sys.argv[1]); from pip._internal.cli.main import main; raise SystemExit(main(sys.argv[2:]))" "%PIP_WHEEL%" --isolated --disable-pip-version-check install --upgrade --force-reinstall --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" --target "%LOCAL_SITE%" "%PYSIDE_DISTRIBUTION%==%PYSIDE_VERSION%" >>"%LOG%" 2>&1

:RepairPackagesFinished
if errorlevel 1 exit /b 1
call :VerifyPythonPackages
exit /b %ERRORLEVEL%

:VerifyPythonPackages
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
"%APP_PY%" -I -c "import PySide6; from importlib.metadata import version; from PySide6.QtCore import qVersion; assert version('%PYSIDE_DISTRIBUTION%') == '%PYSIDE_VERSION%'; print('%PYSIDE_DISTRIBUTION%=' + version('%PYSIDE_DISTRIBUTION%')); print('Qt=' + qVersion())" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
if /I "%ENV_MODE%"=="venv" goto CheckVenvDependencies
if /I "%ENV_MODE%"=="embedded" goto CheckEmbeddedDependencies
exit /b 1

:CheckVenvDependencies
"%APP_PY%" -I -m pip --isolated --disable-pip-version-check check >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:CheckEmbeddedDependencies
"%APP_PY%" -I -c "import sys; sys.path.insert(0, sys.argv[1]); from pip._internal.cli.main import main; raise SystemExit(main(sys.argv[2:]))" "%PIP_WHEEL%" --isolated --disable-pip-version-check check >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:HasPinnedPySide
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
"%APP_PY%" -I -c "import PySide6; from importlib.metadata import version; raise SystemExit(0 if version('%PYSIDE_DISTRIBUTION%') == '%PYSIDE_VERSION%' else 1)" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:ValidateWinget
set "WINGET_VALIDATED=0"
set "WINGET_EXE="
if not defined LOCALAPPDATA exit /b 1
if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe" set "WINGET_EXE=%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe"
if not defined WINGET_EXE exit /b 1
if not exist "%WINGET_EXE%" exit /b 1
set "WINGET_CHECK=%RUNTIME%\winget-check.txt"
"%WINGET_EXE%" --version >"%WINGET_CHECK%" 2>&1
set "WINGET_CHECK_CODE=%ERRORLEVEL%"
if exist "%WINGET_CHECK%" type "%WINGET_CHECK%" >>"%LOG%"
if not "%WINGET_CHECK_CODE%"=="0" (
    del /f /q "%WINGET_CHECK%" >nul 2>nul
    exit /b 1
)
set "WINGET_VERSION="
if exist "%WINGET_CHECK%" set /p "WINGET_VERSION="<"%WINGET_CHECK%"
del /f /q "%WINGET_CHECK%" >nul 2>nul
if not defined WINGET_VERSION exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$match=[regex]::Match($env:WINGET_VERSION,'(\d+)\.(\d+)'); if(-not $match.Success){exit 1}; $major=[int]$match.Groups[1].Value; $minor=[int]$match.Groups[2].Value; if($major -lt 1 -or ($major -eq 1 -and $minor -lt 6)){exit 1}" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
set "WINGET_SOURCE_CHECK=%RUNTIME%\winget-source-check.txt"
"%WINGET_EXE%" source export winget --disable-interactivity >"%WINGET_SOURCE_CHECK%" 2>&1
set "WINGET_SOURCE_CODE=%ERRORLEVEL%"
if exist "%WINGET_SOURCE_CHECK%" type "%WINGET_SOURCE_CHECK%" >>"%LOG%"
if not "%WINGET_SOURCE_CODE%"=="0" goto WingetSourceFailed
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $source=Get-Content -LiteralPath $env:WINGET_SOURCE_CHECK -Raw | ConvertFrom-Json; $trusted=@($source.TrustLevel) -contains 'Trusted'; $url=([string]$source.Arg).TrimEnd([char[]]'/'); $ok=$source.Name -ceq 'winget' -and $url -ieq 'https://cdn.winget.microsoft.com/cache' -and $source.Data -ceq 'Microsoft.Winget.Source_8wekyb3d8bbwe' -and $source.Identifier -ceq 'Microsoft.Winget.Source_8wekyb3d8bbwe' -and $source.Type -ceq 'Microsoft.PreIndexed.Package' -and $trusted; if(-not $ok){exit 1}" >>"%LOG%" 2>&1
set "WINGET_SOURCE_IDENTITY_CODE=%ERRORLEVEL%"
del /f /q "%WINGET_SOURCE_CHECK%" >nul 2>nul
if not "%WINGET_SOURCE_IDENTITY_CODE%"=="0" exit /b 1
call :Log "WinGet passed validation: %WINGET_VERSION%"
set "WINGET_VALIDATED=1"
exit /b 0

:WingetSourceFailed
del /f /q "%WINGET_SOURCE_CHECK%" >nul 2>nul
exit /b 1

:ReplaceDirectory
set "REPLACE_NEW=%~1"
set "REPLACE_TARGET=%~2"
set "REPLACE_BACKUP=%~2.old"
if not exist "%REPLACE_NEW%" exit /b 1
if exist "%REPLACE_BACKUP%" rmdir /s /q "%REPLACE_BACKUP%" >>"%LOG%" 2>&1
if exist "%REPLACE_BACKUP%" exit /b 1
if not exist "%REPLACE_TARGET%" goto ReplaceMoveNew
move "%REPLACE_TARGET%" "%REPLACE_BACKUP%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1

:ReplaceMoveNew
move "%REPLACE_NEW%" "%REPLACE_TARGET%" >>"%LOG%" 2>&1
if errorlevel 1 goto ReplaceRollback
if exist "%REPLACE_BACKUP%" rmdir /s /q "%REPLACE_BACKUP%" >>"%LOG%" 2>&1
exit /b 0

:ReplaceRollback
if exist "%REPLACE_TARGET%" rmdir /s /q "%REPLACE_TARGET%" >>"%LOG%" 2>&1
if exist "%REPLACE_BACKUP%" move "%REPLACE_BACKUP%" "%REPLACE_TARGET%" >>"%LOG%" 2>&1
exit /b 1

:DownloadAndVerify
set "DL_URL=%~1"
set "DL_FILE=%~2"
set "DL_HASH=%~3"
if not defined DL_HASH exit /b 1
if not exist "%DL_FILE%" goto DownloadFresh
call :VerifyFileHash "%DL_FILE%" "%DL_HASH%"
if not errorlevel 1 (
    call :Log "Reusing an already downloaded file that passed SHA-256 verification: %DL_FILE%"
    exit /b 0
)
del /f /q "%DL_FILE%" >nul 2>nul

:DownloadFresh
if exist "%DL_FILE%" del /f /q "%DL_FILE%" >nul 2>nul
call :Log "Downloading: %DL_URL%"

if not exist "%CURL_EXE%" goto DownloadWithPowerShell
"%CURL_EXE%" --fail --location --silent --show-error --retry 3 --retry-delay 2 --connect-timeout 30 --proto "=https" --proto-redir "=https" -o "%DL_FILE%" "%DL_URL%" >>"%LOG%" 2>&1
if not errorlevel 1 goto VerifyDownload
call :Log "curl failed; retrying with PowerShell."

:DownloadWithPowerShell
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -TimeoutSec 300 -Uri $env:DL_URL -OutFile $env:DL_FILE" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1

:VerifyDownload
if not exist "%DL_FILE%" exit /b 1
call :VerifyFileHash "%DL_FILE%" "%DL_HASH%"
exit /b %ERRORLEVEL%

:VerifyFileHash
set "VERIFY_FILE=%~1"
set "VERIFY_HASH=%~2"
if not exist "%VERIFY_FILE%" exit /b 1
if not defined VERIFY_HASH exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $stream=[IO.File]::OpenRead($env:VERIFY_FILE); try{$sha=[Security.Cryptography.SHA256]::Create(); try{$actual=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','')} finally{$sha.Dispose()}} finally{$stream.Dispose()}; if([string]::IsNullOrWhiteSpace($env:VERIFY_HASH)){Write-Output ('Recorded SHA-256: ' + $actual); exit 0}; if($actual -ne $env:VERIFY_HASH){throw ('SHA-256 mismatch. Expected {0}, got {1}' -f $env:VERIFY_HASH,$actual)}; Write-Output ('Verified SHA-256: ' + $actual)" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:VerifyEverything
if not defined APP_PY exit /b 1
if not defined APP_PYW exit /b 1
if not exist "%APP_PY%" exit /b 1
if not exist "%APP_PYW%" exit /b 1
call :ValidateSelectedEnvironment
if errorlevel 1 exit /b 1
call :VerifyPythonPackages
if errorlevel 1 exit /b 1
if not "%WINGET_VALIDATED%"=="1" exit /b 1

"%APP_PY%" -I -c "import os; from pathlib import Path; app=Path(os.environ['APP_FILE']); assert app.is_file(); compile(app.read_text(encoding='utf-8'), str(app), 'exec'); print('Application source compiled successfully.')" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
"%APP_PY%" -I "%APP_FILE%" --self-test >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:Log
>>"%LOG%" echo [%DATE% %TIME%] %~1
exit /b 0

:PauseIfNeeded
if "%NO_PAUSE%"=="1" exit /b 0
pause
exit /b 0
