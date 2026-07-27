from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


PLATFORMS = ("windows-x64", "linux-x64", "macos-arm64")


def load_reports(directory: Path, expected_commit: str) -> list[dict[str, Any]]:
    reports: list[dict[str, Any]] = []
    for platform in PLATFORMS:
        candidates = sorted(directory.rglob(f"performance-{platform}-*.json"))
        if len(candidates) != 1:
            raise ValueError(
                f"Expected one JSON report for {platform}, found {len(candidates)}"
            )
        report = json.loads(candidates[0].read_text(encoding="utf-8"))
        if report.get("platform") != platform:
            raise ValueError(f"Report platform mismatch for {platform}")
        if report.get("commit") != expected_commit:
            raise ValueError(f"Report commit mismatch for {platform}")
        for field in ("buildElapsedSeconds", "artifactBytes", "fileCount", "trend"):
            if field not in report:
                raise ValueError(f"Missing {field} in {platform} report")
        reports.append(report)
    return reports


def format_bytes(value: int) -> str:
    return f"{value / (1024 * 1024):.2f} MiB"


def format_change(value: float | None) -> str:
    return "n/a" if value is None else f"{value:+.2f}%"


def render_markdown(summary: dict[str, Any]) -> str:
    lines = [
        "# 📊 Performance Report / 性能报告",
        "",
        f"- 🕐 Recorded / 记录时间: `{summary['recordedAtUtc']}`",
        f"- 🧩 Commit: [`{summary['commit'][:7]}`]({summary['commitUrl']})",
        f"- 🛠️ Flutter: `{summary['flutterVersion']}`",
        "- 🚦 Mode / 模式: `profile`",
        f"- 🎬 Trigger / 触发方式: `{summary['trigger']}`",
        f"- 🔗 Workflow / 工作流: [run {summary['runId']}]({summary['workflowUrl']})",
        "",
        "| 🖥️ Platform / 平台 | ⏱️ Build / 构建耗时 | 📈 Change / 变化 | 📦 Bundle / 产物大小 | 📉 Change / 变化 | 📄 Files / 文件数 | 🧭 Baseline / 基线 |",
        "|---|---:|---:|---:|---:|---:|---|",
    ]
    for report in summary["reports"]:
        trend = report["trend"]
        baseline = trend.get("baselineCommit") or "unavailable"
        if baseline != "unavailable":
            baseline = baseline[:7]
        lines.append(
            "| {platform} | {seconds:.0f} s | {elapsed} | {size} | {size_change} | {files} | `{baseline}` |".format(
                platform=report["platform"],
                seconds=report["buildElapsedSeconds"],
                elapsed=format_change(trend.get("buildElapsedPercent")),
                size=format_bytes(report["artifactBytes"]),
                size_change=format_change(trend.get("artifactBytesPercent")),
                files=report["fileCount"],
                baseline=baseline,
            )
        )
    lines.extend(
        [
            "",
            "> ℹ️ Hosted-runner measurements are intended for trend analysis, not precise device FPS, memory, or startup benchmarks.",
            "> ℹ️ 托管 Runner 数据用于观察趋势，不等同于真机 FPS、内存或启动耗时基准。",
            "",
            "Performance changes are informational and do not fail the workflow. / 普通性能波动只记录，不会导致工作流失败。",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-directory", type=Path, required=True)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--file-stamp", required=True)
    parser.add_argument("--recorded-at-utc", required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--flutter-version", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--run-attempt", required=True)
    parser.add_argument("--trigger", required=True)
    args = parser.parse_args()

    reports = load_reports(args.input_directory, args.sha)
    summary = {
        "schemaVersion": 1,
        "recordedAtUtc": args.recorded_at_utc,
        "commit": args.sha,
        "commitUrl": f"https://github.com/{args.repository}/commit/{args.sha}",
        "flutterVersion": args.flutter_version,
        "mode": "profile",
        "trigger": args.trigger,
        "runId": args.run_id,
        "runAttempt": args.run_attempt,
        "workflowUrl": f"https://github.com/{args.repository}/actions/runs/{args.run_id}",
        "reports": reports,
    }

    args.output_directory.mkdir(parents=True, exist_ok=True)
    stem = f"performance-summary-{args.file_stamp}-{args.sha[:7]}"
    (args.output_directory / f"{stem}.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )
    (args.output_directory / f"{stem}.md").write_text(
        render_markdown(summary), encoding="utf-8"
    )


if __name__ == "__main__":
    main()
