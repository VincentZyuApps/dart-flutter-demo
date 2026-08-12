import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "release-publish.yml"
CHECK_WORKFLOW = ROOT / ".github" / "workflows" / "check-microsoft-store.yml"


class StorePublishWorkflowTests(unittest.TestCase):
    def test_store_check_workflow_is_manual_and_read_only(self) -> None:
        workflow = CHECK_WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("name: Check Microsoft Store Authentication", workflow)
        self.assertIn("workflow_dispatch:", workflow)
        self.assertIn("if: github.ref == 'refs/heads/main'", workflow)
        self.assertIn("environment: microsoft-store-production", workflow)
        self.assertIn("msstore apps list", workflow)
        self.assertNotIn("msstore publish", workflow)

    def test_external_publication_is_a_build_publish_superset(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("publish_external_channels:", workflow)
        self.assertIn("should_publish_external_channels=true", workflow)
        self.assertIn("should_publish_external_channels=false", workflow)
        self.assertIn("External channel publication requires publish=true.", workflow)
        self.assertIn(
            "External channel publication is restricted to main or master.",
            workflow,
        )

    def test_store_job_reuses_and_validates_the_windows_artifact(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("publish-microsoft-store:", workflow)
        self.assertIn("needs: [prepare, release-builds, publish]", workflow)
        self.assertIn("environment: microsoft-store-production", workflow)
        self.assertIn("github.ref == 'refs/heads/main'", workflow)
        self.assertIn("github.ref == 'refs/heads/master'", workflow)
        self.assertIn("name: release-windows-x64", workflow)
        self.assertIn("--metadata \"$($msix.FullName).json\"", workflow)
        self.assertIn("Required repository variable is missing: $name", workflow)
        self.assertIn("Required Microsoft Store setting is missing: $name", workflow)
        self.assertIn('msstore publish "$env:MSIX_PATH"', workflow)
        self.assertIn("--appId \"$env:MS_STORE_PRODUCT_ID\"", workflow)
        self.assertNotIn("--inputFile", workflow)
        self.assertNotIn("--noCommit", workflow)

    def test_store_cli_and_action_are_pinned(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn(
            "microsoft/microsoft-store-apppublisher@"
            "cc9910a8d59f2eb55cbb83df0a3800cf3b5300e0",
            workflow,
        )
        self.assertIn("version: v0.3.9", workflow)
        self.assertIn("msstore apps list", workflow)
        self.assertIn('msstore publish "$env:MSIX_PATH"', workflow)


if __name__ == "__main__":
    unittest.main()
