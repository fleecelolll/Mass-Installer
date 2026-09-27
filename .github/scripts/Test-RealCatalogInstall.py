"""Exercise one real catalog install on an ephemeral Windows 11 ARM runner.

This uses the private Python and app extracted from the release ZIP. It does not
run on developer machines or as part of the offline setup self-test.
"""

import importlib.util
import subprocess
import sys
import time
from importlib.machinery import SourceFileLoader
from pathlib import Path


PACKAGE_ID = "Microsoft.Sysinternals.ProcessExplorer"
MAX_WAIT_SECONDS = 10 * 60


def fail(message: str) -> None:
    raise RuntimeError(message)


def main() -> int:
    if len(sys.argv) not in (2, 3) or (len(sys.argv) == 3 and sys.argv[2] != "--dry-run"):
        fail("Usage: Test-RealCatalogInstall.py RELEASE_ROOT [--dry-run]")
    release_root = Path(sys.argv[1]).resolve(strict=True)
    dry_run = len(sys.argv) == 3
    private_python = release_root / ".runtime" / "python" / "python.exe"
    app_file = release_root / "Mass Installer.pyw"
    if Path(sys.executable).resolve() != private_python.resolve(strict=True):
        fail("This test must run with the ZIP's installed private Python.")
    if not app_file.is_file():
        fail("The ZIP-extracted app source is missing.")

    # The dry run stops before any event loop or WinGet command. The real CI run
    # uses normal app startup, including the trusted WinGet preflight.
    if dry_run:
        sys.argv.append("--self-test")
    loader = SourceFileLoader("mass_installer_release_test", str(app_file))
    specification = importlib.util.spec_from_loader(loader.name, loader)
    if specification is None:
        fail("Could not load the ZIP-extracted app source.")
    module = importlib.util.module_from_spec(specification)
    sys.modules[loader.name] = module
    loader.exec_module(module)

    application = module.QApplication(sys.argv)
    application.setStyle("Fusion")
    window = module.MassInstaller()
    window.show()
    if PACKAGE_ID not in module.APP_BY_ID:
        fail("The smoke-test package is not in the release catalog.")
    window.search_input.setText("Process Explorer")
    row = window.app_rows[PACKAGE_ID]
    if row.isHidden():
        fail("The catalog search did not reveal Process Explorer.")
    row.setChecked(True)
    if window.selected_ids != {PACKAGE_ID} or not window.review_button.isEnabled():
        fail("The package selection did not reach the review action.")
    window.review_button.click()
    if (
        window.stack.currentIndex() != window.REVIEW_PAGE
        or set(window.review_rows) != {PACKAGE_ID}
    ):
        fail("The selected package did not appear on the review page.")

    if dry_run:
        window.close()
        print("Dry-run catalog search, selection, and review passed; no app was installed.")
        return 0

    if window.winget_path is None:
        fail("The real run could not locate the setup-validated WinGet executable.")
    built_commands = []
    original_builder = window.build_winget_arguments

    def record_command(app_definition):
        arguments = original_builder(app_definition)
        built_commands.append((app_definition.package_id, list(arguments)))
        return arguments

    window.build_winget_arguments = record_command
    started = time.monotonic()
    clicked_install = False
    outcome = []
    timer = module.QTimer()

    def finish(message: str = "") -> None:
        timer.stop()
        outcome.append(message)
        application.quit()

    def poll() -> None:
        nonlocal clicked_install
        for widget in application.topLevelWidgets():
            if isinstance(widget, module.QMessageBox) and widget.isVisible():
                message = widget.text()
                widget.reject()
                finish(f"The app showed an error dialog: {message}")
                return
        if time.monotonic() - started > MAX_WAIT_SECONDS:
            finish("The real package workflow exceeded its 10-minute watchdog.")
            return
        if not clicked_install:
            if window.winget_ready:
                if not window.install_button.isEnabled():
                    finish("WinGet became ready, but the review install button stayed disabled.")
                    return
                window.install_button.click()
                clicked_install = True
            elif window.winget_version != "checking":
                finish(f"The app rejected its WinGet preflight: {window.winget_version}")
            return
        if window.stack.currentIndex() == window.RESULTS_PAGE and not window.install_active:
            result = window.results.get(PACKAGE_ID)
            if result is None or result[0] != "installed":
                finish(f"The app did not report a fresh install: {result!r}")
            else:
                finish()

    timer.timeout.connect(poll)
    timer.start(100)
    application.exec()
    if not outcome:
        fail("The Qt event loop exited before the install result was recorded.")
    if outcome[0]:
        fail(outcome[0])

    if len(built_commands) != 1 or built_commands[0][0] != PACKAGE_ID:
        fail(f"The app did not build exactly one catalog command: {built_commands!r}")
    arguments = built_commands[0][1]
    if arguments[:3] != ["install", "--id", PACKAGE_ID] or not all(
        option in arguments
        for option in (
            "--exact",
            "--source",
            "winget",
            "--silent",
            "--disable-interactivity",
            "--accept-source-agreements",
            "--accept-package-agreements",
        )
    ) or any(option in arguments for option in ("--ignore-security-hash", "--allow-reboot")):
        fail(f"The app built an unsafe or unexpected WinGet command: {arguments!r}")
    if window.total_jobs != 1 or window.completed_jobs != 1 or window.failed_ids:
        fail("The app did not complete the one-package queue cleanly.")
    if window.session_log_path is None or not window.session_log_path.is_file():
        fail("The app did not save its local installation log.")
    session_log = window.session_log_path.read_text(encoding="utf-8")
    if PACKAGE_ID not in session_log or "Process Explorer: Installed" not in session_log:
        fail("The app's local log did not record the installed package and result.")
    print(f"App result: {window.results[PACKAGE_ID]!r}")
    print(f"App session log: {window.session_log_path}")
    window.close()

    # Verify Windows Package Manager's record rather than trusting a zero exit
    # status or the app's UI alone. Portable packages should be listed here.
    list_command = [
        str(window.winget_path),
        "list",
        "--id",
        PACKAGE_ID,
        "--exact",
        "--source",
        "winget",
        "--disable-interactivity",
    ]
    for attempt in range(3):
        result = subprocess.run(
            list_command,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=60,
        )
        if result.returncode == 0 and PACKAGE_ID.casefold() in result.stdout.casefold():
            print("WinGet confirms the native portable Process Explorer package is installed.")
            return 0
        if attempt < 2:
            time.sleep(3)
    fail(
        "WinGet did not list the package after the app reported installation: "
        + (result.stdout + result.stderr)[-3000:]
    )


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"Real catalog install smoke failed: {error}", file=sys.stderr)
        raise SystemExit(1)
