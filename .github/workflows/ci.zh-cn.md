> **[📖 English](ci.md)** | **[📖 简体中文](ci.zh-cn.md)**

# ⚙️ GitHub Actions 工作流

本仓库在 GitHub Actions 中使用 Flutter 3.41.5。正常 CI 直接使用已提交的 `android/`、`ios/`、`windows/`、`linux/` 和 `macos/` 工程，不运行 `flutter create`，也不 patch 临时生成的 Runner。

## 📝 Commit 约定

第一行使用 Conventional Commits 摘要，并将 CI 关键词放在 commit message 末尾：

```text
feat(system-info): migrate collection into a reusable plugin

[build-profile]
[run-performance]
```

关键词精确匹配、区分大小写且必须带连字符。方括号只是书写风格，不参与匹配。

| 🔑 关键词 | ⚙️ 工作流 | 📦 输出 | ⏳ 保留时间 | 🚀 创建 Release |
|---|---|---|---|:---:|
| `build-release` | `build-release.yml` | 六个 Release 目标加三个 Profile 目标 | 发布后永久保留 | 是 |
| `build-profile` | `profile-debug.yml` | Windows x64、Linux x64、Android Universal Profile | 7 天 | 否 |
| `build-debug` | `profile-debug.yml` | Windows x64、Linux x64、Android Universal Debug | 7 天 | 否 |
| `run-performance` | `performance.yml` | Windows、Linux、macOS 的 JSON/Markdown/日志报告包 | 7 天 | 否 |
| `release-performance` | `performance.yml` | 相同的完整性能报告包 | 永久 Performance Pre-release | 是 |

旧形式 `build release`、`build action` 或 `BUILD-RELEASE` 都不会匹配。同一条 commit 可以放多个有效关键词，从而启动多个工作流。

## 🚀 Release 构建

`build-release.yml` 在 push 包含 `build-release` 时运行，也可以从 `workflow_dispatch` 手动运行。

流水线先运行 `flutter analyze`、根项目测试、本地插件测试和 CI 触发词测试，然后构建：

| 🎯 目标 | 🖥️ Runner | 📦 Release 输出 |
|---|---|---|
| Windows x64 | `windows-latest` | 便携 ZIP 和 Inno Setup EXE |
| Linux x64 | `ubuntu-22.04` | tar.gz、DEB 和 AppImage |
| macOS x64 | `macos-15-intel` | DMG 和 ZIP |
| macOS ARM64 | `macos-latest` | DMG 和 ZIP |
| Android | `ubuntu-latest` | Universal、ARM64 和 x86_64 APK |
| iOS ARM64 | `macos-latest` | 未签名 IPA |

同一次运行还会构建永久附加到 Release 的 Windows x64、Linux x64 和 Android Universal Profile 包，文件名含 `-profile-`。

### 🧪 手动 Dry-Run

手动运行默认 `publish=false`。它会执行质量检查、全部 Release 构建、三项永久 Profile 构建、打包和 Release Notes 渲染，但只上传保留七天的 `release-dry-run-*` Artifact，不创建 tag 或 GitHub Release。

确认 dry-run 全部通过后再使用 `publish=true`。push 中的 `build-release` 会在所有必要 job 成功后自动发布。

## 🧰 Profile 与 Debug 构建

`profile-debug.yml` 接受 `build-profile` 和 `build-debug`。同一条消息包含两个关键词时会生成两套产物。手动运行可选 `profile`、`debug` 或 `both`。

产物示例：

```text
dart-flutter-demo-windows-x64-profile-93ac817
dart-flutter-demo-linux-x64-debug-93ac817
dart-flutter-demo-android-universal-profile-93ac817
```

这些是临时 Actions Artifact，不是 GitHub Release 附件。

## 📊 性能报告

`performance.yml` 支持用 `run-performance` 生成保留七天的 Artifact，并用 `release-performance` 创建永久 Performance Pre-release。手动运行可选 `artifact-7-days` 或 `github-release`，默认使用临时选项。

每周一 UTC 03:00 的计划触发仍然保留，但初始由 `ENABLE_SCHEDULED_PERFORMANCE: 'false'` 关闭。改成 `'true'` 即可启用计划；`SCHEDULED_PERFORMANCE_DESTINATION` 独立选择 `artifact` 或 `release`，并默认使用 `artifact`。

实际启动后，它会在 Windows x64、Linux x64 和 macOS ARM64 上构建 Profile bundle，记录构建耗时、产物大小、文件数、最大文件，以及相对上一次成功报告的变化。三个保留一天的中转 Artifact 最终会合并成一份保留七天的完整报告包。

每份最终报告包包含：

