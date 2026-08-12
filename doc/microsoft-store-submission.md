# Microsoft Store 首次提交清单

首次人工提交已经完成，`build-publish` 也已启用自动更新；本文保留为重新上架或审计商店资料时的清单。

## 固定信息

| 字段 | 值 |
|---|---|
| Store ID | `9PP2SRN17C4F` |
| 产品类型 | MSIX 或 PWA 应用 |
| 产品名称 | `dart-flutter-demo` |
| 应用展示名 | `DartFlutterDemo` |
| 发布者 | `VincentZyu` |
| 架构 | x64 |
| 定价 | 免费 |
| 支持 URL | `https://github.com/VincentZyuApps/dart-flutter-demo/issues` |
| 网站 URL | `https://github.com/VincentZyuApps/dart-flutter-demo` |
| 英文隐私政策 URL | `https://github.com/VincentZyuApps/dart-flutter-demo/blob/main/PRIVACY.md` |
| 中文隐私政策 URL | `https://github.com/VincentZyuApps/dart-flutter-demo/blob/main/PRIVACY.zh-cn.md` |

## 上传程序包

1. 从手动 `publish=false` 的 Release & Publish 运行中下载 `release-dry-run-v<version>` Artifact。
2. 解压并选择 `dart-flutter-demo-windows-x64-store-v<version>.msix`。
3. 不要上传同目录中的 EXE、ZIP、JSON 或 Profile 包。
4. 等待 Partner Center 完成包验证，并确认架构为 x64、Package Identity 与产品一致。
5. 检查打包日志输出的 `store_version` 与门户显示值一致；`X.Y.Z-beta.W+YYYYMMDD` 按 `YYYY.MMDD.(20000 + W).0` 映射。

该 MSIX 是未签名的 Store 提交包，不能作为普通侧载安装器。Microsoft 会在商店认证流程中签名。

## 英文商店文案

### Short description

Cross-platform Flutter showcase for system information, typography, responsive layouts, dialogs, and Material controls.

### Description

DartFlutterDemo is a hands-on Flutter UI showcase for exploring cross-platform desktop and mobile behavior.

Features include:

- typed local system information with source and fallback diagnostics;
- modern Flutter and classic Win32-style dialog demonstrations;
- typography, local font, spacing, and color experiments;
- responsive Grid, Masonry, and List layouts backed by public GitHub repository data;
- Material 3 controls, accessibility states, progress flows, and feedback components.

The Windows Store package currently supports x64 devices only. The project is free and open source.

### Search terms

`Flutter`, `Dart`, `UI showcase`, `system information`, `Material 3`, `developer tools`

## 中文商店文案

### 简短说明

用于体验系统信息、字体排版、响应式布局、对话框与 Material 控件的跨平台 Flutter 展示应用。

### 说明

DartFlutterDemo 是一个用于探索 Flutter 跨桌面端和移动端行为的交互式 UI 展示应用。

主要功能包括：

- 显示带数据来源和回退诊断的本地系统信息；
- 演示现代 Flutter 对话框和经典 Win32 风格对话框；
- 实验字体、本地字体文件、间距和颜色；
- 使用公开 GitHub 仓库数据展示响应式 Grid、Masonry 与 List 布局；
- 展示 Material 3 控件、无障碍状态、进度流程与反馈组件。

Windows 商店包目前只支持 x64 设备。本项目永久免费并开放源代码。

### 搜索词

`Flutter`, `Dart`, `UI 展示`, `系统信息`, `Material 3`, `开发者工具`

## `runFullTrust` 受限能力说明

可以在认证备注中使用下面的英文说明：

> This MSIX packages a Flutter Win32 desktop application and requires `runFullTrust` to launch its desktop executable. The app reads local system information for an on-device diagnostics showcase. It does not install a service or driver, change system settings, or automatically upload device information. Optional network access is limited to public GitHub data, avatar images, Google Fonts, and user-opened external links.

## 认证人员测试说明

可以在认证备注中继续添加：

> Launch DartFlutterDemo normally. The initial System Info page displays local diagnostics. Use the left navigation to open Dialog Lab, Typography Studio, Adaptive Grid, and Controls & Feedback. Adaptive Grid can request public GitHub repository data; no account or test credentials are required. Exporting a system information log requires an explicit confirmation and saves the file locally.

## 截图与门户选项

- 优先重新截取干净的 Windows 11 应用截图，不要包含调试窗口、私人主机名、局域网 IP、代理地址或其他敏感信息。
- 至少准备系统信息、对话框、字体排版、自适应网格和控件页面的桌面截图。
- 按 Partner Center 当前页面显示的尺寸、宽高比、数量和文件大小要求导出截图，不依赖旧版文档中的固定规格。
- 年龄分级、市场范围、发布时机和政策问卷必须由账号所有者根据门户中的实际问题确认。
- 第一次提交建议选择认证通过后尽快发布；如果需要人工控制上线时间，则在提交选项中选择手动发布时间。

## 提交后

保存 Submission ID 和认证报告链接。产品显示为 Live 后，再实现并启用 `build-publish` 自动更新工作流。
