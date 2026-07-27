import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "ci"))

from performance_report import load_baseline, percent_change  # noqa: E402


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