- 📝 双语汇总 Markdown 和 JSON；
- 🖥️ 三个平台各自的 Markdown 和 JSON，共六个文件；
- 🧾 一份合并日志，覆盖已完成的准备 job 和三个平台 job。

基线优先使用最近且尚未过期的七天 Performance Artifact，找不到时回退到最新的永久 Performance Pre-release。因此，只要存在永久报告，临时报告过期就不会中断长期比较。

永久报告使用唯一的 `performance-<UTC>-<sha>-run<id>-attempt<n>` Tag，并明确标记为 Pre-release，因此不会替代应用的 Latest Release。同一组九个文件会作为附件上传，双语汇总也会直接渲染为 Release 正文。

普通性能波动只记录；只有构建失败、三平台结果不完整、日志缺失或 JSON 无效等结构性错误才会让工作流失败。托管 Runner 数据适合观察趋势，不等同于真机 FPS、内存或启动耗时基准。

## 🏗️ 平台 Bootstrap

`platform-bootstrap.yml` 没有 commit 关键词，只能手动运行。它会在 GitHub 托管的临时目录中生成五个平台工程，并应用：

- 应用 ID `io.github.vincentzyuapps.dartflutterdemo`；
- 展示名 `DartFlutterDemo`；
- 已提交的应用图标；
- App 专属 Android 桌面 Widget。

它上传保留七天的 `dart-flutter-demo-platform-roots-flutter-3.41.5`，其中包含五个平台目录、Flutter `.metadata` 和根依赖 `pubspec.lock`，且绝不自动 commit。下载并审查 Artifact 后，再用它替换仓库的平台目录。此工作流用于首次迁移，以及将来明确决定升级 Flutter 平台模板时的人工重建。

## 📦 最终 Release 文件名

| 🧩 类型 | 📝 模式 |
|---|---|
| Windows | `dart-flutter-demo-windows-x64-v<version>.zip` / `-setup.exe` |
| Linux | `dart-flutter-demo-linux-x64-v<version>.tar.gz` / `.deb` / `.AppImage` |
| macOS | `dart-flutter-demo-macos-<arch>-v<version>.dmg` / `.zip` |
| Android | `dart-flutter-demo-android-<abi>-v<version>.apk` |
| iOS | `dart-flutter-demo-ios-arm64-v<version>.ipa` |
| Profile | `dart-flutter-demo-<platform>-profile-v<version>.<extension>` |
| Performance | `performance-summary-<UTC>-<sha>.md` / `.json`、各平台 `.md` / `.json`，以及 `performance-workflow-<UTC>-<sha>.log` |

GitHub tag 和文件名使用 `pubspec.yaml` 版本中 `+` 之前的部分。例如 `0.4.2-beta.8+20260727` 会生成 tag `v0.4.2-beta.8`。

## 🔐 权限与签名

只有应用的 `publish` job 和性能报告的 `publish-report` job 获得 `contents: write`，其余 job 都是只读权限。发布使用默认 `GITHUB_TOKEN`。仓库不保存 Team ID、证书、Provisioning Profile、keystore 或其他签名 Secret。

Android 产物使用 CI 临时签名；iOS IPA 与 macOS 包均未签名。AltStore 侧载前自行签名 IPA；进入 TestFlight 或 App Store 前，应在独立的私有发布流程中配置签名。

## 🏪 Microsoft Store 初始化与 `build-publish`

> **🚧 当前状态：** `build-publish` 是预留关键词，尚未启用。在 Partner Center 首次提交正式上线、MSIX 身份值完成审查、商店发布 job 实现并验证之前，不要使用该关键词。

规划中的 `build-publish` 会扩展 `build-release`：先执行完全相同的质量检查、Release 构建、永久 Profile 构建和 GitHub Release 发布，再生成 Windows x64 MSIX，并在 `microsoft-store-production` GitHub Environment 等待人工批准，之后才提交 Microsoft Store。工作流成功只表示提交已经送达 Partner Center，微软认证仍会在此后继续运行。

本项目保持永久免费。`0.5.0-beta.9` 等预发布版本也会直接提交正式商店页面，不使用 Package Flight，因此批准 Environment 部署前必须仔细检查版本和 Release Notes。

现有 Windows x64 便携 ZIP 与 Inno Setup EXE 继续作为 GitHub Release 附件。本项目不规划 MSI：MSI 会重复 EXE 已覆盖的传统安装器职责，增加一套打包流水线，并且仍然需要 Authenticode 签名。MSIX 才是商店发布格式；微软会在认证通过后重新签名，因此只通过商店分发时不需要购买 CA 代码签名证书。

### 🧾 首次在 Partner Center 人工上架

微软目前只支持通过 GitHub Actions 自动更新已经发布并处于 Live 状态的免费产品。启用 `build-publish` 前依次完成：

