import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "windows" / "runner" / "main.cpp"
WORKFLOW = ROOT / ".github" / "workflows" / "release-publish.yml"


class WindowsCliRunnerTests(unittest.TestCase):
    def test_cli_commands_create_a_console_without_a_parent_console(self) -> None:
        runner = RUNNER.read_text(encoding="utf-8")

        self.assertIn("bool IsConsoleCommand", runner)
        self.assertIn('argument == "--help"', runner)
        self.assertIn('argument == "--version"', runner)
        self.assertIn('argument == "--system-info"', runner)
        self.assertIn("IsConsoleCommand(command_line_arguments)", runner)
        self.assertIn("CreateAndAttachConsole();", runner)

    def test_release_workflow_smokes_the_windows_cli(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("Verify Windows command line", workflow)
        self.assertIn("Windows CLI help smoke check failed.", workflow)
        self.assertIn("Windows CLI version smoke check failed.", workflow)


if __name__ == "__main__":
    unittest.main()
