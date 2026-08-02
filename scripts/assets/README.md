# 应用图标脚本

本目录保存应用图标的生成与应用工具。`assets/icons/` 中的文件都是生成产物，不建议直接手工修改、替换或补写；否则下一次运行生成器时，这些改动可能被覆盖。

需要修改图标时，应先更新源图 `assets/images/logo-icon-favicon.png` 或生成逻辑 `scripts/assets/generate-app-icons.py`，再从仓库根目录运行生成器。

## 生成全部图标

下面的命令会清理并重建整个 `assets/icons/` 目录，包括 Android、iOS、macOS、Windows、Linux 和 Microsoft Store 图像。

```bash
uv run scripts/assets/generate-app-icons.py
```

## 仅生成 Microsoft Store 图像

只调整 Microsoft Store 图像时，优先使用下面的命令。它只会重建 `assets/icons/windows/MicrosoftStore/`，不会影响其他平台图标。

```bash
uv run scripts/assets/generate-app-icons.py --microsoft-store-only
```

## 应用到平台工程

`apply-app-icons.py` 会把已经生成的图标复制到指定平台工程。参数可使用 `windows-x64`、`macos-x64`、`macos-arm64`、`linux-x64`、`android-multiarch` 或 `ios-arm64`。

```bash
uv run python scripts/assets/apply-app-icons.py windows-x64
```

不要通过平台工程中的副本反向修改 `assets/icons/`。应始终修改源图或生成器，重新生成后再应用到平台工程。
