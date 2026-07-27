import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "ci" / "performance" / "performance-report.py"
SPEC = importlib.util.spec_from_file_location("performance_report", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)
load_baseline = MODULE.load_baseline
percent_change = MODULE.percent_change


class PerformanceReportTest(unittest.TestCase):
    def test_percent_change(self) -> None:
        self.assertEqual(percent_change(125, 100), 25)
        self.assertIsNone(percent_change(125, 0))
        self.assertIsNone(percent_change(125, None))

    def test_loads_platform_baseline_from_nested_bundle(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory) / "downloaded-artifact"
            directory.mkdir()
            report = {
                "platform": "linux-x64",
                "commit": "a" * 40,
                "buildElapsedSeconds": 90,
                "artifactBytes": 1024,
            }
            (directory / "performance-linux-x64-aaaaaaa.json").write_text(
                json.dumps(report), encoding="utf-8"
            )

            baseline = load_baseline(Path(temporary_directory), "linux-x64")

        self.assertIsNotNone(baseline)
        self.assertEqual(baseline["commit"], "a" * 40)

    def test_ignores_another_platform(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            (directory / "performance-linux-x64-aaaaaaa.json").write_text(
                json.dumps({"platform": "windows-x64"}), encoding="utf-8"
            )
            self.assertIsNone(load_baseline(directory, "linux-x64"))


if __name__ == "__main__":
    unittest.main()
