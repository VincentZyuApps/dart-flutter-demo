import base64
import re
import unittest
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / ".github" / "release_template.md"
WORKFLOWS = ROOT / ".github" / "workflows"


class ReleaseTemplateTests(unittest.TestCase):
    def test_profile_builds_and_notes_share_one_blockquote(self) -> None:
        content = TEMPLATE.read_text(encoding="utf-8")

        self.assertNotIn("none yet", content)
        self.assertIn("> #### Profile Builds", content)
        self.assertIn("> #### Installation & Compatibility Notes", content)
        self.assertIn("> - [Windows x64 Profile ZIP]", content)
        self.assertIn("> - [Linux x64 Profile tar.gz]", content)
        self.assertIn("> - [Android Universal Profile APK]", content)
        self.assertIn("dart-flutter-demo-windows-x64-store-v__VERSION__.msix", content)
        self.assertIn("dart-flutter-demo-linux-x64-v__VERSION__.flatpak", content)
        self.assertIn("dart-flutter-demo.flatpakref", content)

        quoted = content.split("> #### Profile Builds", maxsplit=1)[1]
        quoted = quoted.split("### 📄 Git Information", maxsplit=1)[0]
        for line in quoted.splitlines():
            self.assertTrue(not line or line.startswith(">"), line)

    def test_flatpak_is_the_last_linux_download(self) -> None:
        content = TEMPLATE.read_text(encoding="utf-8")
        linux_row = next(
            line for line in content.splitlines() if line.startswith("| **Linux**")
        )
        positions = [
            linux_row.index(suffix)
            for suffix in (".AppImage", ".deb", ".tar.gz", ".flatpak")
        ]
        self.assertEqual(positions, sorted(positions))

    def test_store_msix_badge_uses_classic_four_color_windows_logo(self) -> None:
        content = TEMPLATE.read_text(encoding="utf-8")
        match = re.search(
            r"windows-x64-store-msix.*?"
            r"logo=data:image/svg%2bxml;base64,([^)]+)",
            content,
        )
        self.assertIsNotNone(match)
        assert match is not None
        svg = base64.b64decode(unquote(match.group(1))).decode("utf-8")
        for color in ("#F25022", "#7FBA00", "#00A4EF", "#FFB900"):
            self.assertIn(color, svg)
        self.assertEqual(svg.count("<path "), 4)

    def test_only_build_release_collects_application_commits(self) -> None:
        references = []
        for workflow in WORKFLOWS.glob("*.yml"):
            if "collect-commits.py" in workflow.read_text(encoding="utf-8"):
                references.append(workflow.name)

        self.assertEqual(references, ["release-publish.yml"])


if __name__ == "__main__":
    unittest.main()
