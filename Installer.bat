@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Mass Installer Setup
set "INSTALLER_SELF=%~f0"
set "INSTALLER_ROOT=%~dp0"

set "NO_PAUSE=0"
set "ASSUME_YES=0"
set "SETUP_CHILD=0"
set "LOG_READY="
set "REPAIR_HINT="
set "REPAIR_COMMAND="
set "REPAIR_FALLBACK="
set "REPAIR_LINK="
set "DIAGNOSTIC_LOG=nul"
set "PATHS_VALIDATED="
set "FFMPEG_DIR="
set "DENO_DIR="
set "HERCULES_DIR="
set "LUA_DIR="

:ParseArguments
if "%~1"=="" goto ArgumentsReady
if /I "%~1"=="--no-pause" goto ParseNoPause
if /I "%~1"=="--yes" goto ParseYes
if /I "%~1"=="--fleece-setup-child" goto ParseChildMarker
goto UnknownOption

:ParseChildMarker
if /I not "%FLEECE_TOOLS_INSTALLER_CHILD%"=="1" goto UnknownOption
set "SETUP_CHILD=1"
shift
goto ParseArguments

:UnknownOption
echo.
echo   Unknown setup option. No setup changes were made.
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
if "%SETUP_CHILD%"=="1" goto DedicatedChildReady
set "SETUP_CHILD_ARGS=--fleece-setup-child"
if "%ASSUME_YES%"=="1" set "SETUP_CHILD_ARGS=%SETUP_CHILD_ARGS% --yes"
if "%NO_PAUSE%"=="1" set "SETUP_CHILD_ARGS=%SETUP_CHILD_ARGS% --no-pause"
set "FLEECE_TOOLS_INSTALLER_CHILD=1"
"%SystemRoot%\System32\cmd.exe" /d /c call "%INSTALLER_SELF%" %SETUP_CHILD_ARGS%
exit /b %ERRORLEVEL%

:DedicatedChildReady
set "FLEECE_TOOLS_INSTALLER_CHILD="

set "ROOT=%INSTALLER_ROOT%"
set "MAX_ROOT_LENGTH=72"
set "APP_FILE=%ROOT%Mass Installer.pyw"
set "LOG=%ROOT%setup.log"
set "RUNTIME=%ROOT%.runtime"
set "SETUP_LOCK=%RUNTIME%\setup.lock"
set "SETUP_LOCK_OWNER=%SETUP_LOCK%\owner.json"
set "SETUP_MARKER=%RUNTIME%\setup-complete.txt"
set "SETUP_LOCK_HELD=0"
set "SETUP_LOCK_TOKEN="
set "SETUP_LOCK_MAX_AGE_MINUTES=60"
set "DOWNLOADS=%RUNTIME%\downloads"
set "PYTHON_DIR=%RUNTIME%\python"
set "RUNTIME_PY=%PYTHON_DIR%\python.exe"
set "RUNTIME_PYW=%PYTHON_DIR%\pythonw.exe"
set "LOCAL_SITE=%PYTHON_DIR%\Lib\site-packages"
set "PIP_WHEEL=%PYTHON_DIR%\pip.whl"
set "TRUSTED_WINGET_PATH=%RUNTIME%\trusted-winget-path.txt"
set "WINGET_RESOLVER=%RUNTIME%\Validate-TrustedWinget.ps1"
set "WINGET_STATE=not-checked"
set "VENV=%ROOT%.venv"
set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "CURL_EXE=%SystemRoot%\System32\curl.exe"
set "ROBOCOPY_EXE=%SystemRoot%\System32\robocopy.exe"
set "PYTHON_VERSION=3.14.7"
set "PYSIDE_VERSION=6.11.2"
set "PYSIDE_DISTRIBUTION=PySide6-Essentials"
set "PYPI_INDEX=https://pypi.org/simple"
set "PIP_WHEEL_URL=https://files.pythonhosted.org/packages/f3/6e/1736e5b4ae2b778ef2f81c47d797de9f891d4d8acb047a24ca37a60294dd/pip-26.2.1-py3-none-any.whl"
set "PIP_WHEEL_SHA256=71138ADF1F4CA900CDB7D289C21B7494329F2332B6D85F0E1C42108C0384ED3E"
set "WINGET_RESOLVER_SHA256=E3B57C06C6D10FB265D3425A2E3CF218184C6337D125856EB0B9C26E6CA85F5C"
set "WINGET_RESOLVER_GZIP_B64_1=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"
set "WINGET_RESOLVER_GZIP_B64_2=i+XSBazEPXTVnJ7l2MqThF5fiDS7PdthLCxla4zPWCXuPpgaQF0IoVv1BmoU/tW/HvN7JgXHisUtiTQBQ7CPioIogsEgmkm2GvOkH3wJBr1dZbokb/frBZlPMbCNlLf7QcnJuXgAaSqYOliJrKBXbfxy/ybawzYPvx9ZhO44Pi27fDU5/Ti56Fw6EqtpBvE6qvEqieDRdJP4/ej8cPabUc9i/ScS/GpqytYxHMD0RCR5Cu0CtX3uwG5VQa9Xlq/r76Yo3ZHKxeXpbHIybl6E6aE5ytugmV1cTmfjj1+vJqefxrOveNhB1UU78rB1FNqBlrnSkISu3s6oXkb6UQc9Y18VL2HMgbSxFlmZc0OzJZCiHMAtBPERUDHNXDyds0dISEEeOyKcriAKes89m+b013TSPJ7PJbunGgoswaDXqwLArqQPri+I9en7fmmR2FQ6zLJHt0pC0wGod2DrlqhFRv6oudurJUgIz4yPRI/zNbJgMXxrYLJuZ9Ars1Hztym6Qld6B8efx+OjcXFz09nhbHyQSVDAdci4cdnWV6P7Jftves/2WrwjRkci55qE8I3sDbYmAo80xss2OEJ6ixR9Sqa3ie5yIekK/an6UX9z7uFoOx1nTodZtoFA39PbGkuFc0HwFu6XtKmOybFJHJ8vQvuM19lAubXUr6aUlUbVtameZKzXrJDypLm3GgfUAbzvTajSiXzFcljnyoIGZ3dBe/P7Pg49JATDIgwEAxLGsW25qhoytuBU5xL+yTwkz96xp0Lq4tTFLCT8CCoGjqleb2C1PHtRxa+oNKVI4GYl5DDLSDktwT6shAVTGiQkQ3Kba+OCskImQ8xQda6GREjiqBFVsE/uGE8Qh7NE46N6uxpWOEUxHT+bhe9KyFIaAxrABxrf5Vm1pOjDzHrYS67yLBOY/RRnLrt9lfeaCwk0XlanJ4yTUhK1lnM75XXbXkgPiptyuyMnr88iNoljw4x8AngrG5ucHgMDEjKMGJ6heLVX4YIlssoUJquKJUD0EtwAgmRSaKPCGFBKW6umE34tZtT5JXv3hLNGX9wWtOGaXFeUszko3V351NyTTwRjzYkDjR5XaTBYR7ggEJC/nHyon+pxld6UDPzPCvOsdn2BFUO/3FUWF0NXS3g1FJZUjWqGJcA100afPULFcC2auPV2q6eALDyVnyHYT2aKUuzyfZS/tfzeoSCl6EsufYMkz42biilPsADakIKtvS430MS0sVHwVU3QEr9tg6orppc1tcfU8kswJNe2FjwSq4xKpgTHjq1MsCCaLLiQcEQVdDRZoBwT1LKmzLOXlubvSkipZvemUPM4zG+tqdcYdP0Ra+W2l9tp5xVSc1k16Wzi2s2+0JBtqlckGcbUzQSsxT9b31WoLrRNKyBv908+NDSgct92iniY6yVqDlbTZWRqFGS12V8DXW7D1IGrNwsMJsqBPAKp2ZzFVJsCtPStG/bhvRiUzwRSBeQ7CZoCQVLt1mUH7iJs4wX9y2SLaHIt0PIUa+yuG8hIxYUqHNtERpm5cfWOZufbgmBLdGeSLdAejl0N0Fa0GpK21vlXixH83iIPJSjzdGBLn+HALkDlKV50fQTb0A4ShKEDCMibvb29PfJ2/29/fde2nxrasjFoXw50dCFdSmDmnWROWQqW1y5W0amjrddJ2MZMGb13/i13hmTn33ynw7g9RJEbmysD4Sbfa9Z5x7qZqK9MiRP87/0/+l+SnwZfIvOf/j9GXyL85fvecP95t8NxSNC55JAQSlY0nQuJLWWHvH38Ff2PGUQWE20dL0Fdv7lp7GK8Y9d+Y1dmOLZmXZMHCVWWMk2CL1EwKFLPBZC3xsAR54b91/s3g8qw91oHANDqhHFsgnpJoD0Xdqzf2KcLxRf4hl/wTUrfHQs37f+92GU/wTfzCbe5YyG/++/2BoNmJmMNY1tVd2YEj5i2EmuYJAwTptD9hoyjD401u2f6KSD7xhp+2f/L/rsOc/Apv2gNYj5nMaNp"
set "WINGET_RESOLVER_GZIP_B64_3=WOdgnVnYXYVV1Ch5RuF1+wquCp86Gk3UaZ6mZ/JqyTRMMxpD30M72JpFbLfCKtPt/NShqzg0/P5BjgS/B6mPpViFvyvB26LDSsLccoHCjjzc70yR60Mp6dPNq5jEIC04kN+nZ6fE9nyjreKQI+xyPqbMuMnJcU30sQCHcvGq/R+ppq8CsInqnGFAewWYeWH2KgAs6D7DPaRW+q+HMaSORJqCaTSpaDLm+QokmlXdT718p3MGaaJIriAhOS9iu71X/ZSBWqeJ9k1flVaUt/RDZnIpUxcbKuw23Sj/dlb48pEuLz4bHS1DwuYjNCiY0vXnRkqL8yJTwOHks3UlfxCcp9J4WXX2qoYGeR681iq8RKY7G7LVRMX3+FtOU9Vvv7rctpLopNK8W2tRtRywfKC5DbxvYD+OxdpbB7xd6DIie3lhzIUuO06B66u8lCU2latMCoUkFm9qdGBTjlgVgB0RvOthwot9n/Iplf9Tb2rtmIyeojFXebY7VC0BwcCPRWJxUmJPahteeslUmV1ipwVbs0QvKSdvov2/R/vv9tyTRP8nbk6z8KdDKDNQ2tbS9YqqnBt0CgfwzSUece1DT2/uUL32bBIv8bz0+rPY57senFSY+WTHvIIpknMc/Lf8TsML+b3AzleMa6YrEYeHCAdQL7y6rDser+9jNKVs/JRsDBsp3PClQXpzsl2W22bAs6Ymr05dPv0yu0vgoKMmsldqn2x0tbDciLzOQDUmb2dFFb7yyQc2iG0Mqhav927swuP42OXIHZCY37dWr98UoB8+tBf3y8XjzqdJawZiVUMD3IWYUFf1mDeom8Hg0twtX0h4zxI85teJ09YzxjXXS4FKqIaseX9/Nj/kT/3reEnl9c3Ne6/gxH/3dgYDI9e9H5MOeiDgemvhbOWNiFk1ceYz0Hmnc+pq5r/Kth2C5PUG3jDyC4uobt/lWYYdrLbexZSnak8taqJ0Fesmbk7E/TpWXk+vUYu7RlSytglY3F9Q9KySmt50OpwS6w9bzFovVaJe90TIzq9qDHSYVSMcVWKo2YStejGG2w5iV2vEdWwb6tCp3/iaKM82PORqG0DgNLHBmMXUJfvN718qDjwH0x3mN4zW6vpUH9K/OP92tht0gP0mlPZzr86MS5Pd1v8yggHCCMZmY7HgsQQNZe/eOIh6qmWG7d6Lz9pTge6ssL9zAVii4NNLDqR7nlS60RHZwWcuX6Py/Vh0AkrRhecj3GutXtWq2ZC7+ir1spjzCr7smpbg9qXBW4/6n30c0XhwZg5TOiI0tvU6qUt/tc2TLF9aG62ukdEfOivGsYiE0APtsiwT+8yJ5T22SHWXOdxCTHPlnIf1DiRh9h3+nHGmliROgfK0+v+5nnv/B+hyB8LaOAAA"

