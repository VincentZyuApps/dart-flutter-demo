import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "svg" / "languages.py"
SPEC = importlib.util.spec_from_file_location("svg_languages", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class LanguageDetectionTests(unittest.TestCase):
    def test_detects_repository_and_workflow_languages(self) -> None:
        cases = {
            ".github/workflows/release-publish.yml": "YAML",
            "README.md": "Markdown",
            "packages/plugin/assets/windows/SystemInfo.ps1": "PowerShell",
            "scripts/ci/packaging/linux/wrapper.sh": "Shell",
            "windows/packaging/exe/inno_setup.iss": "Inno Setup",
            "windows/runner/runner.exe.manifest": "XML",
            "ios/Runner/Info.plist": "XML",
            "macos/Runner/Configs/Release.xcconfig": "Xcode Config",
            "android/app/build.gradle.kts": "Kotlin",
            "packages/plugin/macos/plugin.podspec": "Ruby",
            "pubspec.lock": "YAML",
        }
        for filename, expected in cases.items():
            with self.subTest(filename=filename):
                self.assertEqual(MODULE.detect_language(Path(filename)), expected)

    def test_github_is_not_mistaken_for_git_metadata(self) -> None:
        self.assertFalse(MODULE.is_ignored(".github/workflows/release-publish.yml"))

    def test_generated_assets_are_ignored_by_prefix(self) -> None:
        for filename in (
            "assets/icons/windows/app_icon.ico",
            "doc/images/preview/page0.windows11.png",
            "doc/images/svg/lang-line-stats.svg",
        ):
            with self.subTest(filename=filename):
                self.assertTrue(MODULE.is_ignored(filename))


if __name__ == "__main__":
    unittest.main()
