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
  devices/
    ios/                  在桌面系统诊断 iPhone/iPad 连接
  download/               手动下载 GitHub Release
  svg/                    手动生成仓库统计 SVG
```

## 目录约定

- `scripts/ci/` 只保存由 GitHub Actions 调用或用于验证 CI 行为的脚本。
- `scripts/ci/packaging/linux/` 保存 AppImage 包装器、Flatpak AppStream 元数据渲染器，以及 Release/package-only 共用的 Flatpak 安装与沙箱验证脚本。
- `scripts/ci/packaging/windows/` 同时保存 Inno Setup 渲染器与 Windows x64 Store MSIX 打包校验器。
- `scripts/ci/validation/` 保存安全 YAML 解析和重复键校验工具。
- `scripts/assets/` 保存生成和应用多平台图标的工具，详细约定见 [`assets/README.md`](assets/README.md)。
- `scripts/devices/ios/` 保存运行于桌面系统的 Apple 移动设备诊断工具；文件名应标明工具运行的平台。
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

## Microsoft Store 图像

`assets/icons/` 是统一的生成产物目录，不建议直接手工修改其中的文件。需要调整图标时，应修改源图或 `generate-app-icons.py`，再从仓库根目录运行生成命令。

下面的命令只重建 `assets/icons/windows/MicrosoftStore/`，不会清理其他平台已经生成的图标。

```bash
uv run scripts/assets/generate-app-icons.py --microsoft-store-only
```

脚本使用 `assets/images/logo-icon-favicon.png` 作为源图，保持原始比例并居中放到不透明背景上，不会把方形图标拉伸成竖图。生成结果对应 Partner Center 的上传位置：

| 文件 | Partner Center 用途 | 尺寸 | 大小上限 |
|---|---|---:|---:|
| `store-poster-720x1080.png` | Microsoft Store 徽标 / 招贴画 | 720x1080 | 50 MB |
| `store-poster-1440x2160.png` | Microsoft Store 徽标 / 招贴画 | 1440x2160 | 50 MB |
| `store-box-art-1080x1080.png` | Microsoft Store 徽标 / 1:1 封面图 | 1080x1080 | 50 MB |
| `store-box-art-2160x2160.png` | Microsoft Store 徽标 / 1:1 封面图 | 2160x2160 | 50 MB |
| `store-display-icon-300x300.png` | Microsoft Store 显示图像 / 应用磁贴图标 | 300x300 | 5 MB |
| `store-display-icon-150x150.png` | Microsoft Store 显示图像 | 150x150 | 5 MB |
| `store-display-icon-71x71.png` | Microsoft Store 显示图像 | 71x71 | 5 MB |

Partner Center 把招贴画标记为 9:16，但当前页面列出的实际尺寸是 720x1080 和 1440x2160。脚本以门户要求的精确像素尺寸为准。
