"""Offline regressions using fake WinGet/QProcess and disposable profile/log files.

Run with .runtime/python/python.exe -I scripts/Test-AppSafety.py.
Optional --report PATH writes machine-readable bounded workload measurements.
No catalog application or publisher installer is executed.
"""
import argparse
import codecs
from collections import deque
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import time
import tracemalloc
import unittest
from unittest.mock import patch

os.environ["QT_QPA_PLATFORM"] = "offscreen"
root = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("audited_mass", str(root / "Mass Installer.pyw"))
spec = importlib.util.spec_from_loader(loader.name, loader)
appmod = importlib.util.module_from_spec(spec)
sys.modules[loader.name] = appmod
started = time.perf_counter()
loader.exec_module(appmod)
measurements = {"module_import_seconds": time.perf_counter() - started}
application = appmod.QApplication.instance() or appmod.QApplication([])
real_process = appmod.QProcess


class FakeProcess:
    def __init__(self, data=b""):
        self.data = data
        self.read_sizes = []
        self.deleted = False
        self.killed = False

    def readAllStandardOutput(self):
        data, self.data = self.data, b""
        self.read_sizes.append(len(data))
        return data

    def read(self, maximum):
        self.read_sizes.append(min(maximum, len(self.data)))
        data, self.data = self.data[:maximum], self.data[maximum:]
        return data

    def bytesAvailable(self):
        return len(self.data)

    def state(self):
        return real_process.Running if not self.killed else real_process.NotRunning

    def kill(self):
        self.killed = True

    def deleteLater(self):
        self.deleted = True


