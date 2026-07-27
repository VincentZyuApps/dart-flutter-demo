from __future__ import annotations

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--commits", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    base_url = (
        f"https://github.com/{args.repository}/releases/download/v{args.version}"
    )
    template = Path(".github/release_template.md").read_text(encoding="utf-8")
    build_info = f"### Build Info\n- Commit: `{args.sha}`\n- Flutter: `3.41.5`"
    rendered = (
        template.replace("__REPO__", args.repository)
        .replace("__VERSION__", args.version)
        .replace("__BASE_URL__", base_url)
        .replace("__BUILD_INFO__", build_info)
        .replace("__COMMIT_LOG__", args.commits.strip() or "- Manual build")
    )
    args.output.write_text(rendered, encoding="utf-8")


if __name__ == "__main__":
    main()
