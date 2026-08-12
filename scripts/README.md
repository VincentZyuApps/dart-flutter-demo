# 🧰 脚本目录

📐 脚本文件名统一使用连字符命名法，并按职责和执行场景分层管理。

```text
scripts/
  assets/                 🎨 手动生成和应用多平台图标
  ci/
    common/               🧩 工作流公共辅助逻辑和触发词匹配
    packaging/            📦 平台专用发行包打包逻辑
    performance/          📊 性能报告生成和汇总
    platform/bootstrap/   🏗️ 手动重新生成 Flutter 平台源码
    release/              🚀 应用发行说明和提交范围处理
    validation/           ✅ 安全解析 YAML 并检查重复键
  devices/
    ios/                  📱 在桌面系统诊断 iPhone/iPad 连接
  download/               ⬇️ 手动下载 GitHub Release
  svg/                    🖼️ 手动生成仓库统计 SVG
```

## 🗂️ 目录约定

- 🤖 `scripts/ci/` 只保存由 GitHub Actions 调用或用于验证 CI 行为的脚本。
- 🐧 `scripts/ci/packaging/linux/` 保存 AppImage 包装器、Flatpak AppStream 元数据渲染器，以及 Release/package-only 共用的 Flatpak 安装与沙箱验证脚本。
- 🪟 `scripts/ci/packaging/windows/` 同时保存 Inno Setup 渲染器与 Windows x64 Store MSIX 打包校验器。
- ✅ `scripts/ci/validation/` 保存安全 YAML 解析和重复键校验工具，详细用法见 [`ci/validation/README.md`](ci/validation/README.md)。
- 🎨 `scripts/assets/` 保存生成和应用多平台图标的工具，详细约定见 [`assets/README.md`](assets/README.md)。
- 📱 `scripts/devices/ios/` 保存运行于桌面系统的 Apple 移动设备诊断工具；文件名应标明工具运行的平台。
- ⬇️ `scripts/download/` 保存手动下载 GitHub Release 的工具，详细用法见 [`download/README.md`](download/README.md)。
- 🖼️ `scripts/svg/` 保存手动生成仓库统计 SVG 的工具，详细用法见 [`svg/README.md`](svg/README.md)。
- 🤖 Android 模板在这里使用连字符文件名，Bootstrap 复制到 Android 工程时恢复为符合资源规范的下划线文件名。
