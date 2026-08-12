from __future__ import annotations

import subprocess
from pathlib import Path


LANGUAGE_BY_SUFFIX = {
    ".bat": "Batchfile",
    ".bash": "Shell",
    ".c": "C",
    ".cc": "C++",
    ".cfg": "INI",
    ".cmake": "CMake",
    ".cmd": "Batchfile",
    ".cpp": "C++",
    ".cs": "C#",
    ".css": "CSS",
    ".csv": "CSV",
    ".cxx": "C++",
    ".dart": "Dart",
    ".editorconfig": "EditorConfig",
    ".entitlements": "XML",
    ".fish": "Shell",
    ".fs": "F#",
    ".fsx": "F#",
    ".gitignore": "Ignore List",
    ".go": "Go",
    ".gradle": "Groovy",
    ".groovy": "Groovy",
    ".h": "C++",
    ".hpp": "C++",
    ".htm": "HTML",
    ".html": "HTML",
    ".ini": "INI",
    ".iss": "Inno Setup",
    ".java": "Java",
    ".js": "JavaScript",
    ".json": "JSON",
    ".jsonc": "JSON with Comments",
    ".jsx": "JavaScript",
    ".kt": "Kotlin",
    ".kts": "Kotlin",
    ".less": "Less",
    ".lua": "Lua",
    ".m": "Objective-C",
    ".manifest": "XML",
    ".markdown": "Markdown",
    ".md": "Markdown",
    ".mm": "Objective-C++",
    ".pbxproj": "Xcode",
    ".php": "PHP",
    ".plist": "XML",
    ".podspec": "Ruby",
    ".properties": "Java Properties",
    ".ps1": "PowerShell",
    ".psd1": "PowerShell",
    ".psm1": "PowerShell",
    ".py": "Python",
    ".r": "R",
    ".rb": "Ruby",
    ".rc": "C++",
    ".rs": "Rust",
    ".sass": "Sass",
    ".scss": "SCSS",
    ".sh": "Shell",
    ".sql": "SQL",
    ".storyboard": "XML",
    ".svg": "XML",
    ".swift": "Swift",
    ".toml": "TOML",
    ".ts": "TypeScript",
    ".tsx": "TypeScript",
    ".xcodeproj": "Xcode",
    ".xcconfig": "Xcode Config",
    ".xcprivacy": "XML",
    ".xcscheme": "XML",
    ".xcsettings": "XML",
    ".xcworkspacedata": "XML",
    ".xib": "XML",
    ".xml": "XML",
    ".yaml": "YAML",
    ".yml": "YAML",
    ".zsh": "Shell",
}

LANGUAGE_BY_NAME = {
    ".editorconfig": "EditorConfig",
    ".fvmrc": "JSON",
    ".gitattributes": "Git Attributes",
    ".gitignore": "Ignore List",
    ".metadata": "YAML",
    "CMakeLists.txt": "CMake",
    "Dockerfile": "Dockerfile",
    "Gemfile": "Ruby",
    "Makefile": "Makefile",
    "Podfile": "Ruby",
    "pubspec.lock": "YAML",
}

LANG_COLORS = {
    "Batchfile": "#C1F12E",
    "C": "#555555",
    "C#": "#178600",
    "C++": "#F34B7D",
    "CMake": "#DA3434",
    "CSS": "#663399",
    "CSV": "#237346",
    "Dart": "#00B4AB",
    "Dockerfile": "#384D54",
    "EditorConfig": "#FEFEFE",
    "F#": "#B845FC",
    "Git Attributes": "#F44D27",
    "Go": "#00ADD8",
    "Groovy": "#4298B8",
    "HTML": "#E34C26",
    "INI": "#D1DDEB",
    "Ignore List": "#6E7781",
    "Inno Setup": "#264B99",
    "Java": "#B07219",
    "Java Properties": "#2A6277",
    "JavaScript": "#F1E05A",
    "JSON": "#DDB100",
    "JSON with Comments": "#DDB100",
    "Kotlin": "#A97BFF",
    "Less": "#1D365D",
    "Lua": "#000080",
    "Makefile": "#427819",
    "Markdown": "#083FA1",
    "Objective-C": "#438EFF",
    "Objective-C++": "#6866FB",
    "PHP": "#4F5D95",
    "PowerShell": "#2671BE",
    "Python": "#3572A5",
    "R": "#198CE7",
    "Ruby": "#701516",
    "Rust": "#DEA584",
    "Sass": "#A53B70",
    "SCSS": "#C6538C",
    "SQL": "#E38C00",
    "Shell": "#89E051",
    "Swift": "#F05138",
    "TOML": "#9C4221",
    "TypeScript": "#3178C6",
    "Xcode": "#147EFB",
    "Xcode Config": "#147EFB",
    "XML": "#0060AC",
    "YAML": "#CB171E",
}

IGNORE_PREFIXES = (
    "assets/icons/",
    "build/",
    "dist/",
    "doc/images/preview/",
    "doc/images/svg/",
    "tmp/",
)


def is_ignored(path: str) -> bool:
    normalized = path.replace("\\", "/").lstrip("./")
    return any(normalized.startswith(prefix) for prefix in IGNORE_PREFIXES)


def list_source_files(root: Path) -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    )
    return sorted(
        {
            Path(raw)
            for raw in result.stdout.splitlines()
            if raw.strip() and not is_ignored(raw)
        }
    )


def detect_language(path: Path) -> str | None:
    if path.name in LANGUAGE_BY_NAME:
        return LANGUAGE_BY_NAME[path.name]
    return LANGUAGE_BY_SUFFIX.get(path.suffix.lower())
