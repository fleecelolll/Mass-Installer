@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Mass Installer Setup
set "INSTALLER_SELF=%~f0"
set "INSTALLER_ROOT=%~dp0"

set "NO_PAUSE=0"
set "ASSUME_YES=0"
set "SETUP_CHILD=0"
set "LOG_READY="
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
set "VENV_PY=%VENV%\Scripts\python.exe"
set "VENV_PYW=%VENV%\Scripts\pythonw.exe"
set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "CURL_EXE=%SystemRoot%\System32\curl.exe"
set "ROBOCOPY_EXE=%SystemRoot%\System32\robocopy.exe"
set "PYTHON_VERSION=3.14.7"
set "PYSIDE_VERSION=6.11.2"
set "PYSIDE_DISTRIBUTION=PySide6-Essentials"
set "PIP_VERSION=26.2.1"
set "PYPI_INDEX=https://pypi.org/simple"
set "PIP_WHEEL_URL=https://files.pythonhosted.org/packages/f3/6e/1736e5b4ae2b778ef2f81c47d797de9f891d4d8acb047a24ca37a60294dd/pip-26.2.1-py3-none-any.whl"
set "PIP_WHEEL_SHA256=71138ADF1F4CA900CDB7D289C21B7494329F2332B6D85F0E1C42108C0384ED3E"
set "WINGET_RESOLVER_SHA256=F784519A4690CF5E223F6C491EC22BE5176485BE5CB13E70F85D53069DC18AC2"
set "WINGET_RESOLVER_GZIP_B64_1=H4sIAAAAAAAACs07a2/bOLbf/SuIIIBsjKVJ0525hQfBNk2djmebB2Jns0Ca22WkY5sbmVRJKnHQyX+/OCQlUQ8nTncXuPnQxibPg4fnfZjdsZRCHsaaCX4uYQ4SeAzkgARTLbKgt3suxUKCUo1FlgLX6eOR4JrxHILeFHQ41ZLF+kQkQMK/g1RMcPK219uFdQaxhuSUrgz0CYulUGKuo4+g7rTIDrNswpWmaQoyqPaf57cpU0uQCHR0elDCkSMhMyEpcj0kZ5sWPh9cQLISPBmS6cEVVUvGFxoXjg4upx6dqchlDJcyRTpLrTM1+vnnOOHRA+ML0NGq5DcWq59jGi+hBT1J6ie7sqB28eu7B7h7vH2bvLu9fWjDzh6zhlzOJUx4AmtIonMa39EFBL3ePOfmnshEhReQUamgfz05i45ZCtNHpWE14XNxszvRsBqQ7z1CCOmbT9Gh1pLd5hoUCW8pT0gBVy3cjEYO6blgXA9IyIHs9Z48uhfwLWcSwlMhVzT9yCTEWsjH/rXSkvHFze451cshKT9+preQFpzsMg0rckA+gQ6RJxJ+ZhokTRGIGFASHgsZg9nO5qQfcqEtXHQ+nShUNso4SBIKSfqVFOyeQUEJf/RSigeyY1kgTBFERQk3nJOkYD3aMRBPFYfPHBjl9fxZh+Q6FfjphK7ZKl99Br7QS3JA3vx68uHfEMT2MjBfG7kVN3wzGo3XTGnlsBznaYqGaLfa7xyf4UKTOuvbi/RW5DyBhMxZCi9IdcLvxR2EHyxEJdHxGuJc09sUPLkeykW+Aq7VkFwzrm92Z2wFItcnLE2ZgljwpFxyrJ/lOsv1h0cNqpI5muf1p5wlN6PRKTzgb/1BNBPos/iiH5wGA7tT6UTk2tzCAflDMB7ae5E512wFpB9YrxDGS4jvwoD8ZLD/RILIgnqIQMofRQRSFogYnwvk/iOjCy6UZrGKzqWIQampplIbqx+NODz0PQhz+c7jeqL1NpSixR3lB2/DlZB3jC9KQ0cmJmcRHuNmNPoEulxBOn2Pis/HpYLpEtLUrhp25jRVPidHEqiGU3HFeCIecIeWub/hAqzJTjXlCZXJhGe53mKfVYUtNpowWN+XWRFvkHxd4G5vVN4HokJCvk7hheD3PE9TX0U6vxe5PhLZY9f+ru+p1JA0WcUQ/kB1jLdlODstOdby0TPtOoOe5zjLgPc9kxiWixjlb0Yjd3PwUK0cxk4+F0CTK8k0mnMRppZUgluyjLTl0EXeGdJ/h3wVamrX2MeA4rxecMX4J9AkFnmaGMdnRB4Fzsk1laBS0ugoFQqc1DsutwlkNTb6QBVMtQS6inDnTByqRx4XV4FnaYlvE0aj2s8hdKKvED4s8SYaMvmdqvGaaUj8mFAGKKeB0TilmYLE984kXADpcttNRKVeVkT/xtK0PyBPJEY1Jt8raRc/1/eCJTclwBVl+lhI5LT/y97eXnWoehgrLvSepiwx6SJBp5wQkesoqAE9dZ22uIWu0OnFHxtjKxm/sP3/mUSE9Z6wjgEwtjOtiKJz0I8kZSv2vKCMDYXTFCAjYU0fftnrtUG25rq01uvZUgJNGF9EM6rulPn3ZjRC0MM07b8v7gn1fehbyWBIDM62fbsTJ5IyzvjC1wnf0r37P05zteybsNHp0Lo3/Le16N+5U/+gsGb6COs5z6+M3Xed4vjIVGb83W8bo15TQA2QroDoUTEZ80FHZl7L3IqDK+cD3bGDLnE1mXqeQpHStSgAutkXCWCBfKnn7zDOzWCto8vZ8bsxjwXqscspbHo0JA2dqYds"
set "WINGET_RESOLVER_GZIP_B64_2=TyQoqgpz9Am0S2q9SIoR7zBNDT+F5k1q5UDdL7ij/hBqJ8Mu1IXbsmf/CLFIQB7TNL2l8d14HUOGSnrTOOdLyvxAbTFiVsjl7Dh857kmz8dkKs6VFitx+y+I9c3776RQZjxooey/kaknV/zNfFOKw/xmsT6ROeM0TRvJlI2FmH71N9o8Wmmn5XgMFyBFhHYgLcvpykLKxXLpAlbiHrpqTs9ybOVJQq8vRJrdnu0wFpayNcYnrBJ3H0wNoC6E0K16AzUKP/Wvx/yeScGxYnFLIk3AEOyjoiCKYDCIZpKtxjzpB1+CQW9XmS7J2/16QeZTDGwj5e1+UHJyLh5AmgqmDlYiK+hVG7/cv4n2sM3D70cWoTuOT8suX01OP04uOpeOxGqaQbyJarxKIlibbhK/H50fzn436lms/0SC30xN2TqGA5ieiCRPoV2gts8d2K0q6PXK8nXz3RSlO1K5uDydTU7GzYswPTRHeRs0s4vL6Wz88evV5PTTePYVDzuoumhHHraOQjvQMlcaktDV2xnVy0ivddAz9lXxEsYcSBtrkZU5NzRbAinKAdxCEB8BFdPMxdM5W0NCCvLYEeF0BVHQe+rZNKe/oZPm8Xwu2T3VUGAJBr1eFQB2JX1wfUGsT9/3S4vEptJhlq3dKglNB6Dega1bohYZ+bPmbq+WICE8Mz4SPc7XyILF8K2BybqdQa/MRs1nU3SFrvQOjj+Px0fj4uams8PZ+CCToIDrkHHjsq2vRvdL9t/0nuy1eEeMjkTONQnhG9kbbE0E1jTGyzY4QnqLFH1KpreJ7nIh6Qr9qfpRf3Pu4Wg7HWdOh1n2DIG+p7c1lgrnguAt3C9pUx2TY5M4Pl+E9hmvs4Fya6lfTSkrjaprUz3J2KxZIeVJc281DqgDeN83oUon8hXLYZ0rCxqc3QXtze/7OPSQEAyLMBAMSBjHtuWqasjYglOdS/gb85A8eceeCqmLUxezkPAjqBg4pnq9gdXy7EUVv6LSlCKBm5WQwywj5bQE+7ASFkxpkJAMyW2ujQvKCpkMMUPVuRoSIYmjRlTBPrljPEEczhKNj+rtaljhFMV0/GwWvishS2kMaAAfaHyXZ+VS5ZbmQgKNl9WxCOOkPGKtl9zOZd22F+J+cQVud+QE8VnEJiNs2IdPAMX9bPfSY2BAQoahwLMAr6gqfKtEVpnCLFSxBIhegpsskEwKbXQTI0VpRNXYwS+yjJ6+ZMiecDYogtuCxlmT64pyNgelu0uamt/xiWAQOXGg0XqVBoNNhAsCAfnLyYf6qdar9KZk4B8rTKDahQOWAv1yV1k1DF2R4BVHWCs1yhSWANdMG0X1CBVTs2ji1ts9nAKycEF+6LdfmfFIsct3Pv7W8vsOBSlFX3LpWxp5atxUTHmClc0zudXG63KTSswHG5Vc1d0s8dv+prpiellTe8wZvwRDcm2LvCOxyqhkSnBsxcoEK53JggsJR1RBR/cEyv5/LR3KPHtpaf6uhJRqdm8qMI/D/Naaeo1B1/iwVm6btJ12XiE1l1WTznNcu6EWGrLN4YrswZi6GW21+Geb2wXVhbZpBeTt/smHhgZUftmOBw9zvUTNwTK5DDmNSqs21Gugy238OXCFZIHBhC+QRyA1m7OYalNZlr71mX14LwblE4FUAflOgqZAkFS7J9mBu4jHeEF/N2kgmlwLtDzFBrvrBjJScXEX5zGRUWZuXL2j2floINgS3ZlkC7SHY5fctxWthqStdf7VYmi+t8hDCcq8CdjSZziwC1B5ihddn602tIMEYegAAvJmb29vj7zd/59f"
set "WINGET_RESOLVER_GZIP_B64_3=37Xtp4a27PjZJwEd7UWX35hBJplTloLltYtVdOpo63UStuNSRu+df8qdIdn5J9/pMG4PUeTm4cpAuJH2hnXesW5G5StTuwT/e//X/pfkp8GXyPzX/+voS4S/fN8b7j/tdjgOCTqXHBJCyYqmcyGxV+yQt4+/ov8yE8ZiVK3jJajrNzeNXYx37Nq/aUvB4gtTTd7YtwDFN/ANv8FHHg4b7vm1w11j6oJFDNFLysmb6NcO/bLKuK16OdWFdSakJtYYSBgmTKHLCxlHvxVrds/0Y0D2jQb+sv+X/XcdKuhTflEDxXzOYkbTsM7BJlW0uwpNrFHyFNFrnRVcFX5sNJqo0zxNz+TVkmmYZjSGvod2sDWL2LuEVabbOaFDV3Fo+P2THAl+D1IfS7EK/1CCt0WHabnRgwKFnR+435ki14dS0sebVzGJgVFwIH9Mz06JbaBGW/l+R9jlWUyZ2Y2T4waPbwEO5eJV+z9STV8FYJPDOcMg8gow81zrVQDYf/oM95Ba6b8expA6EmkKpmujosmY5yuQaFZ13/Dync4ZpIkiuYKE5LyIp/Ze9WMGapMm2gdyVSgvb+mHzORSps4fV9htiC8/Oyt8+UiXF5+NjpZu+PkjNCiYcvHnRhqJwxdTNOEYsXUlfxIcTtJ4WbXJqu4AeRq81iq85KE7A7EZfMX3+FtOU9VvP2HcNnvvpNK8W2tRtbyrfO24DbxvYD+OxdpbB7xd6DIie3lhzIUu2zeBuT9w3cbi52XlKhMxIYnFmxodeC4vwyufgdK2VKsn7GW/uWvaj0MopbHfs/GBoNevrl4JNomXeF56NVjs860MO9xmrtXR52aK5BwHxi0Taxic30PqfP22oSsfcXiIcHDxwmu9uo15bQXTNiv7CiUbw0a2MnxpANuciJbVnBkMbCj5qlOXT4bM7hI46Ei57ZXaUX9Xh8SNVusMVOPVdgJQ4SufCmBj0brbavF678YurMfHLmPsgFwAedtavX5TgH740F7cLxePO5+0bBikVPUyuAsxXr3qTT6jbgaDy+i2nKx742yP+U3itOWC8UL1rLcSqiFr3m2fzQ/5Y/86XlJ5fXPz3qtn8N+9ncHAyHXvx6SDLg243lo4W3kjYlaNS/0MdN7pnLqawK+ybYcgeb2BN4z8wiKq23d5lmEHq633FOWp2t3umihdp+M5bk7E/SZWXk+v0RZ3fY5kY4+puL+gaIkkNb3pdDgl1h+2mI1eqkS96WmJnXvUGOgwq0Y4qsRQswlb4GHRbRtUXZW3awg21KFTv/EVSp498wCobQCB08QGYxZTl+yffzdRceA5mO4w/8xIpq5P9eHui3NTZ7tBB9jvQmmyY5p1VFdHrnVUqCa7rT81wABhBGM7wrHgsQQNZWvYOAj7VwPFjxnSei8FayPmOlvFiKy/cwGYjeOTPQ6ke1xRutER2cHnEV+j8t1RdAJK0YXnI9wrn//IWLvxVMioZekKUN03a4UuPcY2j2kcvy/rfV16O4fOjrDvLSH0QLt020Qfc2J5jz0w3aWQtxDTXDnztfZJEmZfUM8ZZ2pJ4hQoT6u/xHnq/R/vvu8wlDYAAA=="