set "NATIVE_ARCH=%PROCESSOR_ARCHITECTURE%"
if defined PROCESSOR_ARCHITEW6432 set "NATIVE_ARCH=%PROCESSOR_ARCHITEW6432%"
if /I "%NATIVE_ARCH%"=="AMD64" goto ArchitectureX64
if /I "%NATIVE_ARCH%"=="ARM64" goto ArchitectureArm64
set "FAIL_MESSAGE=This installer currently supports 64-bit and ARM64 Windows only."
set "REPAIR_HINT=Use a 64-bit x64 or ARM64 Windows PC. This ZIP cannot run on 32-bit Windows."
goto Failed

:ArchitectureX64
set "ARCH=x64"
set "PYTHON_URL=https://www.python.org/ftp/python/3.14.7/python-3.14.7-embed-amd64.zip"
set "PYTHON_SHA256=D297E5FF019966817AD8502465176139F2D3D840FA4ED84B13BED399A6AB1F15"
goto ArchitectureReady

:ArchitectureArm64
set "ARCH=arm64"
set "PYTHON_URL=https://www.python.org/ftp/python/3.14.7/python-3.14.7-embed-arm64.zip"
set "PYTHON_SHA256=F6773983C8959D4281E48C4540CB0BDD23E42391E4E951CE17E7CEB52658F21C"

:ArchitectureReady
if not exist "%POWERSHELL_EXE%" (
    set "FAIL_MESSAGE=Trusted Windows PowerShell is missing from the system folder."
    set "REPAIR_HINT=Run Windows Update or Windows system-file repair, then retry. Do not download PowerShell from an unofficial site."
    goto Failed
)
if not exist "%ROBOCOPY_EXE%" (
    set "FAIL_MESSAGE=Trusted Windows file-copy support is missing from the system folder."
    set "REPAIR_HINT=Run Windows Update or Windows system-file repair, then retry. Do not download Robocopy from an unofficial site."
    goto Failed
)
if not exist "%ROOT%LICENSE" (
    set "FAIL_MESSAGE=The bundled Tool License is missing from this folder. Extract a fresh official release and try again."
    set "REPAIR_HINT=Extract the entire official release ZIP again; keep Installer.bat and LICENSE together."
    goto Failed
)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "if([IO.Path]::GetFullPath($env:ROOT).Length -gt [int]$env:MAX_ROOT_LENGTH){exit 2}" >nul 2>nul
if errorlevel 1 (
    set "FAIL_MESSAGE=The complete app folder path must be 72 characters or fewer. Move the extracted folder closer to the drive root and try again."
    set "REPAIR_HINT=Move the extracted folder to a shorter path you own, then run Installer.bat there."
    goto Failed
)
cls
echo.
echo   The app and private components stay inside this folder.
echo   The folder-local shortcut opens the private Python directly.
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
echo   Continue only if you accept the Terms and bundled Tool License.
echo   Terms: https://fleece.wtf/terms
echo   Tool License: LICENSE in this folder
echo.
echo  ==================================================
echo.
if "%ASSUME_YES%"=="1" (
    echo   Continue with install or repair? [Y/N]: Y
) else (
    choice /C YN /N /M "  Continue with install or repair? [Y/N]: "
    if errorlevel 2 goto Cancelled
)

:SetupApprovalReady
call :ValidatePrivatePaths
if errorlevel 1 (
    set "FAIL_MESSAGE=The app folder or one of its private setup paths is not safe to modify. Extract a fresh copy to a normal folder and try again."
    set "REPAIR_HINT=Re-extract the whole official ZIP to a normal local folder you own, without directory links."
    goto Failed
)
set "PATHS_VALIDATED=1"
call :CheckRootWritePermission
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup cannot write to this app folder. Move it to a folder owned by this Windows user and try again."
    set "REPAIR_HINT=Move the whole extracted folder to a writable local folder you own, then retry."
    goto Failed
)
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>nul
if not exist "%RUNTIME%" (
    set "FAIL_MESSAGE=Could not create the private runtime folder."
    set "REPAIR_HINT=Check free disk space and use a writable local folder you own, then retry."
    goto Failed
)
call :AcquireSetupLock
if errorlevel 1 goto SetupAlreadyRunning

:PrepareSetupLog
if exist "%LOG%" del /f /q "%LOG%" >nul 2>nul
if exist "%LOG%" (
    set "FAIL_MESSAGE=The previous setup log could not be replaced safely."
    set "REPAIR_HINT=Close programs using setup.log, check folder write access, then retry."
    goto Failed
)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$stream=[IO.File]::Open($env:LOG,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$stream.Dispose()" >nul 2>nul
if errorlevel 1 (
    set "FAIL_MESSAGE=A fresh private setup log could not be created safely."
    set "REPAIR_HINT=Check free disk space and use a writable local folder you own, then retry."
    goto Failed
)
set "LOG_READY=1"
set "DIAGNOSTIC_LOG=%LOG%"
call :EnsureAppClosed
if errorlevel 1 (
    set "FAIL_MESSAGE=Mass Installer is open. Close the app before installing or repairing its files."
    set "REPAIR_HINT=Close Mass Installer completely, then run Installer.bat again."
    goto Failed
)
if not exist "%DOWNLOADS%" mkdir "%DOWNLOADS%" >>"%LOG%" 2>&1
if not exist "%DOWNLOADS%" (
    set "FAIL_MESSAGE=Could not create the private download folder."
    set "REPAIR_HINT=Check free disk space and folder write access, then retry."
    goto Failed
)

set "LOG_MESSAGE============================================================"
call :LogCurrent
set "LOG_MESSAGE=Setup started."
call :LogCurrent
set "LOG_MESSAGE=Project root: %ROOT%"
call :LogCurrent
set "LOG_MESSAGE=Native architecture: %NATIVE_ARCH%"
call :LogCurrent

if not exist "%APP_FILE%" (
    set "FAIL_MESSAGE=Mass Installer.pyw is missing from this folder."
    set "REPAIR_HINT=Extract the entire official release ZIP again; do not run Installer.bat alone."
    goto Failed
)

echo.
echo   [ PREFLIGHT ]   Windows Package Manager
echo.
echo      Checking the trusted Microsoft package, source, and version...
call :TouchSetupLock
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup lost ownership of its private setup lock."
    goto Failed
)
call :CheckWingetRequirement
if errorlevel 1 goto Failed
echo      WinGet is ready. Continuing with private app components.
echo      Checking Windows shortcut support...
call :CheckShortcutSupport
if errorlevel 1 (
    set "FAIL_MESSAGE=Windows shortcut support is unavailable, or the existing Mass Installer shortcut is unsafe. See setup.log for details."
    set "REPAIR_HINT=Re-extract the official ZIP to a normal folder. If this repeats, ask your Windows administrator about shortcut support."
    goto Failed
)

