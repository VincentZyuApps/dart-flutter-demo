import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ENGLISH = ROOT / "README.md"
CHINESE = ROOT / "README.zh-cn.md"
EMOJI_PATTERN = re.compile("[\U0001F300-\U0001FAFF\u2600-\u27BF]\ufe0f?")


def heading_level(line: str) -> int:
    match = re.match(r"^(#+) ", line)
    return len(match.group(1)) if match else 0


class ReadmeSyncTests(unittest.TestCase):
    def test_english_and_chinese_readmes_have_matching_structure(self) -> None:
        english = ENGLISH.read_text(encoding="utf-8").splitlines()
        chinese = CHINESE.read_text(encoding="utf-8").splitlines()
        self.assertEqual(len(english), len(chinese))

        for line_number, (english_line, chinese_line) in enumerate(
            zip(english, chinese, strict=True), start=1
        ):
            context = f"line {line_number}"
            self.assertEqual(english_line == "", chinese_line == "", context)
            self.assertEqual(
                heading_level(english_line), heading_level(chinese_line), context
            )
            self.assertEqual(
                english_line.startswith("```"),
                chinese_line.startswith("```"),
                context,
            )
            self.assertEqual(
                english_line.startswith("- "), chinese_line.startswith("- "), context
            )
            self.assertEqual(
                english_line.count("|") if english_line.startswith("|") else 0,
                chinese_line.count("|") if chinese_line.startswith("|") else 0,
                context,
            )
            self.assertEqual(
                len(re.findall(r"\]\(([^)]+)\)", english_line)),
                len(re.findall(r"\]\(([^)]+)\)", chinese_line)),
                context,
            )
            self.assertEqual(
                EMOJI_PATTERN.findall(english_line),
                EMOJI_PATTERN.findall(chinese_line),
                context,
            )


if __name__ == "__main__":
    unittest.main()
