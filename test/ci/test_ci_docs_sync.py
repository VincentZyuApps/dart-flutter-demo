import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ENGLISH_DOC = ROOT / ".github" / "workflows" / "ci.md"
CHINESE_DOC = ROOT / ".github" / "workflows" / "ci.zh-cn.md"
EMOJI_PATTERN = re.compile("[\U0001F300-\U0001FAFF\u2600-\u27BF]\ufe0f?")


def heading_level(line: str) -> int:
    match = re.match(r"^(#+) ", line)
    return len(match.group(1)) if match else 0


def ordered_list_marker(line: str) -> str:
    match = re.match(r"^(\d+)\. ", line)
    return match.group(1) if match else ""


class CiDocsSyncTest(unittest.TestCase):
    def test_english_and_chinese_docs_have_matching_structure(self) -> None:
        english = ENGLISH_DOC.read_text(encoding="utf-8").splitlines()
        chinese = CHINESE_DOC.read_text(encoding="utf-8").splitlines()
        self.assertEqual(len(english), len(chinese))

        for line_number, (english_line, chinese_line) in enumerate(
            zip(english, chinese, strict=True), start=1
        ):
            context = f"line {line_number}"
            self.assertEqual(
                english_line == "", chinese_line == "", f"blank line: {context}"
            )
            self.assertEqual(
                heading_level(english_line),
                heading_level(chinese_line),
                f"heading: {context}",
            )
            self.assertEqual(
                english_line.startswith("```"),
                chinese_line.startswith("```"),
                f"code fence: {context}",
            )
            self.assertEqual(
                english_line.startswith("- "),
                chinese_line.startswith("- "),
                f"bullet: {context}",
            )
            self.assertEqual(
                ordered_list_marker(english_line),
                ordered_list_marker(chinese_line),
                f"ordered list: {context}",
            )
            self.assertEqual(
                english_line.count("|") if english_line.startswith("|") else 0,
                chinese_line.count("|") if chinese_line.startswith("|") else 0,
                f"table columns: {context}",
            )
            self.assertEqual(
                re.findall(r"`[^`]+`", english_line),
                re.findall(r"`[^`]+`", chinese_line),
                f"inline code: {context}",
            )
            self.assertEqual(
                re.findall(r"\]\(([^)]+)\)", english_line),
                re.findall(r"\]\(([^)]+)\)", chinese_line),
                f"link targets: {context}",
            )
            self.assertEqual(
                EMOJI_PATTERN.findall(english_line),
                EMOJI_PATTERN.findall(chinese_line),
                f"emoji: {context}",
            )


if __name__ == "__main__":
    unittest.main()
