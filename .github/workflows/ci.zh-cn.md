> **[【📖 English】](ci.md)** | **[【📖 简体中文】](ci.zh-cn.md)**

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
| `build-release` | `release-publish.yml` | 六个平台 Release 目标、x86_64 Flatpak 和三个 Profile 目标 | 发布后永久保留 | 是 |
| `build-publish` | `release-publish.yml` | `build-release` 的全部内容，加签名 Flatpak 与 Microsoft Store 发布 | 永久，并更新外部渠道 | 是 |
| `build-profile` | `profile-debug.yml` | Windows x64、Linux x64、Android Universal Profile | 7 天 | 否 |
| `build-debug` | `profile-debug.yml` | Windows x64、Linux x64、Android Universal Debug | 7 天 | 否 |
| `run-performance` | `performance.yml` | Windows、Linux、macOS 的 JSON/Markdown/日志报告包 | 7 天 | 否 |
| `release-performance` | `performance.yml` | 相同的完整性能报告包 | 永久 Performance Pre-release | 是 |

旧形式 `build release`、`build action` 或 `BUILD-RELEASE` 都不会匹配。同一条 commit 可以放多个有效关键词，从而启动多个工作流。

## 🚀 Release 与发布

`release-publish.yml` 在 push 包含 `build-release` 或 `build-publish` 时运行，也可以从 `workflow_dispatch` 手动运行。`build-publish` 是严格超集：两个关键词都会创建完全相同且经过验证的 GitHub Release，只有 `build-publish` 会请求签名 Flatpak 更新，并把同一份已验证 MSIX 提交到 Microsoft Store 认证。

所有发布的应用版本，包括带有 `alpha`、`beta` 或 `rc` 后缀的版本，都会创建为非草稿的正式 Release，并明确标记为仓库的 Latest Release。

只有应用 Release Notes 包含 Commit Log，范围从最近一个可达且匹配 `v[0-9]*` 的应用 tag 之后开始；Performance、Profile、Debug 和 Bootstrap 输出都不包含提交历史。

流水线先运行 `flutter analyze`、根项目测试、本地插件测试和 CI 触发词测试，然后构建：

| 🎯 目标 | 🖥️ Runner | 📦 Release 输出 |
|---|---|---|
| Windows x64 | `windows-latest` | 便携 ZIP、Inno Setup EXE 和 Store 提交用 MSIX |
| Linux x64 | `ubuntu-22.04` 加 Freedesktop `25.08` 容器 | tar.gz、DEB、AppImage 和 Flatpak |
| macOS x64 | `macos-15-intel` | DMG 和 ZIP |
| macOS ARM64 | `macos-latest` | DMG 和 ZIP |
| Android | `ubuntu-latest` | Universal、ARM64 和 x86_64 APK |
| iOS ARM64 | `macos-latest` | 未签名 IPA |

同一次运行还会构建永久附加到 Release 的 Windows x64、Linux x64 和 Android Universal Profile 包，文件名含 `-profile-`。

### 🧪 手动 Dry-Run

手动运行默认 `publish=false`。它会执行质量检查、全部 Release 构建、Flatpak 打包与冒烟测试、三项永久 Profile 构建、MSIX 校验和 Release Notes 渲染，但只上传保留七天的 `release-dry-run-*` Artifact，不创建 tag 或 GitHub Release。

确认 dry-run 全部通过后再使用 `publish=true`。同时设置 `publish_external_channels=true` 可以复现 `build-publish` 并更新 Flatpak 与 Microsoft Store；若没有启用 `publish=true`，该选项会被拒绝。push 中包含任一发布关键词时，都会在所有必要 job 成功后自动发布。

## 📦 Flatpak 包校验

`check-flatpak-repo.yml` 是手动触发的 x86_64 `.flatpak` package-only 工作流。它不会创建 GitHub Release、更新 Flatpak 仓库、使用生产 GPG 密钥或发布到 Flathub。

