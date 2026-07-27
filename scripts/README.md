# Scripts

Script filenames use kebab-case. Directories group tools by ownership and execution context.

```text
scripts/
  assets/                 Manual app-icon generation and application
  ci/
    common/               Shared workflow helpers and trigger matching
    packaging/            Platform-specific release packaging
    performance/          Performance report generation and aggregation
    platform/bootstrap/   Manual Flutter platform-source regeneration
    release/              Application Release Notes and commit ranges
  download/               Manual GitHub Release downloads
  svg/                    Manual repository statistics SVG generation
```

Files under `scripts/ci/` are called by GitHub Actions or test CI behavior. Files in the other directories are manually invoked maintenance tools.

Android template filenames use kebab-case here, but the bootstrap script copies them into generated Android projects with Android-compatible underscore resource names.

## 中文

脚本文件名统一使用 kebab-case，并按归属和执行场景分层。

- `scripts/ci/` 只保存由 GitHub Actions 调用或用于验证 CI 行为的脚本。
- `scripts/assets/` 保存手动生成和应用多平台图标的工具。
- `scripts/download/` 保存手动下载 GitHub Release 的工具。
- `scripts/svg/` 保存手动生成仓库统计 SVG 的工具。
- Android 模板在这里使用连字符文件名，Bootstrap 复制到 Android 工程时恢复为符合资源规范的下划线文件名。
