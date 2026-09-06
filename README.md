<div align="center">

# mass installer

A little tool I made with AI to quickly install or update useful Windows apps together through WinGet locally on 64-bit Windows.

<img src="Mass%20Installer.png" alt="Mass Installer app window" width="760">

</div>

## features

- Browse a curated catalog grouped into useful categories
- Search for apps and select as many as needed
- Install or update selected apps in one clear queue
- See waiting, installing, installed, current, failed, and cancelled results
- Use exact, selected WinGet package IDs instead of free-form searches
- Keep app icons bundled locally
- Never reset or rewrite WinGet sources
- Never restart Windows automatically

## requirements

- 64-bit x64 or ARM64 Windows
- Windows Package Manager 1.29 or newer through Microsoft App Installer
- An internet connection during setup and app installation
- Permission to install the selected Windows applications

## installation

1. Download the latest release ZIP.
2. Extract the complete folder.
3. Double-click `Installer.bat`.
4. Press **Y** once to accept the Terms and bundled Tool License and approve setup.
5. Leave the setup window open until every check passes.
6. Double-click the `Mass Installer` shortcut created in the folder.

Keep the full extracted folder path at 72 characters or fewer so Windows can install the private packages reliably.

Setup keeps the private Python runtime, dependencies, settings, and every app component inside the extracted folder. It does not require administrator access, change PATH, or install global Python packages. The generated folder-local shortcut starts the app directly with that private runtime, so Microsoft Store or system Python is not required.

Setup pins and verifies official Python 3.14.7, pip, PySide6-Essentials, and the official WinGet source contract. Downloaded runtime archives are checked against pinned SHA-256 hashes before use.

Run `Installer.bat` again to repair the private components or after moving the complete folder. Setup preserves app selections and logs and recreates the shortcut for the folder's current location.

## usage

1. Search or browse the app catalog.
2. Select the apps you want.
3. Review the selection.
4. Choose **Install**.
5. Leave Mass Installer open while the queue finishes.

Mass Installer uses selected package IDs from its catalog. WinGet resolves those IDs through the verified Microsoft community source and follows the publisher download locations defined there. A publisher installer can still request administrator approval, show its own window, require a license, or request a restart.

## built with

- [Windows Package Manager](https://learn.microsoft.com/windows/package-manager/winget/)
- [PySide6](https://doc.qt.io/qtforpython-6/)
- [Python](https://www.python.org/)

## privacy and removal

The app has no telemetry, analytics, advertisements, accounts, or uploads. Selections and activity stay on the computer. WinGet and publisher network requests occur only for setup and the installs you start. Logs can contain package names, installer output, and local folder paths, so review them before sharing.

To remove Mass Installer, close it and delete the extracted folder. This removes its folder-local shortcut, private runtime, dependencies, settings, logs, and app files. Applications installed through it are normal Windows applications and remain installed until removed separately.

## troubleshooting

If setup stops, review `setup.log`, correct the listed problem, and run `Installer.bat` again. Setup reports success only after its dependencies, offline self-tests, and shortcut all pass.

If the `Mass Installer` shortcut does not open, run `Installer.bat` again and keep the complete extracted folder together. Setup recreates and validates the shortcut for the folder's current location.

If WinGet validation fails, install or update **App Installer** from Microsoft to WinGet 1.29 or newer and run setup again. Setup does not reset or rewrite WinGet sources.

## license

Copyright 2026 Fleece. This project is source-available, not open source. The bundled [LICENSE](LICENSE) permits downloading, installing, and running an unmodified official release for lawful personal, non-commercial use. Modification, redistribution, sale, rebranding, and derivative versions remain prohibited. Third-party materials retain their own licenses, as listed in [assets/THIRD_PARTY_NOTICES.md](assets/THIRD_PARTY_NOTICES.md).

## note

This project was made with AI.

Review each selected application and its publisher terms before installing it.