echo.
echo   [ STEP 1 / 3 ]   Private Python environment
echo.
call :ValidateEmbeddedPython
if not errorlevel 1 (
    if exist "%VENV%" call :RemoveDirectoryRobust "%VENV%"
    if exist "%VENV%" (
        set "FAIL_MESSAGE=An old .venv folder could not be removed after private Python was verified."
        set "REPAIR_HINT=Close programs using this folder, then retry. If it repeats, extract a fresh ZIP to a new folder."
        goto Failed
    )
    echo      Existing private Python is valid. Keeping it.
    set "LOG_MESSAGE=Existing embedded CPython passed validation."
    call :LogCurrent
    set "ENV_MODE=embedded"
    set "APP_PY=%RUNTIME_PY%"
    set "APP_PYW=%RUNTIME_PYW%"
    goto PythonEnvironmentReady
)

echo      No verified private Python runtime is available yet.
echo.

:ExplainEmbeddedPython
echo      Setup can place Python %PYTHON_VERSION% privately inside
echo      this folder. It will not replace your current Python,
echo      change PATH, install global packages, or need admin.
echo.
echo.
echo      Downloading and preparing private Python...
call :InstallEmbedPy
if errorlevel 1 (
    set "FAIL_MESSAGE=Private Python could not be installed or verified."
    set "REPAIR_HINT=Check your connection and free disk space, then retry. Use setup.log to see which download or check failed."
    goto Failed
)
if exist "%VENV%" call :RemoveDirectoryRobust "%VENV%"
if exist "%VENV%" (
    set "FAIL_MESSAGE=An invalid old .venv folder could not be removed."
    set "REPAIR_HINT=Close programs using this folder, then retry. If it repeats, extract a fresh ZIP to a new folder."
    goto Failed
)
set "ENV_MODE=embedded"
set "APP_PY=%RUNTIME_PY%"
set "APP_PYW=%RUNTIME_PYW%"

:PythonEnvironmentReady
call :ValidateSelectedEnvironment
if errorlevel 1 (
    set "FAIL_MESSAGE=The private Python environment did not pass validation."
    set "REPAIR_HINT=Check free disk space and retry. If it repeats, re-extract the official ZIP to a new folder."
    goto Failed
)
echo      Checking bundled app source...
call :CompileAppSource
if errorlevel 1 (
    set "FAIL_MESSAGE=Mass Installer.pyw is invalid or unreadable. Re-extract the official release ZIP and run setup again."
    set "REPAIR_HINT=Re-extract the entire official release ZIP, then rerun Installer.bat."
    goto Failed
)
echo      Checking bundled app icons and image...
call :CheckBundledAssets
if errorlevel 1 (
    set "FAIL_MESSAGE=One or more bundled app icons or the app image are missing or invalid."
    set "REPAIR_HINT=Re-extract the entire official release ZIP, including its assets folder, then rerun setup."
    goto Failed
)
echo      Done.

echo.
echo   [ STEP 2 / 3 ]   App components
echo.
echo      Installing or repairing trusted packages from PyPI...
echo      Existing components are reused whenever possible.
call :TouchSetupLock
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup lost ownership of its private setup lock."
    goto Failed
)
call :InstallPythonPackages
if errorlevel 1 (
    set "FAIL_MESSAGE=PySide6 could not be installed and verified."
    set "REPAIR_HINT=Check your connection and free disk space, then retry. See setup.log for the package error."
    goto Failed
)
call :TouchSetupLock
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup lost ownership of its private setup lock."
    goto Failed
)
echo      Done.

echo.
echo   [ STEP 3 / 3 ]   Final checks
echo.
echo      Checking Windows Package Manager...
call :TouchSetupLock
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup lost ownership of its private setup lock."
    goto Failed
)
call :CheckWingetRequirement
if errorlevel 1 goto Failed

:WingetReady
echo      Testing every required component without installing apps...
call :TouchSetupLock
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup lost ownership of its private setup lock."
    goto Failed
)
call :VerifyEverything
if errorlevel 1 (
    if not defined FAIL_MESSAGE set "FAIL_MESSAGE=One or more final component checks failed."
    if not defined REPAIR_HINT set "REPAIR_HINT=Open setup.log to identify the failed self-test, then rerun setup once. If it repeats, use a fresh official ZIP."
    goto Failed
)
echo      Creating the Mass Installer start shortcut...
call :CreateShortcut
if errorlevel 1 (
    set "FAIL_MESSAGE=The start shortcut could not be created."
    set "REPAIR_HINT=Check folder write access and setup.log, then retry. If it repeats, extract a fresh ZIP to a new folder."
    goto Failed
)
call :WriteSetupMarker
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup finished its checks but could not save the completion marker."
    set "REPAIR_HINT=Check free disk space and folder write access, then rerun setup."
    goto Failed
)
echo      Every check passed.

if exist "%DOWNLOADS%" call :RemoveDirectoryRobust "%DOWNLOADS%"
if exist "%DOWNLOADS%" (
    set "FAIL_MESSAGE=Setup passed its checks but could not safely remove temporary downloads."
    set "REPAIR_HINT=Close programs scanning this folder, check folder write access, then rerun setup."
    goto Failed
)
set "LOG_MESSAGE=Setup completed successfully."
call :LogCurrent
call :ReleaseSetupLock

echo.
echo  ==================================================
echo                ALL SET, YOU ARE READY
echo  ==================================================
echo.
echo   Double click the "Mass Installer" shortcut in this
echo   folder to start. You can copy the shortcut to your
echo   Desktop or pin it to the taskbar.
echo.
echo   Run this installer again whenever you want to
echo   repair the app's private local files or refresh the shortcut.
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
echo   If no setup window is open, restart Windows and retry.
echo.
call :PauseIfNeeded
exit /b 1

:Cancelled
call :ReleaseSetupLock
echo.
echo  ==================================================
echo                     SETUP CANCELLED
echo  ==================================================
echo.
echo   Nothing was installed or changed after cancellation.
echo   Run Installer.bat again whenever you are ready.
echo.
call :PauseIfNeeded
exit /b 1

:Failed
if not defined FAIL_MESSAGE set "FAIL_MESSAGE=Setup stopped because an unexpected error occurred."
if "%FAIL_MESSAGE%"=="Setup lost ownership of its private setup lock." set "REPAIR_HINT=Close any other setup window and retry. If none is open, restart Windows first."
if not defined REPAIR_HINT set "REPAIR_HINT=Review the detailed log, then retry from a fresh official ZIP in a writable local folder."
set "LOG_MESSAGE=ERROR: %FAIL_MESSAGE%"
if defined LOG_READY call :LogCurrent
set "LOG_MESSAGE=HOW_TO_FIX: %REPAIR_HINT%"
if defined LOG_READY call :LogCurrent
if defined REPAIR_COMMAND (
    set "LOG_MESSAGE=HOW_TO_FIX_COMMAND: %REPAIR_COMMAND%"
    if defined LOG_READY call :LogCurrent
)
if defined REPAIR_FALLBACK (
    set "LOG_MESSAGE=HOW_TO_FIX_FALLBACK: %REPAIR_FALLBACK%"
    if defined LOG_READY call :LogCurrent
)
if defined REPAIR_LINK (
    set "LOG_MESSAGE=HOW_TO_FIX_LINK: %REPAIR_LINK%"
    if defined LOG_READY call :LogCurrent
)
if defined PATHS_VALIDATED call :ReleaseSetupLock
echo.
echo  ==================================================
echo                     SETUP STOPPED
echo  ==================================================
echo.
echo   %FAIL_MESSAGE%
echo.
echo   How to fix it:
echo      %REPAIR_HINT%
if defined REPAIR_COMMAND echo      %REPAIR_COMMAND%
if defined REPAIR_FALLBACK echo      %REPAIR_FALLBACK%
if defined REPAIR_LINK echo      %REPAIR_LINK%
echo.
echo   No success was reported because all checks did not pass.
if defined LOG_READY (
    echo   The detailed log is here:
    echo.
    echo   "%LOG%"
) else (
    echo   No new log was written because setup stopped before it could safely own one.
)
echo.
echo   Fix the listed problem, then run Installer.bat again.
echo.
call :PauseIfNeeded
exit /b 1


