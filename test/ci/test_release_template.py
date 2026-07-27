import unittest
from pathlib import Path


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

        quoted = content.split("> #### Profile Builds", maxsplit=1)[1]
        quoted = quoted.split("### 📄 Git Information", maxsplit=1)[0]
        for line in quoted.splitlines():
            self.assertTrue(not line or line.startswith(">"), line)

    def test_only_build_release_collects_application_commits(self) -> None:
        references = []
        for workflow in WORKFLOWS.glob("*.yml"):
            if "collect-commits.py" in workflow.read_text(encoding="utf-8"):
                references.append(workflow.name)

        self.assertEqual(references, ["build-release.yml"])


if __name__ == "__main__":
    unittest.main()
