# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "PyYAML==6.0.2",
# ]
# ///

from __future__ import annotations

import argparse
import ctypes
import os
import re
import subprocess
import sys
from pathlib import Path

try:
    import yaml
    from yaml.constructor import ConstructorError
except ModuleNotFoundError:
    print(
        "缺少 PyYAML 依赖。\n"
        "推荐在仓库根目录运行：\n"
        "  uv run scripts/ci/validation/check-yaml.py\n"
        "如需使用仓库级虚拟环境，请依次运行：\n"
        "  uv venv\n"
        "  uv pip install PyYAML==6.0.2\n"
        "  uv run python scripts/ci/validation/check-yaml.py",
        file=sys.stderr,
    )
    raise SystemExit(2)


REPO_ROOT = Path(__file__).resolve().parents[3]
YAML_SUFFIXES = {".yaml", ".yml"}


class TerminalStyle:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    CYAN = "\033[36m"

    def __init__(self, enabled: bool) -> None:
        self.enabled = enabled

    def paint(self, text: str, *codes: str) -> str:
        if not self.enabled:
            return text
        return f"{''.join(codes)}{text}{self.RESET}"


class UniqueKeySafeLoader(yaml.SafeLoader):
    pass


# PyYAML defaults to YAML 1.1, where words such as "on" become booleans.
# GitHub Actions uses YAML 1.2-style true/false values, so narrow the resolver.
UniqueKeySafeLoader.yaml_implicit_resolvers = {
    key: [
        resolver
        for resolver in resolvers
        if resolver[0] != "tag:yaml.org,2002:bool"
    ]
    for key, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
}
UniqueKeySafeLoader.add_implicit_resolver(
    "tag:yaml.org,2002:bool",
    re.compile(r"^(?:true|false)$", re.IGNORECASE),
    list("tTfF"),
)


def construct_unique_mapping(
    loader: UniqueKeySafeLoader,
    node: yaml.MappingNode,
    deep: bool = False,
) -> dict[object, object]:
    loader.flatten_mapping(node)
    mapping: dict[object, object] = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        try:
            duplicate = key in mapping
        except TypeError as error:
            raise ConstructorError(
                "while constructing a mapping",
                node.start_mark,
                "found an unhashable mapping key",
                key_node.start_mark,
            ) from error
        if duplicate:
            raise ConstructorError(
                "while constructing a mapping",
                node.start_mark,
                f"found duplicate key {key!r}",
                key_node.start_mark,
            )
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


UniqueKeySafeLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
    construct_unique_mapping,
)


def tracked_yaml_files() -> list[Path]:
    result = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "ls-files", "-z", "--", "*.yml", "*.yaml"],
        check=True,
        capture_output=True,
    )
    relative_paths = [
        item.decode("utf-8") for item in result.stdout.split(b"\0") if item
    ]
    return [REPO_ROOT / relative for relative in relative_paths]


def explicit_yaml_files(inputs: list[str]) -> tuple[list[Path], list[str]]:
    files: list[Path] = []
    errors: list[str] = []
    for raw_path in inputs:
        path = Path(raw_path).expanduser()
        if not path.is_absolute():
            path = Path.cwd() / path
        path = path.resolve()
        if not path.exists():
            errors.append(f"Path not found: {raw_path}")
        elif path.is_dir():
            files.extend(
                candidate
                for candidate in path.rglob("*")
                if candidate.is_file() and candidate.suffix.lower() in YAML_SUFFIXES
            )
        elif path.suffix.lower() not in YAML_SUFFIXES:
            errors.append(f"Not a .yml or .yaml file: {raw_path}")
        else:
            files.append(path)
    return sorted(set(files)), errors


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def validate_file(path: Path) -> str | None:
    try:
        with path.open("r", encoding="utf-8-sig") as stream:
            for _document in yaml.load_all(stream, Loader=UniqueKeySafeLoader):
                pass
    except (OSError, UnicodeError, yaml.YAMLError) as error:
        return str(error)
    return None


def enable_windows_ansi() -> None:
    if os.name != "nt":
        return
    try:
        kernel32 = ctypes.windll.kernel32
        for standard_handle in (-11, -12):
            handle = kernel32.GetStdHandle(standard_handle)
            mode = ctypes.c_ulong()
            if kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
                kernel32.SetConsoleMode(handle, mode.value | 0x0004)
    except (AttributeError, OSError):
        pass


def should_use_color(choice: str) -> bool:
    if choice == "always":
        return True
    if choice == "never" or "NO_COLOR" in os.environ:
        return False
    return sys.stdout.isatty() and os.environ.get("TERM") != "dumb"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Safely parse YAML files and reject duplicate mapping keys."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="YAML files or directories; defaults to every Git-tracked YAML file.",
    )
    parser.add_argument(
        "--color",
        choices=("auto", "always", "never"),
        default="auto",
        help="Color mode for terminal output (default: auto; honors NO_COLOR).",
    )
    args = parser.parse_args()

    enable_windows_ansi()
    style = TerminalStyle(should_use_color(args.color))
    print(
        style.paint(
            "🔎 YAML Validation",
            TerminalStyle.BOLD,
            TerminalStyle.CYAN,
        )
    )

    collection_errors: list[str] = []
    try:
        if args.paths:
            files, collection_errors = explicit_yaml_files(args.paths)
        else:
            files = tracked_yaml_files()
    except (OSError, subprocess.CalledProcessError) as error:
        print(
            style.paint(
                f"❌ Unable to list tracked YAML files: {error}",
                TerminalStyle.BOLD,
                TerminalStyle.RED,
            ),
            file=sys.stderr,
        )
        return 2

    if not files and not collection_errors:
        print(
            style.paint(
                "⚠️ No YAML files found.",
                TerminalStyle.BOLD,
                TerminalStyle.YELLOW,
            ),
            file=sys.stderr,
        )
        return 1

    source = "explicit input" if args.paths else "Git-tracked files"
    print(
        style.paint(
            f"📄 Checking {len(files)} YAML file(s) from {source}...",
            TerminalStyle.BOLD,
        )
    )

    failures = list(collection_errors)
    for path in files:
        error = validate_file(path)
        if error is None:
            print(
                style.paint("✅ PASS", TerminalStyle.BOLD, TerminalStyle.GREEN),
                style.paint(display_path(path), TerminalStyle.DIM),
            )
        else:
            failures.append(f"{display_path(path)}: {error}")

    if failures:
        print(
            "\n"
            + style.paint(
                f"❌ YAML validation failed with {len(failures)} error(s)",
                TerminalStyle.BOLD,
                TerminalStyle.RED,
            ),
            file=sys.stderr,
        )
        for failure in failures:
            print(
                style.paint("  •", TerminalStyle.RED),
                failure,
                file=sys.stderr,
            )
        return 1

    print(
        "\n"
        + style.paint(
            f"🎉 All {len(files)} YAML file(s) passed validation.",
            TerminalStyle.BOLD,
            TerminalStyle.GREEN,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