:AcquireSetupLock
2>nul mkdir "%SETUP_LOCK%"
if not errorlevel 1 goto SetupLockCreated
call :ValidatePrivateTree "%SETUP_LOCK%"
if errorlevel 1 exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $lock=$env:SETUP_LOCK; $owner=$env:SETUP_LOCK_OWNER; $max=[double]$env:SETUP_LOCK_MAX_AGE_MINUTES; $fresh=(((Get-Date)-(Get-Item -LiteralPath $lock).CreationTime).TotalSeconds -lt 30); if($fresh){exit 2}; $owned=$false; $token=$null; if(Test-Path -LiteralPath $owner){try{$data=Get-Content -LiteralPath $owner -Raw -Encoding UTF8|ConvertFrom-Json; $token=[string]$data.token; $heartbeat=[DateTime]::Parse([string]$data.heartbeatUtc).ToUniversalTime(); $process=Get-CimInstance Win32_Process -Filter ('ProcessId=' + [int]$data.pid) -ErrorAction SilentlyContinue; if($process -and $process.Name -ieq 'cmd.exe'){$started=([DateTime]$process.CreationDate).ToUniversalTime(); $recorded=[DateTime]::Parse([string]$data.processStartedUtc).ToUniversalTime(); $sameProcess=[Math]::Abs(($started-$recorded).TotalSeconds) -lt 3; $dedicatedChild=($data.child -eq $true -and [string]$process.CommandLine -match '(?i)--fleece-setup-child(?:\s|$)'); if($sameProcess -and ($dedicatedChild -or ([DateTime]::UtcNow-$heartbeat).TotalMinutes -lt $max)){$owned=$true}}}catch{}}; if($owned){exit 2}; if(Test-Path -LiteralPath $owner){try{$latest=Get-Content -LiteralPath $owner -Raw -Encoding UTF8|ConvertFrom-Json; if($token -and [string]$latest.token -ne $token){exit 2}}catch{if($token){exit 2}}}; $stale=$lock+'.stale-'+[Guid]::NewGuid().ToString('N'); Move-Item -LiteralPath $lock -Destination $stale; Remove-Item -LiteralPath $stale -Recurse -Force" >nul 2>nul
if errorlevel 1 exit /b 1
2>nul mkdir "%SETUP_LOCK%"
if errorlevel 1 exit /b 1

:SetupLockCreated
set "SETUP_LOCK_HELD=1"
set "SETUP_LOCK_TOKEN_FILE=%SETUP_LOCK%\token.txt"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -Command "[Guid]::NewGuid().ToString('N')" >"%SETUP_LOCK_TOKEN_FILE%" 2>nul
if exist "%SETUP_LOCK_TOKEN_FILE%" set /p "SETUP_LOCK_TOKEN="<"%SETUP_LOCK_TOKEN_FILE%"
del /f /q "%SETUP_LOCK_TOKEN_FILE%" >nul 2>nul
if not defined SETUP_LOCK_TOKEN goto SetupLockCreateFailed
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $self=Get-CimInstance Win32_Process -Filter ('ProcessId=' + $PID); if(-not $self -or -not $self.ParentProcessId){throw 'Could not identify the setup process.'}; $parent=Get-CimInstance Win32_Process -Filter ('ProcessId=' + $self.ParentProcessId); if(-not $parent){throw 'Could not identify the setup process.'}; if($env:SETUP_CHILD -ne '1' -or [string]$parent.CommandLine -notmatch '(?i)--fleece-setup-child(?:\s|$)'){throw 'Could not verify the dedicated setup child.'}; $started=([DateTime]$parent.CreationDate).ToUniversalTime().ToString('o'); $data=[ordered]@{schema=2;pid=[int]$parent.ProcessId;processStartedUtc=$started;token=$env:SETUP_LOCK_TOKEN;heartbeatUtc=[DateTime]::UtcNow.ToString('o');child=$true}; $new=$env:SETUP_LOCK_OWNER+'.new'; $data|ConvertTo-Json -Compress|Set-Content -LiteralPath $new -Encoding UTF8; Move-Item -LiteralPath $new -Destination $env:SETUP_LOCK_OWNER -Force" >nul 2>nul
if not errorlevel 1 exit /b 0

:SetupLockCreateFailed
del /f /q "%SETUP_LOCK_OWNER%" >nul 2>nul
rmdir "%SETUP_LOCK%" >nul 2>nul
set "SETUP_LOCK_HELD=0"
set "SETUP_LOCK_TOKEN="
exit /b 1

:EnsureAppClosed
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "foreach($name in @('Global\FleeceMassInstallerApp','Local\FleeceMassInstallerApp')){try{$mutex=[Threading.Mutex]::OpenExisting($name);$mutex.Dispose();exit 1}catch [Threading.WaitHandleCannotBeOpenedException]{}catch{exit 1}};exit 0" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:CheckRootWritePermission
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\');$probe=Join-Path $root ('.fleece-write-test-'+[Guid]::NewGuid().ToString('N')+'.tmp');try{$stream=[IO.File]::Open($probe,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$stream.Dispose()}finally{if(Test-Path -LiteralPath $probe){Remove-Item -LiteralPath $probe -Force}};exit 0" >nul 2>nul
exit /b %ERRORLEVEL%

:ValidatePrivatePaths
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\');$volume=[IO.Path]::GetPathRoot($root).TrimEnd('\');if([string]::IsNullOrWhiteSpace($root)-or $root -ieq $volume){throw 'Unsafe project root.'};$rootItem=Get-Item -LiteralPath $root -Force;if(-not $rootItem.PSIsContainer-or($rootItem.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'The project root must be a normal directory.'};$targets=@($env:RUNTIME,$env:VENV,$env:DOWNLOADS,$env:PYTHON_DIR,(Join-Path $env:PYTHON_DIR 'Lib'),$env:LOCAL_SITE,$env:SETUP_LOCK,($env:PYTHON_DIR+'.new'),($env:PYTHON_DIR+'.old'),($env:VENV+'.old'),(Join-Path $env:RUNTIME 'b'),(Join-Path $env:RUNTIME 'b.new'),(Join-Path $env:RUNTIME 'b.old'),(Join-Path $env:RUNTIME 'setup-check'));foreach($name in @('FFMPEG_DIR','DENO_DIR','HERCULES_DIR','LUA_DIR')){$value=[Environment]::GetEnvironmentVariable($name);if($value){$targets+=@($value,($value+'.new'),($value+'.old'),($value+'.extract'))}};$prefix=$root+'\';foreach($target in $targets){if([string]::IsNullOrWhiteSpace($target)){throw 'A private setup path is empty.'};$full=[IO.Path]::GetFullPath($target).TrimEnd('\');if(-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'A private setup path escaped the project root.'};if(Test-Path -LiteralPath $full){$item=Get-Item -LiteralPath $full -Force;if(-not $item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'A private setup directory is unsafe.'}}};foreach($file in @($env:LOG,$env:SETUP_MARKER,($env:SETUP_MARKER+'.new'),$env:SETUP_LOCK_OWNER,($env:SETUP_LOCK_OWNER+'.new'),$env:PIP_WHEEL,$env:TRUSTED_WINGET_PATH,$env:WINGET_RESOLVER)){if([string]::IsNullOrWhiteSpace($file)){continue};$full=[IO.Path]::GetFullPath($file);if(-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'A private setup file escaped the project root.'};if(Test-Path -LiteralPath $full){$item=Get-Item -LiteralPath $full -Force;if($item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'A private setup file is unsafe.'}}};exit 0" >nul 2>nul
exit /b %ERRORLEVEL%

:WriteSetupMarker
if /I not "%ENV_MODE%"=="embedded" exit /b 1
>"%SETUP_MARKER%.new" echo %ENV_MODE%
if errorlevel 1 exit /b 1
move /y "%SETUP_MARKER%.new" "%SETUP_MARKER%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
if not exist "%SETUP_MARKER%" exit /b 1
exit /b 0

:ReleaseSetupLock
if not "%SETUP_LOCK_HELD%"=="1" exit /b 0
call :ValidatePrivateTree "%SETUP_LOCK%"
if errorlevel 1 exit /b 2
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; if(-not(Test-Path -LiteralPath $env:SETUP_LOCK_OWNER)){exit 2}; $data=Get-Content -LiteralPath $env:SETUP_LOCK_OWNER -Raw -Encoding UTF8|ConvertFrom-Json; if([string]$data.token -ne $env:SETUP_LOCK_TOKEN){exit 2}; $released=$env:SETUP_LOCK+'.released-'+[Guid]::NewGuid().ToString('N'); Move-Item -LiteralPath $env:SETUP_LOCK -Destination $released; Remove-Item -LiteralPath $released -Recurse -Force" >nul 2>nul
set "RELEASE_LOCK_CODE=%ERRORLEVEL%"
set "SETUP_LOCK_HELD=0"
set "SETUP_LOCK_TOKEN="
exit /b %RELEASE_LOCK_CODE%