工作流先在 `ubuntu-22.04` 构建已提交的 Linux 应用并保留完整 Flutter bundle，再放入官方 Freedesktop `25.08` Flatpak 容器封装。Flatpak 分支始终固定为 `stable`；应用版本和发布日期仍然独立来自 `pubspec.yaml`。

初始严格沙箱只开放网络与 IPC 共享、Wayland、回退 X11 和 DRI 渲染，不开放主机或 Home 文件系统、任意设备以及直接的系统/会话总线。Flatpak 未安全暴露的系统信息可能暂时无法取得或描述的是沙箱，后续只有实现并验证更窄的只读集成后才会扩大权限。

运行工作流并下载保留七天的 package-only Artifact：

```bash
gh workflow run check-flatpak-repo.yml --ref main
RUN_ID="$(gh run list --workflow check-flatpak-repo.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$RUN_ID" --exit-status
gh run download "$RUN_ID" --name "flatpak-package-only-$RUN_ID" --dir "tmp/downloads/ci/flatpak-package-only-$RUN_ID"
```

工作流会校验 Desktop 文件与 AppStream 元数据、安装生成的 bundle、核对准确的 `app/io.github.vincentzyuapps.dartflutterdemo/x86_64/stable` ref 与版本、拒绝宽泛沙箱权限，并要求应用在虚拟显示器的 20 秒冒烟测试期间持续运行。

