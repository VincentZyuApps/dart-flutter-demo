import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "ci"))

from ci_trigger import contains_token  # noqa: E402


class CiTriggerTest(unittest.TestCase):
    def test_bracketed_token_matches(self) -> None:
        self.assertTrue(contains_token("feat(ci): update\n\n[build-release]", "build-release"))

    def test_plain_hyphenated_token_matches(self) -> None:
        self.assertTrue(contains_token("chore: update build-profile", "build-profile"))

    def test_legacy_space_form_does_not_match(self) -> None:
        self.assertFalse(contains_token("build release", "build-release"))

    def test_larger_word_does_not_match(self) -> None:
        self.assertFalse(contains_token("prebuild-release-test", "build-release"))

    def test_tokens_are_case_sensitive(self) -> None:
        self.assertFalse(contains_token("[BUILD-DEBUG]", "build-debug"))

    def test_release_performance_matches(self) -> None:
        self.assertTrue(
            contains_token(
                "perf(ci): retain the report\n\n[release-performance]",
                "release-performance",
            )
        )

    def test_performance_tokens_do_not_overlap(self) -> None:
        self.assertFalse(
            contains_token("[release-performance]", "run-performance")
        )
        self.assertFalse(
            contains_token("[run-performance]", "release-performance")
        )


if __name__ == "__main__":
    unittest.main()