:TouchSetupLock
if not "%SETUP_LOCK_HELD%"=="1" exit /b 0
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $data=Get-Content -LiteralPath $env:SETUP_LOCK_OWNER -Raw -Encoding UTF8|ConvertFrom-Json; if([string]$data.token -ne $env:SETUP_LOCK_TOKEN){exit 2}; $data.heartbeatUtc=[DateTime]::UtcNow.ToString('o'); $new=$env:SETUP_LOCK_OWNER+'.new'; $data|ConvertTo-Json -Compress|Set-Content -LiteralPath $new -Encoding UTF8; Move-Item -LiteralPath $new -Destination $env:SETUP_LOCK_OWNER -Force" >nul 2>nul
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
"%~1\python.exe" -I -c "import sys, struct, site; ok = sys.implementation.name == 'cpython' and sys.version_info[:3] == (3, 14, 7) and struct.calcsize('P') == 8 and any(p.lower().endswith(r'lib\site-packages') for p in sys.path); raise SystemExit(0 if ok else 1)" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
"%~1\python.exe" -I -c "import sys; sys.path.insert(0, sys.argv[1]); from pip._internal.cli.main import main; raise SystemExit(main(sys.argv[2:]))" "%~1\pip.whl" --version >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

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

if exist "%PYTHON_NEW%" call :RemoveDirectoryRobust "%PYTHON_NEW%"
if exist "%PYTHON_NEW%" exit /b 1
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
set "LOG_MESSAGE=Official embedded CPython passed local validation."
call :LogCurrent
exit /b 0

:ValidateSelectedEnvironment
if /I not "%ENV_MODE%"=="embedded" exit /b 1
call :ValidateEmbeddedPython
exit /b %ERRORLEVEL%

:ValidateLegacyVenvLayoutAt
if "%~1"=="" exit /b 1
if not exist "%~1\Scripts\python.exe" exit /b 1
if not exist "%~1\Scripts\pythonw.exe" exit /b 1
if not exist "%~1\pyvenv.cfg" exit /b 1
exit /b 0

:InstallPythonPackages
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
call :CurrentPackagesFullyHealthy
if not errorlevel 1 exit /b 0
call :BeginPackageTransaction
if errorlevel 1 exit /b 1
if /I not "%ENV_MODE%"=="embedded" exit /b 1
call :InstallEmbeddedPackages
set "PACKAGE_TRANSACTION_CODE=%ERRORLEVEL%"
call :FinishPackageTransaction %PACKAGE_TRANSACTION_CODE%
exit /b %ERRORLEVEL%

:CurrentPackagesFullyHealthy
call :HasPinnedPySide
if errorlevel 1 exit /b 1
call :VerifyPythonPackages
exit /b %ERRORLEVEL%

:BeginPackageTransaction
set "PACKAGE_BACKUP=%RUNTIME%\b"
set "PACKAGE_BACKUP_NEW=%PACKAGE_BACKUP%.new"
if /I not "%ENV_MODE%"=="embedded" exit /b 1
set "PACKAGE_TARGET=%PYTHON_DIR%"
set "PACKAGE_BACKUP_PROBE=python.exe"
if exist "%PACKAGE_BACKUP%" (
    call :ValidatePrivateTree "%PACKAGE_BACKUP%"
    if errorlevel 1 exit /b 1
    if exist "%PACKAGE_BACKUP%\%PACKAGE_BACKUP_PROBE%" (
        set "LOG_MESSAGE=Recovering the local package environment left by an interrupted repair."
        call :LogCurrent
        call :ReplaceDirectory "%PACKAGE_BACKUP%" "%PACKAGE_TARGET%"
        if errorlevel 1 exit /b 1
    ) else (
        call :ValidateLegacyVenvLayoutAt "%PACKAGE_BACKUP%"
        if errorlevel 1 exit /b 1
        set "LOG_MESSAGE=Removing a completed package backup from the retired virtual-environment setup."
        call :LogCurrent
        call :RemoveDirectoryRobust "%PACKAGE_BACKUP%"
        if errorlevel 1 exit /b 1
    )
)
if not exist "%PACKAGE_TARGET%" exit /b 1
call :ValidatePrivateTree "%PACKAGE_TARGET%"
if errorlevel 1 exit /b 1
if exist "%PACKAGE_BACKUP_NEW%" call :RemoveDirectoryRobust "%PACKAGE_BACKUP_NEW%"
if exist "%PACKAGE_BACKUP_NEW%" exit /b 1
set "LOG_MESSAGE=Creating a local rollback copy before package repair."
call :LogCurrent
"%ROBOCOPY_EXE%" "%PACKAGE_TARGET%" "%PACKAGE_BACKUP_NEW%" /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ /NFL /NDL /NJH /NJS /NP >>"%LOG%" 2>&1
if errorlevel 8 exit /b 1
call :ValidatePrivateTree "%PACKAGE_BACKUP_NEW%"
if errorlevel 1 exit /b 1
if not exist "%PACKAGE_BACKUP_NEW%\%PACKAGE_BACKUP_PROBE%" exit /b 1
move "%PACKAGE_BACKUP_NEW%" "%PACKAGE_BACKUP%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
if not exist "%PACKAGE_BACKUP%" exit /b 1
call :ValidatePrivateTree "%PACKAGE_BACKUP%"
if errorlevel 1 exit /b 1
if exist "%PACKAGE_BACKUP_NEW%" exit /b 1
exit /b 0

:FinishPackageTransaction
set "PACKAGE_TRANSACTION_CODE=%~1"
if "%PACKAGE_TRANSACTION_CODE%"=="0" (
    if exist "%PACKAGE_BACKUP%" call :RemoveDirectoryRobust "%PACKAGE_BACKUP%"
    if exist "%PACKAGE_BACKUP%" exit /b 1
    exit /b 0
)
set "LOG_MESSAGE=Package repair failed; restoring the previous private Python environment."
call :LogCurrent
call :ReplaceDirectory "%PACKAGE_BACKUP%" "%PACKAGE_TARGET%"
if errorlevel 1 exit /b 1
exit /b %PACKAGE_TRANSACTION_CODE%

:InstallEmbeddedPackages
call :ValidateEmbeddedPython
if errorlevel 1 exit /b 1
call :HasPinnedPySide
if errorlevel 1 goto InstallFullEmbeddedPackages
call :VerifyPythonPackages
if not errorlevel 1 exit /b 0

:InstallFullEmbeddedPackages
set "LOG_MESSAGE=Installing pinned %PYSIDE_DISTRIBUTION% %PYSIDE_VERSION% into embedded CPython from official PyPI."
call :LogCurrent
call :ResetEmbeddedPackages
if errorlevel 1 exit /b 1
"%APP_PY%" -I -c "import sys; sys.path.insert(0, sys.argv[1]); from pip._internal.cli.main import main; raise SystemExit(main(sys.argv[2:]))" "%PIP_WHEEL%" --isolated --disable-pip-version-check install --upgrade --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" --target "%LOCAL_SITE%" "%PYSIDE_DISTRIBUTION%==%PYSIDE_VERSION%" >>"%LOG%" 2>&1
set "PACKAGE_INSTALL_CODE=%ERRORLEVEL%"

if not "%PACKAGE_INSTALL_CODE%"=="0" goto RepairPythonPackages
call :VerifyPythonPackages
if not errorlevel 1 exit /b 0

:RepairPythonPackages
echo      A component check failed. Repairing local packages...
set "LOG_MESSAGE=Initial package validation failed; forcing a clean package reinstall."
call :LogCurrent
if /I not "%ENV_MODE%"=="embedded" exit /b 1

call :ResetEmbeddedPackages
if errorlevel 1 exit /b 1
"%APP_PY%" -I -c "import sys; sys.path.insert(0, sys.argv[1]); from pip._internal.cli.main import main; raise SystemExit(main(sys.argv[2:]))" "%PIP_WHEEL%" --isolated --disable-pip-version-check install --upgrade --force-reinstall --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" --target "%LOCAL_SITE%" "%PYSIDE_DISTRIBUTION%==%PYSIDE_VERSION%" >>"%LOG%" 2>&1

if errorlevel 1 exit /b 1
call :VerifyPythonPackages
exit /b %ERRORLEVEL%