下载的 `.flatpak` 是版本固定的侧载 bundle，不会配置自动更新。`release-publish.yml` 复用相同校验脚本，并把版本化 bundle 附加到每次应用 Release。`[build-publish]` 还会附加 `flatpak-publish-request.json`；独立的 [`VincentZyuApps/flatpak-repo`](https://github.com/VincentZyuApps/flatpak-repo) 工作流发现该标记后发布签名 `stable` 更新，并通过固定的 [`.flatpakref`](https://vincentzyuapps.github.io/flatpak-repo/dart-flutter-demo.flatpakref) 提供更新。

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
| Windows | `dart-flutter-demo-windows-x64-v<version>.zip` / `-setup.exe` / `dart-flutter-demo-windows-x64-store-v<version>.msix` |
| Linux | `dart-flutter-demo-linux-x64-v<version>.tar.gz` / `.deb` / `.AppImage` / `.flatpak` |
| macOS | `dart-flutter-demo-macos-<arch>-v<version>.dmg` / `.zip` |
| Android | `dart-flutter-demo-android-<abi>-v<version>.apk` |
| iOS | `dart-flutter-demo-ios-arm64-v<version>.ipa` |
| Profile | `dart-flutter-demo-<platform>-profile-v<version>.<extension>` |
| Performance | `performance-summary-<UTC>-<sha>.md` / `.json`、各平台 `.md` / `.json`，以及 `performance-workflow-<UTC>-<sha>.log` |

GitHub tag 和文件名使用 `pubspec.yaml` 版本中 `+` 之前的部分。例如 `X.Y.Z-beta.W+YYYYMMDD` 会生成 tag `vX.Y.Z-beta.W`。

## 🔐 权限与签名

只有应用的 `publish` job 和性能报告的 `publish-report` job 获得 `contents: write`，其余 job 都是只读权限。发布使用默认 `GITHUB_TOKEN`。仓库不保存 Team ID、证书、Provisioning Profile、keystore 或其他签名 Secret。

Android 产物使用 CI 临时签名；iOS IPA 与 macOS 包均未签名。AltStore 侧载前自行签名 IPA；进入 TestFlight 或 App Store 前，应在独立的私有发布流程中配置签名。

## 🏪 外部分发与 Microsoft Store

> **当前状态：** 产品已经 Live，CI 应用拥有 Partner Center **Manager (Windows)** 权限，只读认证检查也成功列出 Store ID `9PP2SRN17C4F`。`build-publish` 现在同时启用签名自建 Flatpak 发布与 Microsoft Store 自动提交。

`build-publish` 扩展 `build-release`：执行完全相同的质量检查、Release 构建、永久 Profile 构建、GitHub Release 发布、Flatpak 打包和 Windows x64 MSIX 校验。它附加 `flatpak-publish-request.json`，随后 `publish-flatpak-repository` 会立即调用公开的 `flatpak-repo` 工作流，并等待其完成签名与 Pages 部署。与此同时，`publish-microsoft-store` 会校验同一 Windows Artifact 的元数据与 SHA-256，确认目标 Product ID 可见，并把 MSIX 提交认证。任一下游失败都会把应用工作流标红，但不会删除 GitHub Release 或撤销另一个外部渠道。

本项目保持永久免费。`vX.Y.Z-beta.W` 等预发布版本也会直接提交正式商店页面，不使用 Package Flight。Store job 不等待人工审批，因此推送包含 `build-publish` 的 commit 前必须仔细检查版本和 Release Notes。

现有 Windows x64 便携 ZIP 与 Inno Setup EXE 继续作为 GitHub Release 附件。本项目不规划 MSI：MSI 会重复 EXE 已覆盖的传统安装器职责，增加一套打包流水线，并且仍然需要 Authenticode 签名。MSIX 才是商店发布格式；微软会在认证通过后重新签名，因此只通过商店分发时不需要购买 CA 代码签名证书。

### 🧾 首次在 Partner Center 人工上架

微软目前只支持通过 GitHub Actions 自动更新已经发布并处于 Live 状态的免费产品。当前产品已完成以下前置条件；重新配置或审计时可按此清单检查：

1. 在 [Partner Center](https://storedeveloper.microsoft.com/) 注册 Windows 开发者账号，并完成要求的身份验证。
2. 从 Partner Center 主页进入 **应用和游戏**，创建新产品并选择 **MSIX 或 PWA 应用**，然后保留应用名称。
3. 打开新建的产品，从左侧导航进入 **产品标识**，按下一节记录 Store 与 MSIX 的公共身份值。
4. 将现有 Microsoft Entra 租户关联到 Partner Center，或从 Partner Center 创建租户。
5. 为 CI 注册 Microsoft Entra 应用，在 Partner Center 的账号用户管理中添加该应用，并授予 **Manager** 角色。
6. 手动运行 `release-publish.yml` 并保持 `publish=false`，下载保留七天的 `release-dry-run-*` Artifact，再选择其中的 Windows x64 Store `.msix`。
7. 按照 [Microsoft Store 首次提交清单](../../doc/microsoft-store-submission.md)，在 Partner Center 人工创建第一次提交，上传该 MSIX，填写商店介绍、隐私、年龄分级、可用地区和政策信息，然后提交认证。
8. 等待产品完成发布并显示为 **Live**，之后再配置自动更新。

商店包版本独立于 `pubspec.yaml` SemVer。它使用四段纯数字，第一段不能为零，每段不超过 65535，第四段为零。工作流会单独生成并验证商店版本，不会直接传入 `vX.Y.Z-beta.W`。

### 🪪 产品标识页面

创建产品后，路径是 **Partner Center 主页 -> 应用和游戏 -> dart-flutter-demo -> 产品标识**。当前产品也可以直接打开 [`9PP2SRN17C4F` 产品标识页面](https://partner.microsoft.com/dashboard/products/9PP2SRN17C4F/identity)。这里主要展示可以写入 MSIX Manifest、工作流配置或公开文档的产品公共身份；其中 MSA 应用 ID 是产品身份值，不是 CI 客户端凭据。

当前页面给出的准确值如下：

| 🧩 Partner Center 字段 | 📋 当前值 | 🎯 使用方式 |
|---|---|---|
| Store ID | `9PP2SRN17C4F` | `MS_STORE_PRODUCT_ID`，并用于商店公开链接与发布目标 |
| Package/Identity/Name | `VincentZyu.dart-flutter-demo` | `MS_STORE_IDENTITY_NAME`，写入 MSIX `Package/Identity/Name` |
| Package/Identity/Publisher | `CN=A12FF185-DB00-4CAC-ADE2-C501823ECC8F` | `MS_STORE_PUBLISHER`，写入 MSIX `Package/Identity/Publisher` |
| Package/Properties/PublisherDisplayName | `VincentZyu` | `MS_STORE_PUBLISHER_DISPLAY_NAME`，写入 MSIX PublisherDisplayName |
| Package Family Name (PFN) | `VincentZyu.dart-flutter-demo_j4jaay73mj39p` | 商店根据 Package Identity 计算；不单独写入 Manifest |
| Package SID | `S-1-15-2-4052166922-3111628424-3389906557-1246929253-1774262628-4171725999-764323245` | 商店计算标识；当前工作流不使用 |
| Store URL | `https://apps.microsoft.com/detail/9PP2SRN17C4F` | 产品上线后供用户访问的公开链接 |
| Store protocol link | `ms-windows-store://pdp/?productid=9PP2SRN17C4F` | 在 Windows 上打开 Microsoft Store 产品页 |
| MSA 应用 ID | 不写入仓库 | 当前 `dart-flutter-demo.ae0811c38249` 注册仅支持 Microsoft Account，不能用作 `PARTNER_CENTER_CLIENT_ID` |

`MS_STORE_DISPLAY_NAME` 不由上述 Package Identity 字段提供。它来自本仓库统一的应用展示名，当前固定为 `DartFlutterDemo`。不要用产品标题 `dart-flutter-demo` 或 Dart package 名替代这些字段。CI 必须使用独立的单租户 Entra 应用，并且绝不能把它的 Client ID 或凭据提交到仓库。

### 🔒 GitHub Environment 与 Repository Variables

打开 GitHub 仓库的 **Settings -> Environments -> New environment**，创建 `microsoft-store-production`，并配置：

- 不设置 required reviewers，因为 `build-publish` 按设计需要完全自动发布；
- 将部署分支限制为 `main` 和 `master`；
- 仓库套餐支持时启用禁止自审；
- 添加下面列出的四项 Environment Secrets 与五项 Repository Variables。

最终配置是 **4 个 Environment Secrets + 5 个 Repository Variables**。公开的 Store/MSIX 身份放在仓库级 Variables，发布凭据隔离在 `microsoft-store-production` Environment 中，只有对应 job 可以使用。

优先使用 Environment Secrets，不使用仓库全局 Secrets，这样只有 Store 认证和发布 job 可以得到凭据：

| 🔐 Environment Secret | 📍 获取位置 | 🎯 用途 |
|---|---|---|
| `PARTNER_CENTER_TENANT_ID` | Microsoft Entra 租户概览 | 选择与 Partner Center 关联的租户 |
| `PARTNER_CENTER_SELLER_ID` | Partner Center 法律信息 / Developer | 选择商店卖家账号 |
| `PARTNER_CENTER_CLIENT_ID` | Microsoft Entra 应用注册 | 标识 CI 应用 |
| `PARTNER_CENTER_CLIENT_SECRET` | Microsoft Entra 应用注册的 Secret Value | 验证 CI 应用身份 |

这些凭据不在产品的 **产品标识** 页面。依次按下面的位置取得：

1. 在 [Microsoft Entra 管理中心](https://entra.microsoft.com/) 打开 **Entra ID -> 概述**，复制 **租户 ID** 作为 `PARTNER_CENTER_TENANT_ID`。
2. 打开 **Entra ID -> 应用注册 -> 新注册**，创建 `dart-flutter-demo-store-ci` 等 CI 专用应用，账户类型选择 **仅此组织目录中的账户（单租户）**，重定向 URI 留空。复制它的 **应用程序(客户端) ID** 作为 `PARTNER_CENTER_CLIENT_ID`，不要复用仅支持 MSA 的 `dart-flutter-demo.ae0811c38249`。
3. 在新建的单租户应用中打开 **证书和密码 -> 客户端密码**，创建 Secret 并立即复制 **值（Value）** 作为 `PARTNER_CENTER_CLIENT_SECRET`；不要复制 Secret ID。
4. 打开 Partner Center 的 **账户设置 -> 法律信息 -> Developer**，复制 **卖家 ID（Seller ID）** 作为 `PARTNER_CENTER_SELLER_ID`；不要使用 Publisher、Store ID、Partner ID 或 `CN=...`。
5. 在 Partner Center 的 **账户设置 -> 用户管理 -> Microsoft Entra 应用程序** 中添加新 CI 应用并授予 **Manager (Windows)** 角色。

当前使用的 Entra 页面入口如下。Credentials 地址中的占位符应由门户自动生成；不要把真实 Client ID 写入文档：

| 🌐 Entra 页面 | 🔗 入口 URL 或模板 | 📋 需要复制的字段 |
|---|---|---|
| 租户概览 | `https://entra.microsoft.com/#view/Microsoft_AAD_IAM/EntraLanding.ReactView` | **租户 ID** -> `PARTNER_CENTER_TENANT_ID` |
| 应用注册列表 | `https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM` | 创建或打开单租户 `dart-flutter-demo-store-ci`，复制 **应用程序(客户端) ID** -> `PARTNER_CENTER_CLIENT_ID` |
| 证书和密码 | `https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/__APPLICATION_CLIENT_ID__` | 在该单租户应用中创建客户端密码并复制一次性 **Value** -> `PARTNER_CENTER_CLIENT_SECRET` |

`AADSTS9002331` 表示所选注册仅接受 Microsoft Account 用户，无法使用租户客户端凭据流程。应按上面步骤新建单租户 Entra 应用，不能把令牌端点改成 `/consumers`。

已确认的 Seller ID 入口是 [Partner Center 法律信息的 Developer 页面](https://partner.microsoft.com/dashboard/account/v3/organization/legalinfo#developer)。复制页面中的 **卖家 ID（Seller ID）** 作为 `PARTNER_CENTER_SELLER_ID`。

`https://partner.microsoft.com/dashboard/account/v3/overview` 是新版 **账户设置 | 概述** 页面，不是产品标识页面。页面搜索“租户”没有结果并不能证明租户不存在；先展开左上角汉堡菜单查找 **租户** 或 **用户管理**。如果当前账号看不到这些项目，应检查是否使用了已关联的 Entra 账号、是否进入正确租户，以及是否拥有 Partner Center **Manager** 权限。

使用产品身份页面中的准确值添加以下非敏感 Repository Variables：

| 🔧 Repository Variable | 📍 获取位置 | 🎯 用途 |
|---|---|---|
| `MS_STORE_PRODUCT_ID` | 产品标识页的 Store ID | 选择目标应用提交 |
| `MS_STORE_IDENTITY_NAME` | 产品标识页的 Package/Identity/Name | 写入 `Package/Identity/Name` |
| `MS_STORE_PUBLISHER` | 产品标识页的 Package/Identity/Publisher | 写入 Manifest Publisher |
| `MS_STORE_PUBLISHER_DISPLAY_NAME` | 产品标识页的 Package/Properties/PublisherDisplayName | 写入用户可见的发布者名称 |
| `MS_STORE_DISPLAY_NAME` | 仓库统一的应用展示名 | 写入用户可见的应用名称，当前为 `DartFlutterDemo` |

在仓库根目录运行以下命令，可以创建或覆盖五项非敏感 Repository Variables：

```bash
gh variable set MS_STORE_PRODUCT_ID --body "9PP2SRN17C4F"
gh variable set MS_STORE_IDENTITY_NAME --body "VincentZyu.dart-flutter-demo"
gh variable set MS_STORE_PUBLISHER --body "CN=A12FF185-DB00-4CAC-ADE2-C501823ECC8F"
gh variable set MS_STORE_PUBLISHER_DISPLAY_NAME --body "VincentZyu"
gh variable set MS_STORE_DISPLAY_NAME --body "DartFlutterDemo"
```

四项发布凭据必须交互式写入 Environment Secrets。逐条运行命令，在提示后粘贴对应值；不要把真实值放进命令参数、Shell 历史、文档或聊天记录：

```bash
gh secret set PARTNER_CENTER_TENANT_ID --env microsoft-store-production
gh secret set PARTNER_CENTER_SELLER_ID --env microsoft-store-production
gh secret set PARTNER_CENTER_CLIENT_ID --env microsoft-store-production
gh secret set PARTNER_CENTER_CLIENT_SECRET --env microsoft-store-production
```

GitHub 不允许重新读取 Secret Value，但可以核对已经创建的名称：

```bash
gh variable list
gh secret list --env microsoft-store-production
```

### 🔎 只读认证检查

为选定的 Entra 应用授予 Partner Center **Manager** 角色后，从 `main` 手动运行专用认证检查：

```bash
gh workflow run check-microsoft-store.yml --ref main
RUN_ID="$(gh run list --workflow check-microsoft-store.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$RUN_ID" --exit-status
gh run view "$RUN_ID" --log-failed
```

第二条命令取得最新 Run ID，第三条持续跟踪直到结束并在失败时返回非零退出码，第四条在排查时输出失败步骤日志。该工作流进入 `microsoft-store-production`，安装固定为 `v1.4` 的微软官方 Microsoft Store App Publisher Action 与 Microsoft Store Developer CLI `v0.3.9`，使用四项 Environment Secrets 认证，并且只运行 `msstore apps list`。它不会创建提交、上传包、修改元数据或发布应用。Run `31592179631` 已成功完成，并列出 Product ID `9PP2SRN17C4F`、显示名 `DartFlutterDemo` 与包 ID `VincentZyu.dart-flutter-demo`。

`GITHUB_TOKEN` 由 GitHub 自动提供，不需要手动创建。只向商店提交的 MSIX 不需要 PFX Secret，因为微软会在认证后为包签名。绝不能把 Client Secret、租户凭据、证书或它们的编码形式写入源码、日志、Artifact 或 Release Notes。

### 🚀 自动发布

跨仓库触发 Flatpak 需要一个 fine-grained personal access token：仓库范围只选择 `VincentZyuApps/flatpak-repo`，仓库权限只授予 **Actions: Read and write**。在应用仓库创建 `flatpak-dispatch-production` Environment，将部署分支限制为 `main` 和 `master`，不要设置 required reviewers，并把 Token 保存为 Environment Secret `FLATPAK_REPO_ACTIONS_TOKEN`。该 Token 只负责启动并读取目标 Action，无法访问 Flatpak GPG 私钥；私钥仍只存在于目标仓库的 `flatpak-production` Environment 中。

要创建 GitHub Release、发布签名 Flatpak 更新并把 Microsoft Store 包提交认证，使用：

```text
release: publish DartFlutterDemo

[build-publish]
```

应用工作流会构建全部常规 Release/Profile 产物、创建 GitHub Release、附加验证过的版本化 `.flatpak`，并加入 `flatpak-publish-request.json`。随后它会立即携带准确的 Release 标签和来源 Actions Run ID 调用 `flatpak-repo/publish.yml`，最多等待两分钟定位对应运行，再持续等待其完成。应用仓库没有新发布时，不再运行任何定时轮询。

目标工作流使用自己的 `flatpak-production` Environment，验证发布请求，对 OSTree commit 与 summary 进行 GPG 签名，将 `stable` 仓库部署到 GitHub Pages，并验证公开的 GPG 仓库。如果目标发布失败，应用工作流中的 `Publish signed Flatpak repository` job 也会失败。需要手动补发已有 Release 时运行：

```bash
gh workflow run publish.yml --repo VincentZyuApps/flatpak-repo --ref main -f release_tag=vX.Y.Z-beta.W
```

与此同时，`publish-microsoft-store` 会把验证过的 MSIX 提交至 Product ID `9PP2SRN17C4F` 进行异步认证。Store 工作流成功表示提交已被接受，不表示更新已经 Live。

在 `PARTNER_CENTER_CLIENT_SECRET` 到期前轮换它，并且只更新 Environment Secret 的值。如果后续认证失败，应前往 Partner Center 检查；不能把之前 GitHub job 的成功当作更新已经上线的证明。

### ✅ 验证 Microsoft Store 更新

商店发布需要分成四个阶段理解：GitHub 上传并提交认证、微软执行认证、Partner Center 标记为已发布、商店客户端收到更新。绿色的 `Publish Microsoft Store update` job 只证明第一阶段成功。对于 Release Run `31601324783`，日志已经确认版本为 `2026.812.20014.0` 的 MSIX 上传成功、新 Submission 提交成功，并且状态从 `CommitStarted` 进入 `Certification`；这些信息本身不能证明后续认证已经通过，也不能证明所有商店客户端已经能够取得更新。

在已经使用 Partner Center 应用凭据配置 Microsoft Store Developer CLI `v0.3.9` 的设备上，可以用下面的只读命令查询当前 Submission：

```powershell
msstore submission status 9PP2SRN17C4F
```

下面的命令会持续轮询，直到微软返回 `PUBLISHED` 或 `FAILED`。它可能运行很久，日常检查更适合使用上面的单次 `status` 命令：

```powershell
msstore submission poll 9PP2SRN17C4F
```

这些命令需要受保护的 `microsoft-store-production` Environment 所使用的同一组 Partner Center 凭据。不要为了在本机运行命令而把 `PARTNER_CENTER_CLIENT_SECRET` 复制到仓库、文档、Shell 历史记录、截图或共享日志中。现有 `check-microsoft-store.yml` 只验证身份认证并运行 `msstore apps list`，目前不会查询 Submission 状态。

Partner Center 仍是查看认证结果的权威 GUI。打开 `DartFlutterDemo` 产品及其最新 Submission，检查认证状态、认证报告、包版本和发布时间。`Certification` 表示微软仍在处理，`Published` 表示 Partner Center 已完成发布，`Failed` 则需要打开认证报告排查。公开 Microsoft Store 网页适合确认产品页面可以访问，但通常不会可靠地显示已安装包的精确版本。

Partner Center 显示更新已发布后，在 Windows 中打开 **Microsoft Store -> 库 -> 获取更新**，更新 `DartFlutterDemo`，然后在实际安装应用的 Windows 用户账号中运行：

```powershell
Get-AppxPackage |
  Where-Object {
    $_.Name -like '*dart*' -or
    $_.Name -like '*VincentZyu*' -or
    $_.PackageFamilyName -like '*VincentZyu*'
  } |
  Format-List Name, PackageFullName, PackageFamilyName, Version, Status, InstallLocation
```

本次 Release 的 `Version` 应为 `2026.812.20014.0`。这个商店包版本由 `0.5.0-beta.14+20260812` 映射而来，故意不同于应用展示版本。AppX 注册信息按 Windows 用户隔离，因此其他用户的终端或隔离自动化账号即使在 `VincentZyu` 已安装应用时也可能查询不到包。

### 📚 官方参考资料

- [使用 GitHub Actions 发布应用更新](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/github-actions)
- [将现有 Microsoft Entra ID 租户关联到 Partner Center](https://learn.microsoft.com/windows/apps/publish/partner-center/associate-existing-azure-ad-tenant-with-partner-center-account)
- [在 Microsoft Entra ID 中注册应用](https://learn.microsoft.com/entra/identity-platform/quickstart-register-app)
- [Microsoft Store Developer CLI（MSIX）](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/overview)
- [Microsoft Store Developer CLI 命令参考](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/commands)
- [Microsoft Store MSIX 包要求](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/app-package-requirements)
- [微软官方 Microsoft Store App Publisher Action](https://github.com/microsoft/microsoft-store-apppublisher)
