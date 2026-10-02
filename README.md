<div align="center">

# mass installer

Current audit update: **v1.0.15**. Includes app-specific bug fixes, bounded offline regression/performance tests, and shared setup hardening.

All Fleece desktop tools use the same installation workflow: download the official ZIP, extract the entire folder, run `Installer.bat`, accept the bundled Terms/Tool License, wait for final checks, then open the folder-local shortcut. Setup installs a private runtime without changing system Python or requiring administrator access. Rerun it to repair or refresh a moved shortcut. Keep the full path at most 72 characters, without percent signs. Architecture support and extra components vary by tool; File Converter remains x64-only.

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
- Windows Package Manager 1.29.280 or newer through Microsoft App Installer
- An internet connection during setup and app installation
- Permission to install the selected Windows applications

Before downloading, run `winget --version` in PowerShell or Command Prompt. If it is older than `v1.29.280`, update Microsoft's App Installer first. This minimum includes Microsoft's stable fix for [CVE-2026-68821](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2026-68821/); setup will not bypass it.

## installation

1. Download the latest release ZIP.
2. Extract the complete folder.
3. Double-click `Installer.bat`.
4. Press **Y** once to accept the Terms and bundled Tool License and approve setup.
5. Leave the setup window open until every check passes.
6. Double-click the `Mass Installer` shortcut created in the folder.

Keep the full extracted folder path at 72 characters or fewer so Windows can install the private packages reliably.

Setup keeps the private Python runtime, dependencies, settings, and every app component inside the extracted folder. It does not require administrator access, change PATH, or install global Python packages. The generated folder-local shortcut starts the app directly with that private runtime, so Microsoft Store or system Python is not required.

Setup pins and verifies official Python 3.14.7, pip, PySide6-Essentials, and the official WinGet source contract. Downloaded runtime archives and the complete PyPI wheel dependency set are checked against pinned SHA-256 hashes before use. Setup automatically selects the bundled x64 or ARM64 requirements file; keep both files with the extracted release.

Run `Installer.bat` again to repair the private components or after moving the complete folder. Setup preserves saved selection files and logs and recreates the shortcut for the folder's current location. The current selection is not automatically restored after closing the app; use **Save selection** and **Load selection** to reuse it.

## 1.0.14 security update

- Require reviewed SHA-256 hashes for every Python dependency download during setup and repair.
- Include complete architecture-specific dependency lock files in the release ZIP.
- Keep the same UI, dependency versions, WinGet minimum version, public download, and folder-local setup process.
- Run the existing release gate from the exact canonical ZIP on all supported CI runners.

## usage

1. Search or browse the app catalog.
2. Select the apps you want.
3. Review the selection.
4. Choose **Install**.
5. Leave Mass Installer open while the queue finishes.

Mass Installer uses selected package IDs from its catalog. WinGet resolves those IDs through the verified Microsoft community source and follows the publisher download locations defined there. A publisher installer can still request administrator approval, show its own window, require a license, or request a restart.

**Stop after current app** lets the active installer finish and cancels the remaining queue. Pressing it again offers a separately confirmed emergency force stop of WinGet. Force stopping can leave an app partially installed, and a publisher installer may continue separately. Closing the window during an active queue does not silently kill an installer.

Installer output is processed in 64 KiB slices to keep window events responsive. Individual output lines retain at most 8,192 characters; result classification retains the latest 300 lines, and the activity view retains 1,500 lines. Session logs are capped at 4 MiB. Managed install/crash logs are normally retained for at most 30 days, 20 files, and 32 MiB in total, with the current session protected. These are application-level limits, not a cap on a publisher installer's memory, disk use, or execution time.

## built with

- [Windows Package Manager](https://learn.microsoft.com/windows/package-manager/winget/)
- [PySide6](https://doc.qt.io/qtforpython-6/)
- [Python](https://www.python.org/)

## privacy and removal

The app has no telemetry, analytics, advertisements, accounts, or uploads. Selections and activity stay on the computer. WinGet and publisher network requests occur only for setup and the installs you start. Logs can contain package names, installer output, and local folder paths, so review them before sharing.

To remove Mass Installer, close it and delete the extracted folder. This removes its folder-local shortcut, private runtime, dependencies, settings, logs, and app files. Applications installed through it are normal Windows applications and remain installed until removed separately.

## troubleshooting

If setup stops, the window shows the failed check and a short **How to fix it** instruction immediately. The same instruction and technical cause are saved in `setup.log`; review the log for local paths before sharing it. WinGet and Windows shortcut checks run before downloads. App source and bundled assets are checked as soon as private Python is ready, before PySide6 installation. Download, package, and runtime failures stop setup when their step fails. Setup reports success only after its dependencies, offline self-tests, and shortcut all pass.

If the `Mass Installer` shortcut does not open, run `Installer.bat` again and keep the complete extracted folder together. Setup recreates and validates the shortcut for the folder's current location.

If a trusted WinGet is merely outdated, open a normal PowerShell or Command Prompt and run Microsoft's `winget upgrade Microsoft.AppInstaller`. If WinGet is missing or that command fails, [install or update App Installer from Microsoft Store](https://apps.microsoft.com/detail/9nblggh4nns1). If App Installer is present but fails trust validation, use Windows Settings to repair it before updating; do not bypass the trust check. Reopen the terminal, confirm `winget --version` is at least `v1.29.280`, then run setup again. [Microsoft's App Installer guidance](https://learn.microsoft.com/en-us/windows/msix/app-installer/install-update-app-installer) has the official installation and update options. Setup checks WinGet before downloading private Python packages and again before reporting success; it does not reset or rewrite WinGet sources.

## license

Copyright 2026 Fleece. This project is source-available, not open source. The bundled [LICENSE](LICENSE) permits downloading, installing, and running an unmodified official release for lawful personal, non-commercial use. Modification, redistribution, sale, rebranding, and derivative versions remain prohibited. Third-party materials retain their own licenses, as listed in [assets/THIRD_PARTY_NOTICES.md](assets/THIRD_PARTY_NOTICES.md).

## offline regression checks

From the extracted source folder, run `.runtime\python\python.exe -I scripts\Test-AppSafety.py`. The suite uses fake WinGet processes, offscreen Qt, and disposable profile/log files. It does not install any catalog app. It checks profile validation and atomic saves, source/version checks, safe command construction, cancellation, streamed UTF-8 output, resource limits, and bounded GUI workloads. Use `--report PATH` to save measurements as JSON. Timing budgets are regression tripwires, not installation-speed guarantees.

## note

This project was made with AI.

Review each selected application and its publisher terms before installing it.