:VerifyPythonPackages
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
"%APP_PY%" -I -c "import PySide6; from importlib.metadata import version; from PySide6.QtCore import qVersion; assert version('%PYSIDE_DISTRIBUTION%') == '%PYSIDE_VERSION%'; print('%PYSIDE_DISTRIBUTION%=' + version('%PYSIDE_DISTRIBUTION%')); print('Qt=' + qVersion())" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
if /I not "%ENV_MODE%"=="embedded" exit /b 1
"%APP_PY%" -I -c "import sys; sys.path.insert(0, sys.argv[1]); from pip._internal.cli.main import main; raise SystemExit(main(sys.argv[2:]))" "%PIP_WHEEL%" --isolated --disable-pip-version-check check >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:HasPinnedPySide
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
"%APP_PY%" -I -c "import PySide6; from importlib.metadata import version; raise SystemExit(0 if version('%PYSIDE_DISTRIBUTION%') == '%PYSIDE_VERSION%' else 1)" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:ResetEmbeddedPackages
if /I not "%ENV_MODE%"=="embedded" exit /b 1
call :RemoveDirectoryRobust "%LOCAL_SITE%"
if errorlevel 1 exit /b 1
mkdir "%LOCAL_SITE%" >>"%LOG%" 2>&1
if not exist "%LOCAL_SITE%" exit /b 1
exit /b 0

:RemoveDirectoryRobust
set "REMOVE_TREE=%~1"
if not defined REMOVE_TREE exit /b 1
if not exist "%REMOVE_TREE%" exit /b 0
call :ValidatePrivateTree "%REMOVE_TREE%"
if errorlevel 1 exit /b 1
set "EMPTY_TREE=%RUNTIME%\empty-%RANDOM%-%RANDOM%"
if exist "%EMPTY_TREE%" exit /b 1
mkdir "%EMPTY_TREE%" >>"%LOG%" 2>&1
if not exist "%EMPTY_TREE%" exit /b 1
call :ValidatePrivateTree "%EMPTY_TREE%"
if errorlevel 1 exit /b 1
"%ROBOCOPY_EXE%" "%EMPTY_TREE%" "%REMOVE_TREE%" /MIR /R:2 /W:1 /XJ /NFL /NDL /NJH /NJS /NP /NC /NS >nul 2>>"%LOG%"
if errorlevel 8 exit /b 1
rmdir /s /q "%REMOVE_TREE%" >>"%LOG%" 2>&1
rmdir /s /q "%EMPTY_TREE%" >>"%LOG%" 2>&1
if exist "%REMOVE_TREE%" exit /b 1
if exist "%EMPTY_TREE%" exit /b 1
exit /b 0

