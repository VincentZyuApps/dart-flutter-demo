import importlib.util
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "ci" / "release" / "collect-commits.py"
SPEC = importlib.util.spec_from_file_location("collect_commits", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)
collect_commit_log = MODULE.collect_commit_log


def remove_readonly(function, path, _error) -> None:
    os.chmod(path, stat.S_IWRITE)
    function(path)


class CollectCommitsTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary_root = ROOT / "tmp"
        temporary_root.mkdir(exist_ok=True)
        self.repository = Path(
            tempfile.mkdtemp(prefix="test-collect-commits-", dir=temporary_root)
        )
        self.git("init", "-b", "main")
        self.git("config", "user.name", "CI Test")
        self.git("config", "user.email", "ci@example.com")

    def tearDown(self) -> None:
        shutil.rmtree(self.repository, onexc=remove_readonly)

    def git(self, *arguments: str) -> str:
        return subprocess.run(
            ["git", *arguments],
            cwd=self.repository,
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        ).stdout.strip()

    def commit(self, message: str) -> str:
        tracked = self.repository / "tracked.txt"
        tracked.write_text(message, encoding="utf-8")
        self.git("add", "tracked.txt")
        self.git("commit", "-m", message)
        return self.git("rev-parse", "HEAD")

    def test_collects_only_commits_after_previous_application_release(self) -> None:
        self.commit("initial")
        self.git("tag", "v1.0.0")
        self.commit("feature one")
        head = self.commit("fix two")

        previous_tag, log = collect_commit_log(self.repository, head)

        self.assertEqual(previous_tag, "v1.0.0")
        self.assertNotIn("initial", log)
        self.assertIn("feature one", log)
        self.assertIn("fix two", log)

    def test_ignores_a_current_release_tag_when_rerun(self) -> None:
        self.commit("initial")
        self.git("tag", "v1.0.0")
        self.commit("feature one")
        head = self.commit("fix two")
        self.git("tag", "v2.0.0")

        previous_tag, log = collect_commit_log(self.repository, head)

        self.assertEqual(previous_tag, "v1.0.0")
        self.assertIn("feature one", log)
        self.assertIn("fix two", log)

    def test_without_a_previous_release_reports_initial_release(self) -> None:
        head = self.commit("initial")

        previous_tag, log = collect_commit_log(self.repository, head)

        self.assertIsNone(previous_tag)
        self.assertEqual(log, "- Initial release")


if __name__ == "__main__":
    unittest.main()