set "NATIVE_ARCH=%PROCESSOR_ARCHITECTURE%"
if defined PROCESSOR_ARCHITEW6432 set "NATIVE_ARCH=%PROCESSOR_ARCHITEW6432%"
if /I "%NATIVE_ARCH%"=="AMD64" goto ArchitectureX64
if /I "%NATIVE_ARCH%"=="ARM64" goto ArchitectureArm64
set "FAIL_MESSAGE=This installer currently supports 64-bit and ARM64 Windows only."
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
    goto Failed
)
if not exist "%ROBOCOPY_EXE%" (
    set "FAIL_MESSAGE=Trusted Windows file-copy support is missing from the system folder."
    goto Failed
)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "if([IO.Path]::GetFullPath($env:ROOT).Length -gt [int]$env:MAX_ROOT_LENGTH){exit 2}" >nul 2>nul
if errorlevel 1 (
    set "FAIL_MESSAGE=The complete app folder path must be 72 characters or fewer. Move the extracted folder closer to the drive root and try again."
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
    goto Failed
)
set "PATHS_VALIDATED=1"
call :CheckRootWritePermission
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup cannot write to this app folder. Move it to a folder owned by this Windows user and try again."
    goto Failed
)
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>nul
if not exist "%RUNTIME%" (
    set "FAIL_MESSAGE=Could not create the private runtime folder."
    goto Failed
)
call :AcquireSetupLock
if errorlevel 1 goto SetupAlreadyRunning

