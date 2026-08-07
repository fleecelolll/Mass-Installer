<div align="center">

# mass installer

A little tool I made with AI to quickly install or update useful Windows apps together through WinGet locally on 64-bit Windows.

</div>

<p align="center">
  <img src="Mass Installer.png" alt="mass installer" width="1120">
</p>

## features

- browse a curated catalog grouped into useful categories
- search for apps and select as many as you want
- install or update the selected apps in one clear queue
- see waiting, installing, installed, already-current, failed, and cancelled results
- use exact reviewed WinGet package IDs instead of free-form package searches

Tor Browser is intentionally not supported and is not included in the catalog.

## requirements

- 64-bit or ARM64 Windows
- a working Windows Package Manager (WinGet) installation
- an internet connection while setting up Mass Installer and installing apps

The setup and app check that WinGet is new enough and that the `winget` source matches Microsoft's official URL, identifier, type, and trusted status. They never reset or rewrite your WinGet sources. If a check fails, install or update **App Installer** from Microsoft and run setup again.

## installation

1. download the latest ZIP from the [releases page](../../releases/latest)
2. extract the folder instead of running it from inside the ZIP
3. run `Installer.bat` and leave its window open until every final check passes
4. open the `Mass Installer` shortcut created in the folder

The setup keeps the app runtime inside the extracted folder and does not need administrator access. It also installs one small shared launcher in `%LOCALAPPDATA%\Fleece Tools\Python Launcher` and sets `.pyw` files to open with it for your Windows account. The launcher always uses the selected tool's sibling `.venv\Scripts\pythonw.exe`, then its sibling `.runtime\python\pythonw.exe`. It does not change PATH, install global Python packages, or use another tool's private Python. You can copy the shortcut to your Desktop or pin it to the taskbar.

Before the first Fleece Tools association change, setup exports any existing per-user `.pyw` settings to that shared folder. If the previous setting cannot be backed up safely, setup stops without overwriting it. A later non-Fleece choice is also left alone.

The download contains the installer, app, and bundled app icons. Mass Installer keeps its Python environment, PySide6 packages, and other app-specific files inside this folder.

If compatible 64-bit Python 3.10 through 3.14 is already installed, setup creates a private **.venv** for Mass Installer. That environment keeps its packages separate but still relies on the existing Python installation. If compatible Python is unavailable or its private environment cannot be created, setup offers to download the official Python 3.14 embedded runtime into **.runtime** instead.

Close Mass Installer, then run **Installer.bat** again whenever you need to repair the app's private runtime. Setup safely refuses to run while the app or another setup window is open.

## usage

1. search or browse the app catalog
2. check the apps you want
3. review the selection
4. choose **Install _number_ apps**
5. leave Mass Installer open while the current installation finishes

Mass Installer submits only curated, exact package IDs to WinGet. WinGet then uses the reviewed package manifests and the application publishers' download locations. Some publisher installers may display a Windows administrator prompt, open their own installer window, require acceptance of a license, or request a restart. Mass Installer itself never restarts Windows automatically.

## built with

- [Windows Package Manager (WinGet)](https://learn.microsoft.com/windows/package-manager/winget/)
- [PySide6](https://doc.qt.io/qtforpython-6/)
- [Python](https://www.python.org/)

## privacy and removal

Mass Installer has no telemetry, analytics, accounts, uploads, or usage tracking. Your selections and activity stay on your computer. App icons are bundled locally and never fetched when the app opens. Network connections are still required for setup and installation: setup connects to official Python and PyPI sources, and WinGet connects to Microsoft's verified `winget` source and application publisher download services.

Close Mass Installer and delete this folder to remove Mass Installer's private runtime, packages, and logs.

Deleting this folder removes **Mass Installer only**. Applications installed through it are normal Windows applications and remain installed. Remove those separately through Windows Settings, WinGet, or the application's own uninstaller.

The shared `.pyw` launcher is used by every installed Fleece Tool, so removing one tool does not remove it. To restore the `.pyw` settings that existed before Fleece Tools first configured them, run `%LOCALAPPDATA%\Fleece Tools\Python Launcher\Restore pyw association.cmd`. The restore helper refuses to overwrite a newer non-Fleece choice. After restoring, and after removing every Fleece Tool that uses it, you can delete the shared `Python Launcher` folder. The registry backup files can contain local application names and paths, so review them before sharing.

## troubleshooting

If setup fails, check the internet connection and run **Installer.bat** again. Setup details are written to **setup.log**, and installation-session logs are kept under **.runtime\\logs**. These local logs can contain package names, installer output, and local folder paths, so review them before sharing.

If the **Mass Installer** shortcut does not open the app, run **Installer.bat** again and make sure every final check passes. Setup recreates the shortcut for the folder's current location. Keep the complete folder together; moving only one file breaks the private-runtime lookup.

An individual app can fail because its publisher installer is unavailable, WinGet metadata is temporarily out of date, Windows requires user approval, or the installer returns an error. Mass Installer reports each app separately so one failure does not hide the rest of the results.

## note

This project was made with AI.
