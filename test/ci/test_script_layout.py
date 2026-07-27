import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "scripts"
WORKFLOWS = ROOT / ".github" / "workflows"


class ScriptLayoutTests(unittest.TestCase):
    def test_script_filenames_use_kebab_case_instead_of_underscores(self) -> None:
        offenders = sorted(
            str(path.relative_to(ROOT))
            for path in SCRIPTS.rglob("*")
            if path.is_file()
            and "__pycache__" not in path.parts
            and "_" in path.name
        )

        self.assertEqual(offenders, [])

    def test_workflow_script_references_exist(self) -> None:
        missing = []
        pattern = re.compile(r"scripts/[A-Za-z0-9./_-]+\.(?:py|sh)")
        for workflow in WORKFLOWS.glob("*.yml"):
            for reference in pattern.findall(workflow.read_text(encoding="utf-8")):
                if not (ROOT / reference).is_file():
                    missing.append(f"{workflow.name}: {reference}")

        self.assertEqual(missing, [])


if __name__ == "__main__":
    unittest.main()
