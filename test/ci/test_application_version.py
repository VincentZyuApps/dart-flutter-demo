import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PUBSPEC = ROOT / "pubspec.yaml"
VERSION_SOURCE = ROOT / "lib" / "application_version.dart"


class ApplicationVersionTests(unittest.TestCase):
    def test_cli_version_constant_matches_pubspec(self) -> None:
        pubspec = PUBSPEC.read_text(encoding="utf-8")
        source = VERSION_SOURCE.read_text(encoding="utf-8")
        pubspec_match = re.search(r"^version: (.+)$", pubspec, re.MULTILINE)
        source_match = re.search(
            r"applicationVersion = '([^']+)'", source, re.MULTILINE
        )

        self.assertIsNotNone(pubspec_match)
        self.assertIsNotNone(source_match)
        self.assertEqual(pubspec_match.group(1), source_match.group(1))


if __name__ == "__main__":
    unittest.main()