:PrepareSetupLog
if exist "%LOG%" del /f /q "%LOG%" >nul 2>nul
if exist "%LOG%" (
    set "FAIL_MESSAGE=The previous setup log could not be replaced safely."
    goto Failed
)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$stream=[IO.File]::Open($env:LOG,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$stream.Dispose()" >nul 2>nul
if errorlevel 1 (
    set "FAIL_MESSAGE=A fresh private setup log could not be created safely."
    goto Failed
)
set "LOG_READY=1"
set "DIAGNOSTIC_LOG=%LOG%"
call :EnsureAppClosed
if errorlevel 1 (
    set "FAIL_MESSAGE=Mass Installer is open. Close the app before installing or repairing its files."
    goto Failed
)
if not exist "%DOWNLOADS%" mkdir "%DOWNLOADS%" >>"%LOG%" 2>&1
if not exist "%DOWNLOADS%" (
    set "FAIL_MESSAGE=Could not create the private download folder."
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
    goto Failed
)
if exist "%VENV%" call :RemoveDirectoryRobust "%VENV%"
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
call :TouchSetupLock
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup lost ownership of its private setup lock."
    goto Failed
)
call :InstallPythonPackages
if errorlevel 1 (
    set "FAIL_MESSAGE=PySide6 could not be installed and verified."
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
call :ValidateWinget
set "WINGET_CHECK_CODE=%ERRORLEVEL%"
if "%WINGET_CHECK_CODE%"=="0" goto WingetReady
if "%WINGET_CHECK_CODE%"=="20" (
    set "FAIL_MESSAGE=Microsoft Desktop App Installer is not registered for this Windows user. Install or update App Installer from Microsoft, then run this setup again."
    goto Failed
)
if "%WINGET_CHECK_CODE%"=="21" (
    set "FAIL_MESSAGE=Microsoft Desktop App Installer is present, but WinGet failed trusted package, signature, version, or official-source validation. Repair or update App Installer from Microsoft, then run this setup again."
    goto Failed
)
set "FAIL_MESSAGE=Trusted WinGet validation could not finish safely. Review setup.log, repair or update App Installer from Microsoft, then run this setup again."
goto Failed

:WingetReady
echo      Testing every required component without installing apps...
call :TouchSetupLock
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup lost ownership of its private setup lock."
    goto Failed
)
call :VerifyEverything
if errorlevel 1 (
    set "FAIL_MESSAGE=One or more final component checks failed."
    goto Failed
)
echo      Creating the Mass Installer start shortcut...
call :CreateShortcut
if errorlevel 1 (
    set "FAIL_MESSAGE=The start shortcut could not be created."
    goto Failed
)
call :WriteSetupMarker
if errorlevel 1 (
    set "FAIL_MESSAGE=Setup finished its checks but could not save the completion marker."
    goto Failed
)
echo      Every check passed.

