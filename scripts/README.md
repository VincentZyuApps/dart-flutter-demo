# 脚本目录

脚本文件名统一使用连字符命名法，并按职责和执行场景分层管理。

```text
scripts/
  assets/                 手动生成和应用多平台图标
  ci/
    common/               工作流公共辅助逻辑和触发词匹配
    packaging/            平台专用发行包打包逻辑
    performance/          性能报告生成和汇总
    platform/bootstrap/   手动重新生成 Flutter 平台源码
    release/              应用发行说明和提交范围处理
    validation/           安全解析 YAML 并检查重复键
  download/               手动下载 GitHub Release
  svg/                    手动生成仓库统计 SVG
```

## 目录约定

- `scripts/ci/` 只保存由 GitHub Actions 调用或用于验证 CI 行为的脚本。
- `scripts/ci/packaging/windows/` 同时保存 Inno Setup 渲染器与 Windows x64 Store MSIX 打包校验器。
- `scripts/ci/validation/` 保存安全 YAML 解析和重复键校验工具。
- `scripts/assets/` 保存手动生成和应用多平台图标的工具。
- `scripts/download/` 保存手动下载 GitHub Release 的工具。
- `scripts/svg/` 保存手动生成仓库统计 SVG 的工具。
- Android 模板在这里使用连字符文件名，Bootstrap 复制到 Android 工程时恢复为符合资源规范的下划线文件名。

## YAML 校验

推荐在仓库根目录通过 `uv` 直接运行校验器，PEP 723 会自动提供固定版本的 PyYAML 隔离依赖。

```bash
uv run scripts/ci/validation/check-yaml.py
```

如需显式维护仓库级 `.venv`，可以先创建虚拟环境并安装依赖，再通过该环境中的 Python 运行校验器。

```bash
uv venv
uv pip install PyYAML==6.0.2
uv run python scripts/ci/validation/check-yaml.py
```

不传路径时会校验所有受 Git 跟踪的 `.yml` 和 `.yaml` 文件，也可以传入相对路径、绝对路径或目录。

```bash
uv run scripts/ci/validation/check-yaml.py pubspec.yaml
uv run scripts/ci/validation/check-yaml.py .github/workflows
uv run scripts/ci/validation/check-yaml.py /absolute/path/to/config.yaml
```

终端颜色默认为自动检测，也可以通过 `--color always` 或 `--color never` 明确控制。
