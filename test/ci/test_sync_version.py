import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "version" / "sync-version.py"
SPEC = importlib.util.spec_from_file_location("sync_version", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

get_pubspec_version = MODULE.get_pubspec_version
sync_version = MODULE.sync_version


class SyncVersionTests(unittest.TestCase):
    def test_get_pubspec_version(self) -> None:
        version = get_pubspec_version()
        self.assertTrue(len(version) > 0)
        self.assertIn("+", version)

    def test_sync_version_updates_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            pubspec = tmp_path / "pubspec.yaml"
            dart_file = tmp_path / "application_version.dart"

            pubspec.write_text("name: test_app\nversion: 1.2.3+456\n", encoding="utf-8")
            dart_file.write_text(
                "const String applicationVersion = '0.0.1+1';\n",
                encoding="utf-8",
            )

            # Check mismatch before sync
            self.assertFalse(
                sync_version(
                    pubspec_path=pubspec,
                    dart_path=dart_file,
                    check_only=True,
                )
            )

            # Perform sync
            self.assertTrue(
                sync_version(
                    pubspec_path=pubspec,
                    dart_path=dart_file,
                    check_only=False,
                )
            )

            # Check matching after sync
            self.assertTrue(
                sync_version(
                    pubspec_path=pubspec,
                    dart_path=dart_file,
                    check_only=True,
                )
            )
            self.assertIn("1.2.3+456", dart_file.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
