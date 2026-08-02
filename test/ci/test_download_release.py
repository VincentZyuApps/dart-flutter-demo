import contextlib
import importlib.util
import io
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "download" / "download-release.py"
SPEC = importlib.util.spec_from_file_location("download_release", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class DownloadReleaseSummaryTests(unittest.TestCase):
    def test_summarize_assets_returns_count_and_combined_size(self) -> None:
        assets = [{"size": 1024}, {"size": 2048}, {"name": "unknown-size"}]

        self.assertEqual(MODULE.summarize_assets(assets), (3, 3072))

    def test_print_assets_includes_selected_total(self) -> None:
        release = {
            "tag_name": "v1.2.3",
            "assets": [
                {"name": "first.zip", "size": 1024},
                {"name": "second.zip", "size": 2048},
            ],
        }
        output = io.StringIO()

        with contextlib.redirect_stdout(output):
            summary = MODULE.print_assets(release)

        self.assertEqual(summary, (2, 3072))
        self.assertIn("Selected total: 2 files", output.getvalue())
        self.assertIn("3.0 KB", output.getvalue())


if __name__ == "__main__":
    unittest.main()
