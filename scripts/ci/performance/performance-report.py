from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def percent_change(current: float, previous: float | None) -> float | None:
    if previous is None or previous == 0:
        return None
    return (current - previous) * 100 / previous


def load_baseline(directory: Path, platform: str) -> dict | None:
    candidates = sorted(directory.rglob(f"performance-{platform}-*.json"))
    for candidate in reversed(candidates):
        try:
            baseline = json.loads(candidate.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        if baseline.get("platform") == platform:
            return baseline
    return None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", required=True)
    parser.add_argument("--artifact", type=Path, required=True)
    parser.add_argument("--elapsed-seconds", type=float, required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--baseline-directory", type=Path, required=True)
    parser.add_argument("--output-directory", type=Path, required=True)
    args = parser.parse_args()

    if not args.artifact.exists():
        raise SystemExit(f"Profile artifact does not exist: {args.artifact}")
    files = [path for path in args.artifact.rglob("*") if path.is_file()]
    if not files:
        raise SystemExit(f"Profile artifact contains no files: {args.artifact}")
    total_bytes = sum(path.stat().st_size for path in files)
    largest = sorted(files, key=lambda path: path.stat().st_size, reverse=True)[:10]

    baseline = load_baseline(args.baseline_directory, args.platform)

    previous_seconds = baseline.get("buildElapsedSeconds") if baseline else None
    previous_bytes = baseline.get("artifactBytes") if baseline else None
    report = {
        "schemaVersion": 1,
        "recordedAtUtc": datetime.now(timezone.utc).isoformat(),
        "platform": args.platform,
        "mode": "profile",
        "commit": args.sha,
        "buildElapsedSeconds": args.elapsed_seconds,
        "artifactBytes": total_bytes,
        "fileCount": len(files),
        "largestFiles": [
            {
                "path": str(path.relative_to(args.artifact)).replace("\\", "/"),
                "bytes": path.stat().st_size,
            }
            for path in largest
        ],
        "trend": {
            "baselineCommit": baseline.get("commit") if baseline else None,
            "buildElapsedPercent": percent_change(args.elapsed_seconds, previous_seconds),
            "artifactBytesPercent": percent_change(total_bytes, previous_bytes),
        },
    }

    args.output_directory.mkdir(parents=True, exist_ok=True)
    stem = f"performance-{args.platform}-{args.sha[:7]}"
    (args.output_directory / f"{stem}.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    trend = report["trend"]
    elapsed_trend = "n/a" if trend["buildElapsedPercent"] is None else f"{trend['buildElapsedPercent']:+.2f}%"
    size_trend = "n/a" if trend["artifactBytesPercent"] is None else f"{trend['artifactBytesPercent']:+.2f}%"
    markdown = (
        f"# Performance Report: {args.platform}\n\n"
        f"- Commit: `{args.sha}`\n"
        f"- Mode: `profile`\n"
        f"- Build elapsed: `{args.elapsed_seconds:.0f} s` ({elapsed_trend})\n"
        f"- Artifact size: `{total_bytes} bytes` ({size_trend})\n"
        f"- Files: `{len(files)}`\n"
        f"- Baseline: `{trend['baselineCommit'] or 'unavailable'}`\n\n"
        "Performance changes are reported for investigation and do not fail the workflow.\n"
    )
    (args.output_directory / f"{stem}.md").write_text(markdown, encoding="utf-8")


if __name__ == "__main__":
    main()