:ValidatePrivateTree
if "%~1"=="" exit /b 1
set "VALIDATE_TREE=%~1"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$project=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\');$root=[IO.Path]::GetFullPath($env:VALIDATE_TREE).TrimEnd('\');if(-not $root.StartsWith($project+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Private tree escaped the project root.'};$stack=New-Object 'System.Collections.Generic.Stack[string]';$stack.Push($root);while($stack.Count -gt 0){$directory=Get-Item -LiteralPath $stack.Pop() -Force;if(-not $directory.PSIsContainer-or($directory.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'Unsafe private directory.'};foreach($entryPath in [IO.Directory]::EnumerateFileSystemEntries($directory.FullName)){$entry=Get-Item -LiteralPath $entryPath -Force;if($entry.Attributes-band[IO.FileAttributes]::ReparsePoint){throw 'Unsafe private reparse point.'};if($entry.PSIsContainer){$stack.Push($entry.FullName)}}};exit 0" >>"%DIAGNOSTIC_LOG%" 2>&1
exit /b %ERRORLEVEL%

:ReplaceDirectory
set "REPLACE_NEW=%~1"
set "REPLACE_TARGET=%~2"
goto ReplaceDirectoryValuesReady

:ReplaceDirectoryValuesReady
set "REPLACE_BACKUP=%REPLACE_TARGET%.old"
if not exist "%REPLACE_NEW%" exit /b 1
call :ValidatePrivateTree "%REPLACE_NEW%"
if errorlevel 1 exit /b 1
if exist "%REPLACE_TARGET%" (
    call :ValidatePrivateTree "%REPLACE_TARGET%"
    if errorlevel 1 exit /b 1
)
if exist "%REPLACE_BACKUP%" (
    call :ValidatePrivateTree "%REPLACE_BACKUP%"
    if errorlevel 1 exit /b 1
    if exist "%REPLACE_TARGET%" (
        call :RemoveDirectoryRobust "%REPLACE_BACKUP%"
        if errorlevel 1 exit /b 1
        if exist "%REPLACE_BACKUP%" exit /b 1
    ) else (
        move "%REPLACE_BACKUP%" "%REPLACE_TARGET%" >>"%LOG%" 2>&1
        if errorlevel 1 exit /b 1
        if exist "%REPLACE_BACKUP%" exit /b 1
        call :ValidatePrivateTree "%REPLACE_TARGET%"
        if errorlevel 1 exit /b 1
    )
)
if not exist "%REPLACE_TARGET%" goto ReplaceMoveNew
move "%REPLACE_TARGET%" "%REPLACE_BACKUP%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1

:ReplaceMoveNew
move "%REPLACE_NEW%" "%REPLACE_TARGET%" >>"%LOG%" 2>&1
if errorlevel 1 goto ReplaceRollback
if exist "%REPLACE_BACKUP%" (
    call :RemoveDirectoryRobust "%REPLACE_BACKUP%"
    if errorlevel 1 exit /b 1
)
if exist "%REPLACE_BACKUP%" exit /b 1
exit /b 0

:ReplaceRollback
if exist "%REPLACE_TARGET%" (
    call :RemoveDirectoryRobust "%REPLACE_TARGET%"
    if errorlevel 1 exit /b 1
)
if exist "%REPLACE_TARGET%" exit /b 1
if not exist "%REPLACE_BACKUP%" exit /b 1
call :ValidatePrivateTree "%REPLACE_BACKUP%"
if errorlevel 1 exit /b 1
move "%REPLACE_BACKUP%" "%REPLACE_TARGET%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
if exist "%REPLACE_BACKUP%" exit /b 1
if not exist "%REPLACE_TARGET%" exit /b 1
call :ValidatePrivateTree "%REPLACE_TARGET%"
if errorlevel 1 exit /b 1
exit /b 1

:DownloadAndVerify
set "DL_URL=%~1"
set "DL_FILE=%~2"
set "DL_HASH=%~3"
if not defined DL_HASH exit /b 1
if not exist "%DL_FILE%" goto DownloadFresh
call :VerifyFileHash "%DL_FILE%" "%DL_HASH%"
if not errorlevel 1 (
    set "LOG_MESSAGE=Reusing an already downloaded file that passed SHA-256 verification: %DL_FILE%"
    call :LogCurrent
    exit /b 0
)
del /f /q "%DL_FILE%" >nul 2>nul

:DownloadFresh
if exist "%DL_FILE%" del /f /q "%DL_FILE%" >nul 2>nul
set "LOG_MESSAGE=Downloading: %DL_URL%"
call :LogCurrent
call :TouchSetupLock
if errorlevel 1 exit /b 1

if not exist "%CURL_EXE%" goto DownloadWithPowerShell
"%CURL_EXE%" --fail --location --silent --show-error --retry 3 --retry-delay 2 --connect-timeout 30 --proto "=https" --proto-redir "=https" -o "%DL_FILE%" "%DL_URL%" >>"%LOG%" 2>&1
if not errorlevel 1 goto VerifyDownload
set "LOG_MESSAGE=curl failed; retrying with PowerShell."
call :LogCurrent

:DownloadWithPowerShell
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -TimeoutSec 300 -Uri $env:DL_URL -OutFile $env:DL_FILE" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1

:VerifyDownload
call :TouchSetupLock
if errorlevel 1 exit /b 1
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

:WriteWingetResolver
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';function Hash([byte[]]$b){$s=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($s.ComputeHash($b))).Replace('-','')}finally{$s.Dispose()}};$runtime=[IO.Path]::GetFullPath($env:RUNTIME).TrimEnd('\');$target=[IO.Path]::GetFullPath($env:WINGET_RESOLVER);$expected=Join-Path $runtime 'Validate-TrustedWinget.ps1';if($target -cne $expected){throw 'The WinGet resolver escaped its fixed runtime filename.'};$runtimeItem=Get-Item -LiteralPath $runtime -Force;if(-not $runtimeItem.PSIsContainer-or($runtimeItem.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'The private runtime is unsafe.'};if(Test-Path -LiteralPath $target){$old=Get-Item -LiteralPath $target -Force;if($old.PSIsContainer-or($old.Attributes-band[IO.FileAttributes]::ReparsePoint)-or-not[IO.File]::Exists($old.FullName)){throw 'The WinGet resolver target is unsafe.'}};$payload=$env:WINGET_RESOLVER_GZIP_B64_1+$env:WINGET_RESOLVER_GZIP_B64_2+$env:WINGET_RESOLVER_GZIP_B64_3;$compressed=[Convert]::FromBase64String($payload);$input=[IO.MemoryStream]::new($compressed);$gzip=[IO.Compression.GZipStream]::new($input,[IO.Compression.CompressionMode]::Decompress);$output=[IO.MemoryStream]::new();try{$gzip.CopyTo($output);$bytes=$output.ToArray()}finally{$output.Dispose();$gzip.Dispose();$input.Dispose()};if((Hash $bytes)-cne$env:WINGET_RESOLVER_SHA256){throw 'The embedded WinGet resolver hash is invalid.'};$candidate=Join-Path $runtime ('Validate-TrustedWinget.ps1.new.'+[Guid]::NewGuid().ToString('N'));$backup=$null;$published=$false;try{[IO.File]::WriteAllBytes($candidate,$bytes);$item=Get-Item -LiteralPath $candidate -Force;if($item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-or(Hash ([IO.File]::ReadAllBytes($item.FullName)))-cne$env:WINGET_RESOLVER_SHA256){throw 'The WinGet resolver candidate failed verification.'};$errors=$null;$tokens=$null;[Management.Automation.Language.Parser]::ParseFile($item.FullName,[ref]$tokens,[ref]$errors)|Out-Null;if($errors){throw ($errors|Out-String)};if(Test-Path -LiteralPath $target -PathType Leaf){$backup=Join-Path $runtime ('Validate-TrustedWinget.ps1.replaced.'+[Guid]::NewGuid().ToString('N'));[IO.File]::Replace($candidate,$target,$backup,$true)}else{[IO.File]::Move($candidate,$target)};$candidate=$null;$final=Get-Item -LiteralPath $target -Force;if($final.PSIsContainer-or($final.Attributes-band[IO.FileAttributes]::ReparsePoint)-or(Hash ([IO.File]::ReadAllBytes($final.FullName)))-cne$env:WINGET_RESOLVER_SHA256){throw 'The published WinGet resolver failed verification.'};$published=$true;if($backup){Remove-Item -LiteralPath $backup -Force;$backup=$null}}finally{if($candidate){Remove-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue};if($backup-and-not$published){Write-Warning ('A verified pre-replacement resolver backup was preserved at '+$backup)}}" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:ValidateTrustedWingetCache
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$runtime=[IO.Path]::GetFullPath($env:RUNTIME).TrimEnd('\');$cache=[IO.Path]::GetFullPath($env:TRUSTED_WINGET_PATH);if($cache-cne(Join-Path $runtime 'trusted-winget-path.txt')){throw 'The WinGet cache escaped its fixed runtime filename.'};$item=Get-Item -LiteralPath $cache -Force;if($item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-or-not[IO.File]::Exists($item.FullName)-or$item.Length-lt1-or$item.Length-gt32768){throw 'The WinGet cache is not a normal bounded file.'};$bytes=[IO.File]::ReadAllBytes($item.FullName);if($bytes.Length-ge3-and$bytes[0]-eq0xEF-and$bytes[1]-eq0xBB-and$bytes[2]-eq0xBF){throw 'The WinGet cache must not contain a UTF-8 BOM.'};$text=[Text.UTF8Encoding]::new($false,$true).GetString($bytes);if($text.IndexOfAny([char[]](13,10,0))-ge0-or[string]::IsNullOrWhiteSpace($text)){throw 'The WinGet cache content is malformed.'};$target=[IO.Path]::GetFullPath($text);if($target-cne$text-or[IO.Path]::GetFileName($target)-cne'winget.exe'){throw 'The cached WinGet path is not one exact absolute executable path.'};$winget=Get-Item -LiteralPath $target -Force;if($winget.PSIsContainer-or($winget.Attributes-band[IO.FileAttributes]::ReparsePoint)-or-not[IO.File]::Exists($winget.FullName)-or$winget.Length-gt32MB){throw 'The cached WinGet target is not a normal bounded file.'};$programFiles=[IO.Path]::GetFullPath([Environment]::GetFolderPath('ProgramFiles')).TrimEnd('\');$windowsApps=Join-Path $programFiles 'WindowsApps';$packageRoot=[IO.Path]::GetDirectoryName($target);if([IO.Path]::GetDirectoryName($packageRoot)-ine$windowsApps){throw 'The cached WinGet target is outside a direct WindowsApps package.'};$package=Get-Item -LiteralPath $packageRoot -Force;if(-not$package.PSIsContainer-or($package.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'The cached WinGet package root is unsafe.'};$manifest=Get-Item -LiteralPath (Join-Path $packageRoot 'AppxManifest.xml') -Force;if($manifest.PSIsContainer-or($manifest.Attributes-band[IO.FileAttributes]::ReparsePoint)-or$manifest.Length-gt4MB){throw 'The cached WinGet package manifest is unsafe.'}" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:CheckWingetRequirement
call :ValidateWinget
set "WINGET_CHECK_CODE=%ERRORLEVEL%"
if "%WINGET_CHECK_CODE%"=="0" exit /b 0
if "%WINGET_CHECK_CODE%"=="20" (
    set "FAIL_MESSAGE=Microsoft Desktop App Installer is not registered for this Windows user. Install or update App Installer from Microsoft, then run this setup again."
    set "REPAIR_HINT=Install or update App Installer from Microsoft Store, reopen your terminal, then retry."
    set "REPAIR_LINK=https://apps.microsoft.com/detail/9nblggh4nns1"
    exit /b 1
)
if "%WINGET_CHECK_CODE%"=="21" (
    set "FAIL_MESSAGE=Microsoft Desktop App Installer is present, but WinGet failed trusted package, signature, version, or official-source validation. Repair or update App Installer from Microsoft, then run this setup again."
    set "REPAIR_HINT=In Windows Settings, find App Installer and choose Repair. Then update it in Microsoft Store."
    set "REPAIR_LINK=https://apps.microsoft.com/detail/9nblggh4nns1"
    exit /b 1
)
if "%WINGET_CHECK_CODE%"=="23" (
    set "FAIL_MESSAGE=Microsoft Desktop App Installer is trusted, but its WinGet version is older than 1.29.280. Update App Installer from Microsoft, then run this setup again."
    set "REPAIR_HINT=Open a normal PowerShell or Command Prompt and run:"
    set "REPAIR_COMMAND=winget upgrade Microsoft.AppInstaller"
    set "REPAIR_FALLBACK=Then reopen the terminal and retry. If it fails, use the Microsoft Store link:"
    set "REPAIR_LINK=https://apps.microsoft.com/detail/9nblggh4nns1"
    exit /b 1
)
set "FAIL_MESSAGE=Trusted WinGet validation could not finish safely. Review setup.log, repair or update App Installer from Microsoft, then run this setup again."
set "REPAIR_HINT=Review setup.log, then update or repair App Installer from Microsoft. If it repeats, use a fresh official ZIP."
set "REPAIR_LINK=https://apps.microsoft.com/detail/9nblggh4nns1"
exit /b 1

:ValidateWinget
set "WINGET_VALIDATED=0"
set "WINGET_STATE=resolver-error"
call :WriteWingetResolver
if errorlevel 1 goto WingetResolverError
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%WINGET_RESOLVER%" >>"%LOG%" 2>&1
set "WINGET_RESOLVER_CODE=%ERRORLEVEL%"
if "%WINGET_RESOLVER_CODE%"=="0" goto WingetResolverTrusted
if "%WINGET_RESOLVER_CODE%"=="20" goto WingetResolverAbsent
if "%WINGET_RESOLVER_CODE%"=="21" goto WingetResolverInvalid
if "%WINGET_RESOLVER_CODE%"=="23" goto WingetResolverUnsupportedVersion
goto WingetResolverError

:WingetResolverTrusted
call :ValidateTrustedWingetCache
if errorlevel 1 goto WingetResolverError
set "WINGET_VALIDATED=1"
set "WINGET_STATE=trusted"
set "LOG_MESSAGE=FLEECE_SETUP_WINGET_OUTCOME=trusted"
call :LogCurrent
set "LOG_MESSAGE=Trusted WinGet validation passed and its concrete package path was cached privately."
call :LogCurrent
exit /b 0

:WingetResolverAbsent
set "WINGET_STATE=exact-package-absent"
set "LOG_MESSAGE=FLEECE_SETUP_WINGET_OUTCOME=exact-package-absent"
call :LogCurrent
set "LOG_MESSAGE=The exact Microsoft.DesktopAppInstaller package is not registered for this Windows user."
call :LogCurrent
exit /b 20

:WingetResolverInvalid
set "WINGET_STATE=present-invalid"
set "LOG_MESSAGE=FLEECE_SETUP_WINGET_OUTCOME=present-invalid"
call :LogCurrent
set "LOG_MESSAGE=Desktop App Installer is present, but no WinGet candidate passed the trusted validation contract."
call :LogCurrent
exit /b 21

:WingetResolverUnsupportedVersion
set "WINGET_STATE=unsupported-version"
set "LOG_MESSAGE=FLEECE_SETUP_WINGET_OUTCOME=unsupported-version"
call :LogCurrent
set "LOG_MESSAGE=Desktop App Installer passed trusted package, signature, and official-source validation, but WinGet is older than 1.29.280."
call :LogCurrent
exit /b 23

:WingetResolverError
set "WINGET_STATE=resolver-error"
set "LOG_MESSAGE=FLEECE_SETUP_WINGET_OUTCOME=resolver-error"
call :LogCurrent
set "LOG_MESSAGE=The embedded WinGet resolver or its private cache contract could not be validated safely."
call :LogCurrent
exit /b 22

:VerifyEverything
if not defined APP_PY goto FinalPythonFailed
if not defined APP_PYW goto FinalPythonFailed
if not exist "%APP_PY%" goto FinalPythonFailed
if not exist "%APP_PYW%" goto FinalPythonFailed
call :ValidateSelectedEnvironment
if errorlevel 1 goto FinalPythonFailed
call :VerifyPythonPackages
if errorlevel 1 goto FinalPackagesFailed
if not "%WINGET_VALIDATED%"=="1" goto FinalWingetFailed
if not "%WINGET_STATE%"=="trusted" goto FinalWingetFailed

call :CompileAppSource
if errorlevel 1 goto FinalSourceFailed
call :CheckBundledAssets
if errorlevel 1 goto FinalAssetsFailed
"%APP_PY%" -I "%APP_FILE%" --self-test >>"%LOG%" 2>&1
if errorlevel 1 goto FinalSelfTestFailed
exit /b 0

:FinalPythonFailed
set "FAIL_MESSAGE=Private Python failed its final verification."
set "REPAIR_HINT=Close other programs using this folder, check free disk space, then rerun setup."
exit /b 1

:FinalPackagesFailed
set "FAIL_MESSAGE=PySide6 failed its final verification."
set "REPAIR_HINT=Rerun setup with a working connection. See setup.log for the package check that failed."
exit /b 1

:FinalWingetFailed
set "FAIL_MESSAGE=WinGet failed its final verification."
set "REPAIR_HINT=Update or repair App Installer from Microsoft Store, then rerun setup."
set "REPAIR_LINK=https://apps.microsoft.com/detail/9nblggh4nns1"
exit /b 1

:FinalSourceFailed
set "FAIL_MESSAGE=Mass Installer.pyw changed or became unreadable during setup."
set "REPAIR_HINT=Re-extract the entire official release ZIP, then rerun setup."
exit /b 1

:FinalAssetsFailed
set "FAIL_MESSAGE=Bundled app icons or image failed final verification."
set "REPAIR_HINT=Re-extract the entire official release ZIP, including its assets folder, then rerun setup."
exit /b 1

:FinalSelfTestFailed
set "FAIL_MESSAGE=The Mass Installer app self-test failed."
set "REPAIR_HINT=See the last self-test error in setup.log, then rerun setup once. If it repeats, use a fresh official ZIP."
exit /b 1

:CompileAppSource
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
"%APP_PY%" -I -c "import os; from pathlib import Path; app=Path(os.environ['APP_FILE']); assert app.is_file(); compile(app.read_text(encoding='utf-8'), str(app), 'exec'); print('Application source compiled successfully.')" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:CheckBundledAssets
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
"%APP_PY%" -I -c "import ast, os, re, xml.etree.ElementTree as ET; from pathlib import Path; app=Path(os.environ['APP_FILE']); tree=ast.parse(app.read_text(encoding='utf-8')); assignments=[s.value for s in tree.body if isinstance(s,ast.Assign) for t in s.targets if isinstance(t,ast.Name) and t.id=='ICON_SLUG_BY_PACKAGE']; assert len(assignments)==1, 'Missing icon mapping'; icons=ast.literal_eval(assignments[0]); assert isinstance(icons,dict) and len(icons)==49, 'Unexpected icon mapping'; assert all(isinstance(s,str) and re.fullmatch(r'[a-z0-9]+',s) for s in icons.values()), 'Invalid icon slug'; assets=app.parent/'assets'; folder=assets/'app-icons'; assert assets.is_dir() and not assets.is_symlink() and folder.is_dir() and not folder.is_symlink(), 'Missing or linked icon folder'; files=[folder/(s+'.svg') for s in icons.values()]; bad=[p.name for p in files if not p.is_file() or p.is_symlink() or p.stat().st_size<1]; assert not bad, 'Missing or unsafe icons: '+', '.join(bad); [ET.parse(p) for p in files]; image=app.parent/'Mass Installer.png'; assert image.is_file() and not image.is_symlink() and image.stat().st_size>0, 'Missing or unsafe app image'; print('Bundled app icons and image passed preflight.')" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:CheckShortcutSupport
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$path=Join-Path $env:ROOT 'Mass Installer.lnk';if(Test-Path -LiteralPath $path){$item=Get-Item -LiteralPath $path -Force;if($item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'The existing Mass Installer shortcut is not a normal file.'}};$shell=New-Object -ComObject WScript.Shell;if(-not $shell){throw 'Windows shortcut COM support is unavailable.'};$probe=Join-Path $env:RUNTIME ('shortcut-preflight-'+[Guid]::NewGuid().ToString('N')+'.lnk');try{$link=$shell.CreateShortcut($probe);$link.TargetPath=$env:POWERSHELL_EXE;$link.WorkingDirectory=$env:RUNTIME;$link.Save();if(-not(Test-Path -LiteralPath $probe -PathType Leaf)){throw 'Windows did not save a test shortcut.'};$readback=$shell.CreateShortcut($probe);if([IO.Path]::GetFullPath($readback.TargetPath) -ine [IO.Path]::GetFullPath($env:POWERSHELL_EXE)){throw 'Windows did not preserve the test shortcut target.'}}finally{if(Test-Path -LiteralPath $probe){Remove-Item -LiteralPath $probe -Force}};Write-Output 'Windows shortcut creation and readback passed preflight.'" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:CreateShortcut
set "LINK_PATH=%ROOT%Mass Installer.lnk"
set "LINK_NEW=%RUNTIME%\shortcut.new.lnk"
set "LINK_BACKUP=%RUNTIME%\shortcut.previous.lnk"
set "LINK_TARGET=%APP_PYW%"
set "LINK_DIR=%ROOT%"
set "LINK_DESCRIPTION=Mass Installer"
set "LINK_ICON=%APP_PYW%,0"
if not exist "%LINK_TARGET%" exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $path=$env:LINK_PATH; $new=$env:LINK_NEW; $backup=$env:LINK_BACKUP; $arguments='-I '+[char]34+$env:APP_FILE+[char]34; $samePath={param($a,$b) [IO.Path]::GetFullPath($a).TrimEnd('\') -ieq [IO.Path]::GetFullPath($b).TrimEnd('\')}; $verify={param($shortcut,$stage) if(-not(& $samePath $shortcut.TargetPath $env:LINK_TARGET) -or $shortcut.Arguments -cne $arguments -or -not(& $samePath $shortcut.WorkingDirectory $env:LINK_DIR) -or $shortcut.Description -cne $env:LINK_DESCRIPTION -or [int]$shortcut.WindowStyle -ne 1 -or ($shortcut.IconLocation-replace ',\s+',',') -ine ($env:LINK_ICON-replace ',\s+',',') -or $shortcut.Hotkey){throw ($stage+' shortcut did not preserve its isolated launcher contract.')}}; if(Test-Path -LiteralPath $backup){if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $backup -Force}else{Move-Item -LiteralPath $backup -Destination $path}}; if(Test-Path -LiteralPath $new){Remove-Item -LiteralPath $new -Force}; $shell=New-Object -ComObject WScript.Shell; $link=$shell.CreateShortcut($new); $link.TargetPath=$env:LINK_TARGET; $link.Arguments=$arguments; $link.WorkingDirectory=$env:LINK_DIR; $link.WindowStyle=1; $link.Description=$env:LINK_DESCRIPTION; $link.IconLocation=$env:LINK_ICON; $link.Hotkey=''; $link.Save(); $candidate=$shell.CreateShortcut($new); & $verify $candidate 'New'; $hadOld=Test-Path -LiteralPath $path; $movedOld=$false; try{if($hadOld){Move-Item -LiteralPath $path -Destination $backup; $movedOld=$true}; Move-Item -LiteralPath $new -Destination $path; $verified=$shell.CreateShortcut($path); & $verify $verified 'Installed'; if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Force}; Write-Output ('Created and validated shortcut: ' + $path)}catch{if($movedOld){if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path -Force}; if(Test-Path -LiteralPath $backup){Move-Item -LiteralPath $backup -Destination $path}}elseif(-not $hadOld -and (Test-Path -LiteralPath $path)){Remove-Item -LiteralPath $path -Force}; throw}finally{if(Test-Path -LiteralPath $new){Remove-Item -LiteralPath $new -Force}}" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
if not exist "%LINK_PATH%" exit /b 1
exit /b 0

:LogCurrent
if not defined PATHS_VALIDATED exit /b 1
if not defined LOG_MESSAGE exit /b 0
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $line='[{0:yyyy-MM-dd HH:mm:ss.fff}] {1}{2}' -f [DateTime]::Now,$env:LOG_MESSAGE,[Environment]::NewLine; [IO.File]::AppendAllText($env:LOG,$line,[Text.UTF8Encoding]::new($false))" >nul 2>nul
set "LOG_MESSAGE="
exit /b %ERRORLEVEL%

:PauseIfNeeded
if "%NO_PAUSE%"=="1" exit /b 0
pause
exit /b 0