class InstallerSafety(unittest.TestCase):
    def run(self, result=None):
        started = time.perf_counter()
        try:
            return super().run(result)
        finally:
            measurements.setdefault("test_seconds", {})[self._testMethodName] = time.perf_counter() - started

    def setUp(self):
        with patch.object(sys, "argv", ["audit", "--self-test"]):
            started = time.perf_counter()
            self.window = appmod.MassInstaller()
            measurements.setdefault("offscreen_window_startup_seconds", time.perf_counter() - started)
        self.window.winget_path = Path("C:/injected/winget.exe")
        self.warnings = []
        self.warning_patch = patch.object(appmod.QMessageBox, "warning", side_effect=lambda *args: self.warnings.append(args))
        self.info_patch = patch.object(appmod.QMessageBox, "information", return_value=None)
        self.warning_patch.start()
        self.info_patch.start()

    def tearDown(self):
        self.window.next_install_timer.stop()
        self.window.preflight_timer.stop()
        self.window.install_active = False
        self.window.process = None
        self.window.preflight_process = None
        self.window.close()
        self.window.deleteLater()
        application.sendPostedEvents(None, appmod.QEvent.DeferredDelete)
        application.processEvents()
        self.info_patch.stop()
        self.warning_patch.stop()

    def test_malformed_version_is_rejected_without_integer_conversion_crash(self):
        self.window.finish_winget_preflight(True, "v" + "9" * 5000 + ".29.280")
        self.assertFalse(self.window.winget_ready)
        self.assertLess(len(self.window.winget_version), 100)

    def test_deferred_focus_does_not_outlive_target(self):
        exceptions = []
        with patch.object(sys, "excepthook", side_effect=lambda *args: exceptions.append(args)):
            self.window.set_page(self.window.SELECT_PAGE)
            self.window.search_input.deleteLater()
            application.sendPostedEvents(None, appmod.QEvent.DeferredDelete)
            application.processEvents()
        self.assertEqual(exceptions, [])

    def test_version_and_official_source_contract(self):
        for value, accepted in [("v1.29.279", False), ("v1.29.280", True),
                                ("v1.30.0", True), ("v1.29.280-preview", False),
                                ("not-a-version", False)]:
            self.window.finish_winget_preflight(True, value)
            self.assertEqual(self.window.winget_ready, accepted)
        source = dict(Name="winget", Arg=appmod.OFFICIAL_WINGET_SOURCE_URL,
            Data=appmod.OFFICIAL_WINGET_SOURCE_ID, Identifier=appmod.OFFICIAL_WINGET_SOURCE_ID,
            Type=appmod.OFFICIAL_WINGET_SOURCE_TYPE, TrustLevel=["Trusted"])
        self.assertTrue(self.window.is_official_winget_source(json.dumps(source)))
        for key in source:
            invalid = dict(source, **{key: "untrusted"})
            self.assertFalse(self.window.is_official_winget_source(json.dumps(invalid)))
        for invalid in ("[]", "null", "broken", "[" * 2000):
            self.assertFalse(self.window.is_official_winget_source(invalid))

    def test_all_catalog_commands_are_exact_non_shell_no_reboot(self):
        for app in appmod.APP_CATALOG:
            args = self.window.build_winget_arguments(app)
            self.assertEqual(args[:3], ["install", "--id", app.package_id])
            self.assertIn("--exact", args)
            self.assertEqual(args[args.index("--source") + 1], "winget")
            self.assertNotIn("--allow-reboot", args)
            self.assertNotIn("--ignore-security-hash", args)

    def test_profiles_reject_wrong_shapes_and_unknown_ids_never_selected(self):
        for invalid in (None, [], {"schema": True},
            dict(schema=1, kind=appmod.PROFILE_KIND, packages=[{}]),
            dict(schema=1, kind=appmod.PROFILE_KIND, packages="Google.Chrome")):
            with self.assertRaises(ValueError):
                appmod.validated_profile_packages(invalid)
        self.window.set_selected_ids(["Google.Chrome", "unknown; shell", "Google.Chrome"])
        self.assertEqual(self.window.selected_ids, {"Google.Chrome"})

    def test_profile_load_size_encoding_and_depth_bounds_preserve_selection(self):
        self.window.set_selected_ids(["Google.Chrome"])
        with tempfile.TemporaryDirectory(prefix="mass-audit-") as temporary:
            path = Path(temporary) / "profile.json"
            for content in (b"x" * (128 * 1024 + 1), b"\xff", b"[" * 2000,
                            b'{"schema":true,"kind":"bad","packages":[]}'):
                path.write_bytes(content)
                with patch.object(appmod.QFileDialog, "getOpenFileName", return_value=(str(path), "")):
                    self.window.load_profile()
                self.assertEqual(self.window.selected_ids, {"Google.Chrome"})
            self.assertEqual(len(self.warnings), 4)

    def test_atomic_profile_save_failure_keeps_original_and_cleans_temp(self):
        self.window.set_selected_ids(["Google.Chrome"])
        with tempfile.TemporaryDirectory(prefix="mass-audit-") as temporary:
            path = Path(temporary) / "selection.fleecepack"
            path.write_text("original", encoding="utf-8")
            with patch.object(appmod.QFileDialog, "getSaveFileName", return_value=(str(path), "")), \
                 patch.object(appmod.os, "replace", side_effect=OSError("injected replace failure")):
                self.window.save_profile()
            self.assertEqual(path.read_text(encoding="utf-8"), "original")
            self.assertEqual(list(Path(temporary).iterdir()), [path])
            self.assertEqual(len(self.warnings), 1)

    def prepare_output(self, data):
        self.window.current_app = appmod.APP_CATALOG[0]
        self.window.process = FakeProcess(data)
        self.window.process_decoder = codecs.getincrementaldecoder("utf-8")(errors="replace")
        return self.window.process

    def test_output_read_yields_after_bounded_chunk(self):
        process = self.prepare_output(b"publisher output\n" * 120000)
        self.window.read_install_output()
        self.assertLessEqual(max(process.read_sizes), 64 * 1024)
        self.assertGreater(len(process.data), 0)
        self.window.process = None  # queued continuation must not consume a later job
        application.processEvents()

    def test_finished_process_drains_chunks_before_classification(self):
        process = self.prepare_output(b"normal\n" * 20000 + "A restart is required.\né".encode("utf-8"))
        results = []
        self.window.complete_current = lambda state, label: results.append((state, label))
        self.window.install_process_finished(0, real_process.NormalExit)
        for _ in range(100):
            if results:
                break
            application.processEvents()
        self.assertEqual(results, [("installed", "Installed · restart may be needed")])
        self.assertFalse(process.data)
        self.assertLessEqual(max(process.read_sizes), 64 * 1024)
        self.assertEqual(self.window.current_output_lines[-1], "é")

    def test_output_drain_services_queued_qt_event(self):
        process = self.prepare_output(b"output\n" * 30000)
        events = []
        results = []
        self.window.complete_current = lambda *args: results.append(args)
        appmod.QTimer.singleShot(0, lambda: events.append(len(process.data)))
        started = time.perf_counter()
        self.window.install_process_finished(0, real_process.NormalExit)
        for _ in range(100):
            application.processEvents()
            if results:
                break
        elapsed = time.perf_counter() - started
        measurements["output_210kb_drain_seconds"] = elapsed
        self.assertTrue(events)
        self.assertGreater(events[0], 0, "A queued UI event must run before all stdout is drained")
        self.assertTrue(results)
        self.assertLess(elapsed, 3.0)

    def test_utf8_split_and_tail_bounds(self):
        process = self.prepare_output(b"\xc3")
        self.window.read_install_output()
        process.data = b"\xa9\n"
        self.window.read_install_output()
        self.assertEqual(self.window.current_output_lines, ["é"])
        self.window.consume_install_text("x" * 20000 + ":critical\n", False)
        self.assertLessEqual(len(self.window.current_output_lines[-1]), appmod.MAX_INSTALL_OUTPUT_LINE_CHARS)
        self.assertTrue(self.window.current_output_lines[-1].endswith(":critical"))
        self.window.consume_install_text("\n".join(str(i) for i in range(1000)) + "\n", False)
        self.assertEqual(len(self.window.current_output_lines), 300)
        self.assertLessEqual(self.window.install_log.document().blockCount(), appmod.MAX_INSTALL_LOG_BLOCKS)

    def test_failed_start_and_crash_classification(self):
        process = self.prepare_output(b"")
        self.window.install_active = True
        self.window.total_jobs = 1
        self.window.install_process_error(real_process.FailedToStart)
        package = appmod.APP_CATALOG[0].package_id
        self.assertEqual(self.window.results[package], ("failed", "WinGet could not start"))
        self.assertTrue(process.deleted)
        self.assertIsNone(self.window.process)
        self.assertEqual(self.window.completed_jobs, 1)
        self.assertEqual(self.window.classify_install_result(0, "No restart required."), ("installed", "Installed"))
        self.assertEqual(self.window.classify_install_result(0, "", True), ("failed", "Emergency stop requested"))

    def test_stop_between_jobs_cancels_queue_without_process_launch(self):
        self.window.install_active = True
        self.window.total_jobs = 2
        self.window.install_queue = deque(appmod.APP_CATALOG[:2])
        self.window.request_stop_after_current()
        self.assertFalse(self.window.install_active)
        self.assertEqual(self.window.completed_jobs, 2)
        self.assertTrue(all(state == "cancelled" for state, _ in self.window.results.values()))
        self.assertIsNone(self.window.process)

    def test_preflight_timeout_kills_only_injected_process(self):
        process = FakeProcess()
        self.window.preflight_process = process
        self.window.preflight_stage = "version"
        self.window.preflight_timed_out()
        self.assertTrue(process.killed and process.deleted)
        self.assertIsNone(self.window.preflight_process)
        self.assertFalse(self.window.winget_ready)

    def test_disk_log_utf8_byte_cap_and_retention(self):
        with tempfile.TemporaryDirectory(prefix="mass-audit-") as temporary:
            directory = Path(temporary)
            path = directory / "install-current.log"
            path.write_bytes(b"")
            self.window.session_log_path = path
            with patch.object(appmod, "MAX_SESSION_LOG_BYTES", 256):
                self.window.append_install_log("é" * 1000)
                self.window.append_install_log("omitted")
            self.assertLessEqual(path.stat().st_size, 256)
            self.assertIn("session log reached", path.read_text(encoding="utf-8"))
            for index in range(5):
                (directory / f"install-{index}.log").write_bytes(b"x")
            unrelated = directory / "not-managed.txt"
            unrelated.write_bytes(b"keep")
            appmod.prune_managed_logs(directory, max_files=2, protected=(path,))
            self.assertLessEqual(len(list(directory.glob("*.log"))), 3)
            self.assertEqual(unrelated.read_bytes(), b"keep")

    def test_catalog_and_output_workload_budgets(self):
        self.assertLess(measurements["offscreen_window_startup_seconds"], 5.0)
        started = time.perf_counter()
        for index in range(100):
            self.window.search_input.setText(["chrome", "no-match", "", "video"][index % 4])
        measurements["catalog_100_filters_seconds"] = time.perf_counter() - started
        self.assertLess(measurements["catalog_100_filters_seconds"], 5.0)
        payload = b"publisher output line\n" * 3000
        self.prepare_output(payload)
        tracemalloc.start()
        started = time.perf_counter()
        self.window.read_install_output()
        elapsed = time.perf_counter() - started
        _, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        measurements.update(output_first_slice_seconds=elapsed, output_first_slice_peak_python_bytes=peak)
        self.assertLess(elapsed, 1.0)
        self.assertLess(peak, 8 * 1024 * 1024)
        self.window.process = None


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(InstallerSafety))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(dict(tests=result.testsRun, failures=len(result.failures),
            errors=len(result.errors), measurements=measurements), indent=2) + "\n", encoding="utf-8")
    raise SystemExit(not result.wasSuccessful())
