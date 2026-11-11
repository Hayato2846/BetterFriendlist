"""Exercise the runner's failure boundaries with real, isolated Lua processes."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


RUNNER = Path(__file__).resolve().parents[1] / "bfl_smoke.py"
LUA = os.environ.get("BFL_LUA", "lua")


class SmokeRunnerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="bfl smoke ", dir=os.environ.get("BFL_TEST_TEMP"))
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name) / "repository with spaces"
        self.tools = self.repo / "tools"
        self.tools.mkdir(parents=True)
        self.report = self.repo / "results.json"
        self.manifest = {
            "schemaVersion": 1,
            "sources": {name: {"revision": "0" * 40, "repository": "unused", "version": "test"}
                        for name in ("live", "forever", "classic")},
            "tests": [],
        }
        self.add_test("BFL-FirstSmoke.lua", 'io.write("first executed\\n")')
        self.add_test("BFL-SecondSmoke.lua", 'io.write("second executed\\n")')

    def add_test(self, filename, source, arguments=None):
        (self.tools / filename).write_text(source, encoding="utf-8")
        self.manifest["tests"].append({"file": filename, "arguments": arguments or ["{repo}"]})

    def run_check(self, *args):
        (self.tools / "BFL-SmokeTests.json").write_text(json.dumps(self.manifest), encoding="utf-8")
        environment = os.environ.copy()
        for key in ("BFL_REFERENCES_ROOT", "GITHUB_STEP_SUMMARY", "BFL_SMOKE_REPORT"):
            environment.pop(key, None)
        return subprocess.run(
            [sys.executable, str(RUNNER), "run", "--repo", str(self.repo), "--lua", LUA,
             "--report", str(self.report), *args],
            cwd=self.temporary.name, capture_output=True, text=True, encoding="utf-8",
            errors="replace", env=environment, timeout=15, check=False,
        )

    def test_uses_repo_cwd_and_preserves_arguments_with_spaces(self):
        (self.repo / "marker with spaces.txt").write_text("fixture", encoding="utf-8")
        (self.tools / "BFL-FirstSmoke.lua").write_text(
            'assert(arg[1]:find("repository with spaces", 1, true)); '
            'assert(io.open("marker with spaces.txt", "rb"))', encoding="utf-8")
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        report = json.loads(self.report.read_text(encoding="utf-8"))
        self.assertEqual([test["status"] for test in report["results"]], ["PASS", "PASS"])

    def test_error_overrides_success_text_and_remaining_tests_still_run(self):
        (self.tools / "BFL-FirstSmoke.lua").write_text(
            'io.write("[OK] misleading success\\n"); error("deliberate failure")', encoding="utf-8")
        result = self.run_check()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        report = json.loads(self.report.read_text(encoding="utf-8"))
        self.assertEqual([test["status"] for test in report["results"]], ["FAIL", "PASS"])
        self.assertIn("deliberate failure", report["results"][0]["output"])
        self.assertIn("second executed", result.stdout)

    def test_timeout_is_failure_and_does_not_stop_remaining_tests(self):
        (self.tools / "BFL-FirstSmoke.lua").write_text('while true do end', encoding="utf-8")
        result = self.run_check("--timeout", "0.25")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        report = json.loads(self.report.read_text(encoding="utf-8"))
        self.assertEqual([test["status"] for test in report["results"]], ["TIMEOUT", "PASS"])

    def test_unregistered_smoke_file_is_rejected(self):
        (self.tools / "BFL-NewSmoke.lua").write_text("error('unregistered')", encoding="utf-8")
        result = self.run_check("--list")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unregistered: ['BFL-NewSmoke.lua']", result.stderr)

    def test_deleted_registered_file_is_rejected(self):
        (self.tools / "BFL-FirstSmoke.lua").unlink()
        result = self.run_check()
        self.assertEqual(result.returncode, 2)
        self.assertIn("missing files: ['BFL-FirstSmoke.lua']", result.stderr)

    def test_duplicate_manifest_entry_is_rejected(self):
        self.manifest["tests"].append(self.manifest["tests"][0])
        result = self.run_check()
        self.assertEqual(result.returncode, 2)
        self.assertIn("Duplicate", result.stderr)

    def test_missing_lua_is_error_but_list_does_not_require_lua(self):
        result = self.run_check("--lua", "bfl-nonexistent-lua-interpreter")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Lua 5.4 not found", result.stderr)
        result = self.run_check("--lua", "bfl-nonexistent-lua-interpreter", "--list")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_portable_exclusions_are_explicit_and_full_missing_sources_fails(self):
        self.manifest["tests"][1]["arguments"].append("{forever}")
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        report = json.loads(self.report.read_text(encoding="utf-8"))
        self.assertEqual(report["excluded"], ["BFL-SecondSmoke.lua"])
        self.assertIn("1 source-dependent tests excluded", result.stdout)
        result = self.run_check("--mode", "Full", "--reference-root", str(self.repo / "missing"))
        self.assertEqual(result.returncode, 2)
        self.assertIn("Missing forever WoW source", result.stderr)

    def test_explicit_source_test_cannot_be_silently_excluded(self):
        self.manifest["tests"][1]["arguments"].append("{forever}")
        result = self.run_check("--test", "BFL-SecondSmoke.lua")
        self.assertEqual(result.returncode, 2)
        self.assertIn("require -Mode Full", result.stderr)

    def test_unknown_selection_is_error(self):
        result = self.run_check("--test", "BFL-TypoSmoke.lua")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Unknown smoke test", result.stderr)


if __name__ == "__main__":
    if not shutil.which(LUA):
        raise SystemExit(f"Lua 5.4 required for runner contract tests: {LUA}")
    unittest.main()
