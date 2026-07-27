import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "ci" / "performance" / "performance-summary.py"
SPEC = importlib.util.spec_from_file_location("performance_summary", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)
load_reports = MODULE.load_reports
render_markdown = MODULE.render_markdown


class PerformanceSummaryTest(unittest.TestCase):
    def make_reports(self, directory: Path, commit: str) -> None:
        for index, platform in enumerate(
            ("windows-x64", "linux-x64", "macos-arm64"), start=1
        ):
            report = {
                "schemaVersion": 1,
                "platform": platform,
                "commit": commit,
                "buildElapsedSeconds": 100 + index,
                "artifactBytes": index * 1024 * 1024,
                "fileCount": 10 + index,
                "trend": {
                    "baselineCommit": "b" * 40,
                    "buildElapsedPercent": 1.25,
                    "artifactBytesPercent": -0.5,
                },
            }
            (directory / f"performance-{platform}-{commit[:7]}.json").write_text(
                json.dumps(report), encoding="utf-8"
            )

    def test_loads_three_reports_and_renders_bilingual_summary(self) -> None:
        commit = "a" * 40
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            self.make_reports(directory, commit)
            reports = load_reports(directory, commit)

        markdown = render_markdown(
            {
                "recordedAtUtc": "2026-07-27T04:00:00Z",
                "commit": commit,
                "commitUrl": f"https://github.com/example/repo/commit/{commit}",
                "flutterVersion": "3.41.5",
                "trigger": "commit:release-performance",
                "runId": "123",
                "workflowUrl": "https://github.com/example/repo/actions/runs/123",
                "reports": reports,
            }
        )

        self.assertEqual(
            [report["platform"] for report in reports],
            ["windows-x64", "linux-x64", "macos-arm64"],
        )
        self.assertIn("Performance Report / 性能报告", markdown)
        self.assertIn("| windows-x64 | 101 s | +1.25% | 1.00 MiB |", markdown)

    def test_missing_platform_report_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            with self.assertRaisesRegex(ValueError, "windows-x64"):
                load_reports(Path(temporary_directory), "a" * 40)


if __name__ == "__main__":
    unittest.main()