1. 在 [Partner Center](https://storedeveloper.microsoft.com/) 注册 Windows 开发者账号，并完成要求的身份验证。
2. 保留应用名称，并在 Partner Center 创建产品。
3. 将现有 Microsoft Entra 租户关联到 Partner Center，或从 Partner Center 创建租户。
4. 为 CI 注册 Microsoft Entra 应用，在 Partner Center 的账号用户管理中添加该应用，并授予 **Manager** 角色。
5. 打开产品身份页面，准确记录 Product ID、Package/Identity/Name、Publisher、Publisher 展示名和应用展示名。不得根据 Dart 包名猜测这些值。
6. 仓库实现 MSIX 打包 job 后，手动运行仅打包的 dry-run，并下载 Windows x64 `.msix` Artifact。
7. 在 Partner Center 人工创建第一次提交，上传该 MSIX，填写商店介绍、隐私、年龄分级、可用地区和政策信息，然后提交认证。
8. 等待产品完成发布并显示为 **Live**，之后再配置自动更新。

商店包版本独立于 `pubspec.yaml` SemVer。它必须是四段纯数字，第一段不能为零，每段不超过 65535，第四段必须为零。未来工作流会单独生成并验证商店版本，不会直接传入 `0.5.0-beta.9`。

### 🔒 GitHub Environment

打开 GitHub 仓库的 **Settings -> Environments -> New environment**，创建 `microsoft-store-production`，并配置：

- 设置 required reviewers，确保只有 commit 关键词不能直接对外发布；
- 将部署分支限制为 `main` 和 `master`；
- 仓库套餐支持时启用禁止自审；
- 添加下面列出的 Environment Secrets 与 Variables。

优先使用 Environment Secrets，不使用仓库全局 Secrets，这样只有人工批准后发布 job 才能得到凭据：

| 🔐 Environment Secret | 📍 获取位置 | 🎯 用途 |
|---|---|---|
| `PARTNER_CENTER_TENANT_ID` | Microsoft Entra 租户概览 | 选择与 Partner Center 关联的租户 |
| `PARTNER_CENTER_SELLER_ID` | Partner Center 账号设置 / 标识符 | 选择商店卖家账号 |
| `PARTNER_CENTER_CLIENT_ID` | Microsoft Entra 应用注册 | 标识 CI 应用 |
| `PARTNER_CENTER_CLIENT_SECRET` | Microsoft Entra 应用注册的 Secret Value | 验证 CI 应用身份 |

使用产品身份页面中的准确值添加以下非敏感 Environment Variables：

| 🔧 Environment Variable | 📍 获取位置 | 🎯 用途 |
|---|---|---|
| `MS_STORE_PRODUCT_ID` | Partner Center 产品概览 | 选择目标应用提交 |
| `MS_STORE_IDENTITY_NAME` | Package Identity 详情 | 写入 `Package/Identity/Name` |
| `MS_STORE_PUBLISHER` | Package Identity 详情 | 写入 Manifest Publisher，通常是 `CN=...` 值 |
| `MS_STORE_PUBLISHER_DISPLAY_NAME` | Partner Center 身份详情 | 写入用户可见的发布者名称 |
| `MS_STORE_DISPLAY_NAME` | Partner Center 产品身份 | 写入用户可见的应用名称，预期为 `DartFlutterDemo` |

`GITHUB_TOKEN` 由 GitHub 自动提供，不需要手动创建。只向商店提交的 MSIX 不需要 PFX Secret，因为微软会在认证后为包签名。绝不能把 Client Secret、租户凭据、证书或它们的编码形式写入源码、日志、Artifact 或 Release Notes。

### 🚀 自动发布

完成账号初始化并启用工作流后，使用：

```text
release: publish DartFlutterDemo

[build-publish]
```

工作流会构建全部常规 Release/Profile 产物、创建 GitHub Release、构建 Windows x64 商店 MSIX、等待 `microsoft-store-production` 人工批准、配置微软官方 Microsoft Store Developer CLI，并将 MSIX 提交到正式商店页面。发现版本、更新日志、商店身份或生成包不符合预期时，应拒绝该部署。

在 `PARTNER_CENTER_CLIENT_SECRET` 到期前轮换它，并且只更新 Environment Secret 的值。如果后续认证失败，应前往 Partner Center 检查；不能把之前 GitHub job 的成功当作更新已经上线的证明。

### 📚 官方参考资料

- [使用 GitHub Actions 发布应用更新](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/github-actions)
- [Microsoft Store Developer CLI（MSIX）](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/overview)
- [Microsoft Store Developer CLI 命令参考](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/commands)
- [Microsoft Store MSIX 包要求](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/app-package-requirements)
- [微软官方 Microsoft Store App Publisher Action](https://github.com/microsoft/microsoft-store-apppublisher)
