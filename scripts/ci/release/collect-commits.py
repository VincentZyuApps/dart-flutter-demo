from __future__ import annotations

import argparse
import os
from pathlib import Path
import subprocess
import uuid


def run_git(
    repository: Path,
    *arguments: str,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *arguments],
        cwd=repository,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if check and result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git command failed")
    return result


def find_previous_release_tag(repository: Path, head: str) -> str | None:
    parent = run_git(repository, "rev-parse", f"{head}^", check=False)
    if parent.returncode != 0:
        return None

    described = run_git(
        repository,
        "describe",
        "--tags",
        "--abbrev=0",
        "--match",
        "v[0-9]*",
        parent.stdout.strip(),
        check=False,
    )
    if described.returncode != 0:
        return None
    return described.stdout.strip() or None


def collect_commit_log(repository: Path, head: str) -> tuple[str | None, str]:
    previous_tag = find_previous_release_tag(repository, head)
    if previous_tag is None:
        return None, "- Initial release"

    log = run_git(
        repository,
        "log",
        f"{previous_tag}..{head}",
        "--pretty=format:- %s (%h) - @%an",
        "--reverse",
    ).stdout.strip()
    return previous_tag, log or "- No commits since the previous release"


def append_github_output(path: Path, previous_tag: str | None, log: str) -> None:
    delimiter = f"COMMITS_{uuid.uuid4().hex}"
    with path.open("a", encoding="utf-8", newline="\n") as output:
        output.write(f"previous_tag={previous_tag or ''}\n")
        output.write(f"log<<{delimiter}\n{log}\n{delimiter}\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", type=Path, default=Path("."))
    parser.add_argument("--head", default="HEAD")
    parser.add_argument(
        "--github-output",
        type=Path,
        default=os.environ.get("GITHUB_OUTPUT"),
    )
    args = parser.parse_args()
    if args.github_output is None:
        parser.error("--github-output is required outside GitHub Actions")

    repository = args.repository.resolve()
    previous_tag, log = collect_commit_log(repository, args.head)
    append_github_output(args.github_output, previous_tag, log)
    print(f"Previous application release: {previous_tag or 'none'}")
    print(f"Collected commit entries: {len(log.splitlines())}")


if __name__ == "__main__":
    main()