if exist "%DOWNLOADS%" call :RemoveDirectoryRobust "%DOWNLOADS%"
if exist "%DOWNLOADS%" (
    set "FAIL_MESSAGE=Setup passed its checks but could not safely remove temporary downloads."
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
set "LOG_MESSAGE=ERROR: %FAIL_MESSAGE%"
if defined LOG_READY call :LogCurrent
if defined PATHS_VALIDATED call :ReleaseSetupLock
echo.
echo  ==================================================
echo                     SETUP STOPPED
echo  ==================================================
echo.
echo   %FAIL_MESSAGE%
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
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\');$volume=[IO.Path]::GetPathRoot($root).TrimEnd('\');if([string]::IsNullOrWhiteSpace($root)-or $root -ieq $volume){throw 'Unsafe project root.'};$rootItem=Get-Item -LiteralPath $root -Force;if(-not $rootItem.PSIsContainer-or($rootItem.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'The project root must be a normal directory.'};$targets=@($env:RUNTIME,$env:VENV,$env:DOWNLOADS,$env:PYTHON_DIR,(Join-Path $env:PYTHON_DIR 'Lib'),$env:LOCAL_SITE,$env:SETUP_LOCK,($env:PYTHON_DIR+'.new'),($env:PYTHON_DIR+'.old'),($env:VENV+'.old'),(Join-Path $env:RUNTIME 'environment-before-package-repair'),(Join-Path $env:RUNTIME 'environment-before-package-repair.new'),(Join-Path $env:RUNTIME 'environment-before-package-repair.old'),(Join-Path $env:RUNTIME 'setup-check'));foreach($name in @('FFMPEG_DIR','DENO_DIR','HERCULES_DIR','LUA_DIR')){$value=[Environment]::GetEnvironmentVariable($name);if($value){$targets+=@($value,($value+'.new'),($value+'.old'),($value+'.extract'))}};$prefix=$root+'\';foreach($target in $targets){if([string]::IsNullOrWhiteSpace($target)){throw 'A private setup path is empty.'};$full=[IO.Path]::GetFullPath($target).TrimEnd('\');if(-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'A private setup path escaped the project root.'};if(Test-Path -LiteralPath $full){$item=Get-Item -LiteralPath $full -Force;if(-not $item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'A private setup directory is unsafe.'}}};foreach($file in @($env:LOG,$env:SETUP_MARKER,($env:SETUP_MARKER+'.new'),$env:SETUP_LOCK_OWNER,($env:SETUP_LOCK_OWNER+'.new'),$env:PIP_WHEEL,$env:TRUSTED_WINGET_PATH,$env:WINGET_RESOLVER)){if([string]::IsNullOrWhiteSpace($file)){continue};$full=[IO.Path]::GetFullPath($file);if(-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'A private setup file escaped the project root.'};if(Test-Path -LiteralPath $full){$item=Get-Item -LiteralPath $full -Force;if($item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'A private setup file is unsafe.'}}};exit 0" >nul 2>nul
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


:FindBasePython
set "BASE_PY="
where py.exe >nul 2>nul
if errorlevel 1 goto FindPathPython
for %%V in (3.14 3.13 3.12 3.11 3.10) do call :TryPyTag %%V
if defined BASE_PY exit /b 0

:FindPathPython
call :TryPythonCommand python.exe
if defined BASE_PY exit /b 0
call :TryPythonCommand python3.exe
if defined BASE_PY exit /b 0
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

:TryPythonCommand
if defined BASE_PY exit /b 0
where %~1 >nul 2>nul
if errorlevel 1 exit /b 1
set "CANDIDATE_FILE=%RUNTIME%\python-candidate.txt"
%~1 -I -c "import sys; print(sys.executable)" >"%CANDIDATE_FILE%" 2>>"%LOG%"
if errorlevel 1 exit /b 1
set "CANDIDATE="
set /p "CANDIDATE="<"%CANDIDATE_FILE%"
del /f /q "%CANDIDATE_FILE%" >nul 2>nul
if not defined CANDIDATE exit /b 1
call :TryPythonPath "%CANDIDATE%"
exit /b %ERRORLEVEL%

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
set "LOG_MESSAGE=Found compatible base CPython: %~1"
call :LogCurrent
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
"%~1\python.exe" -I -c "import sys, struct, site; ok = sys.implementation.name == 'cpython' and sys.version_info[:3] == (3, 14, 7) and struct.calcsize('P') == 8 and any(p.lower().endswith(r'lib\site-packages') for p in sys.path); raise SystemExit(0 if ok else 1)" >>"%LOG%" 2>&1
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

if exist "%VENV%" call :RemoveDirectoryRobust "%VENV%"
if exist "%VENV%" exit /b 1

set "LOG_MESSAGE=Creating virtual environment with: %BASE_PY%"
call :LogCurrent
"%BASE_PY%" -I -m venv --copies "%VENV%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
call :ValidateVenv
exit /b %ERRORLEVEL%

:InstallPythonPackages
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
call :CurrentPackagesFullyHealthy
if not errorlevel 1 exit /b 0
call :BeginPackageTransaction
if errorlevel 1 exit /b 1
if /I "%ENV_MODE%"=="venv" call :InstallVenvPackages
if /I "%ENV_MODE%"=="embedded" call :InstallEmbeddedPackages
set "PACKAGE_TRANSACTION_CODE=%ERRORLEVEL%"
call :FinishPackageTransaction %PACKAGE_TRANSACTION_CODE%
exit /b %ERRORLEVEL%

:CurrentPackagesFullyHealthy
if /I "%ENV_MODE%"=="venv" (
    call :HasPinnedPip
    if errorlevel 1 exit /b 1
)
call :HasPinnedPySide
if errorlevel 1 exit /b 1
call :VerifyPythonPackages
exit /b %ERRORLEVEL%

:BeginPackageTransaction
set "PACKAGE_BACKUP=%RUNTIME%\environment-before-package-repair"
set "PACKAGE_BACKUP_NEW=%PACKAGE_BACKUP%.new"
set "PACKAGE_TARGET="
set "PACKAGE_BACKUP_PROBE="
if /I "%ENV_MODE%"=="venv" set "PACKAGE_TARGET=%VENV%"
if /I "%ENV_MODE%"=="embedded" set "PACKAGE_TARGET=%PYTHON_DIR%"
if /I "%ENV_MODE%"=="venv" set "PACKAGE_BACKUP_PROBE=Scripts\python.exe"
if /I "%ENV_MODE%"=="embedded" set "PACKAGE_BACKUP_PROBE=python.exe"
if not defined PACKAGE_TARGET exit /b 1
if not defined PACKAGE_BACKUP_PROBE exit /b 1
if exist "%PACKAGE_BACKUP%" (
    call :ValidatePrivateTree "%PACKAGE_BACKUP%"
    if errorlevel 1 exit /b 1
    if not exist "%PACKAGE_BACKUP%\%PACKAGE_BACKUP_PROBE%" exit /b 1
    set "LOG_MESSAGE=Recovering the local package environment left by an interrupted repair."
    call :LogCurrent
    call :ReplaceDirectory "%PACKAGE_BACKUP%" "%PACKAGE_TARGET%"
    if errorlevel 1 exit /b 1
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

:InstallVenvPackages
call :EnsureCurrentVenvPip
if errorlevel 1 exit /b 1
call :HasPinnedPySide
if errorlevel 1 goto CheckVenvPip
call :VerifyPythonPackages
if not errorlevel 1 exit /b 0

:CheckVenvPip
"%APP_PY%" -I -m pip --version >>"%LOG%" 2>&1
if not errorlevel 1 goto InstallPinnedVenvPackage
set "LOG_MESSAGE=pip was missing; attempting ensurepip repair."
call :LogCurrent
"%APP_PY%" -I -m ensurepip --upgrade >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1

:InstallPinnedVenvPackage
set "LOG_MESSAGE=Installing pinned %PYSIDE_DISTRIBUTION% %PYSIDE_VERSION% from official PyPI."
call :LogCurrent
"%APP_PY%" -I -m pip --isolated --disable-pip-version-check install --upgrade --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" "%PYSIDE_DISTRIBUTION%==%PYSIDE_VERSION%" >>"%LOG%" 2>&1
set "PACKAGE_INSTALL_CODE=%ERRORLEVEL%"
goto CheckInstalledPackages

:EnsureCurrentVenvPip
call :HasPinnedPip
if not errorlevel 1 exit /b 0
"%APP_PY%" -I -m pip --version >>"%LOG%" 2>&1
if not errorlevel 1 goto UpgradeCurrentVenvPip
set "LOG_MESSAGE=pip was missing; attempting ensurepip repair."
call :LogCurrent
"%APP_PY%" -I -m ensurepip --upgrade >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
:UpgradeCurrentVenvPip
"%APP_PY%" -I -m pip --isolated --disable-pip-version-check install --upgrade --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" "pip==%PIP_VERSION%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
"%APP_PY%" -I -c "from importlib.metadata import version; raise SystemExit(0 if version('pip') == '%PIP_VERSION%' else 1)" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

:HasPinnedPip
if not defined APP_PY exit /b 1
if not exist "%APP_PY%" exit /b 1
"%APP_PY%" -I -c "from importlib.metadata import version; raise SystemExit(0 if version('pip') == '%PIP_VERSION%' else 1)" >>"%LOG%" 2>&1
exit /b %ERRORLEVEL%

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

:CheckInstalledPackages
if not "%PACKAGE_INSTALL_CODE%"=="0" goto RepairPythonPackages
call :VerifyPythonPackages
if not errorlevel 1 exit /b 0

:RepairPythonPackages
echo      A component check failed. Repairing local packages...
set "LOG_MESSAGE=Initial package validation failed; forcing a clean package reinstall."
call :LogCurrent
if /I "%ENV_MODE%"=="venv" goto RepairVenvPackages
if /I "%ENV_MODE%"=="embedded" goto RepairEmbeddedPackages
exit /b 1

:RepairVenvPackages
"%APP_PY%" -I -m pip --isolated --disable-pip-version-check install --upgrade --force-reinstall --no-cache-dir --only-binary=:all: --index-url "%PYPI_INDEX%" "%PYSIDE_DISTRIBUTION%==%PYSIDE_VERSION%" >>"%LOG%" 2>&1
goto RepairPackagesFinished

:RepairEmbeddedPackages
call :ResetEmbeddedPackages
if errorlevel 1 exit /b 1
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

:ReplaceDirectoryCurrent
if not defined REPLACE_NEW exit /b 1
if not defined REPLACE_TARGET exit /b 1

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

:WingetResolverError
set "WINGET_STATE=resolver-error"
set "LOG_MESSAGE=FLEECE_SETUP_WINGET_OUTCOME=resolver-error"
call :LogCurrent
set "LOG_MESSAGE=The embedded WinGet resolver or its private cache contract could not be validated safely."
call :LogCurrent
exit /b 22

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
if not "%WINGET_STATE%"=="trusted" exit /b 1

"%APP_PY%" -I -c "import os; from pathlib import Path; app=Path(os.environ['APP_FILE']); assert app.is_file(); compile(app.read_text(encoding='utf-8'), str(app), 'exec'); print('Application source compiled successfully.')" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
"%APP_PY%" -I "%APP_FILE%" --self-test >>"%LOG%" 2>&1
if errorlevel 1 exit /b 1
exit /b 0

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
