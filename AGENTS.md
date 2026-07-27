# AGENTS.md
## Communication
- 默认使用中文回复，每句话自然带“喵”。
- 技术判断、路径、命令、风险和验证结果必须准确完整。
## Local Environment
- 不在本机运行 `flutter`、`dart`、Gradle、Xcode 或平台构建命令。
- Flutter Analyze、测试、构建、Profile 和性能分析全部通过 GitHub Actions 执行。
- 本地只允许检查、编辑、格式化非生成文件和执行非 Flutter 的只读检查。
- 不安装或修改 Visual Studio、Android SDK、Gradle、CocoaPods 或 Xcode 环境。
## Git Safety
- 保留工作区中已有的用户修改，不覆盖或回退未知改动。
- 未经用户明确批准，不执行 `git add`、commit、push、tag 或 Release 操作。
- 在请求 Git 操作前，先检查并汇报 `git status` 与 `git diff HEAD`。
- 不提交证书、私钥、API Key、Team ID、签名文件或其他 Secrets。

## Project Structure

- 应用标识统一为 `io.github.vincentzyuapps.dartflutterdemo`。
- `android/`、`ios/`、`windows/`、`linux/`、`macos/` 必须常驻源码树。
- 平台目录只允许通过一次性 GitHub Actions bootstrap 生成并审查。
- 正常构建工作流不得执行 `flutter create` 或用补丁临时生成平台工程。
- 跨平台系统信息能力位于 `packages/system_info_vincentzyu/`。
- Windows 优先使用 Win32 C++ FFI，PowerShell 只能作为最后 fallback。
- Android Widget 属于应用本身，不放入通用系统信息插件。

## Diagnostics

- 系统信息使用类型化原始数据，显示格式由 App 层负责。
- 每个字段记录来源、耗时、fallback 和错误。
- 日志同步到内存、UI、Console 和异步文件。
- 每个会话一个日志，单文件 10 MiB，最多保留五个文件。
- 日志不联网自动上传，导出时提示包含设备信息。

## CI Conventions

- Commit 首行使用 Conventional Commits，例如 `chore(docs): ...`。
- CI 标记写在 commit message 末尾，推荐使用方括号风格。
- 已实现 `[build-release]`、`[build-profile]`、`[build-debug]`、`[run-performance]`、`[release-performance]`。
- `[build-publish]` 为微软商店预留词，首次人工上架和工作流实现完成前不得声称可用。
- CI 只匹配连字符关键词，方括号只是提交风格规范。
- `build-release.yml` 负责 Release 构建与 GitHub Release。
- `profile-debug.yml` 负责保留七天的 Profile 与 Debug 产物。
- `performance.yml` 的每周计划默认关闭，`run-performance` 保留七天报告，`release-performance` 创建永久 Pre-release。
- `platform-bootstrap.yml` 只生成待人工审查的平台源码 Artifact，不自动 commit。
- 启用后的 `build-publish` 必须复用 `build-release` 的质量检查与产物，并额外执行微软商店发布。
- 只有 `build-release`、`release-performance` 和启用后的 `build-publish` 可以创建 GitHub Release。
- 性能 Release 必须是独立 Pre-release，不得替代应用的 Latest Release。

## External Publishing

- 外部商店发布必须与普通构建分阶段，构建成功后才能进入发布 job。
- 微软商店 Package Identity、Publisher、Product ID 与认证方式必须来自 Partner Center，不得猜测。
- 商店凭据只存放在 GitHub Secrets 或受保护的 GitHub Environment 中。
- 生产发布使用独立 Environment、最小权限和人工审批，不允许在 fork 或 Pull Request 上运行。
- 微软商店优先发布 MSIX，并使用微软官方 `microsoft-store-apppublisher` 与 `msstore` CLI。
- MSIX 的公开身份配置可以提交，Tenant ID、Client ID、Client Secret 与 Seller ID 不得提交。
- 不在日志、Artifact、Release Notes、源码或测试夹具中输出商店凭据和签名材料。
- 外部发布 Action 必须核对官方来源并固定到受信任版本，升级时重新审查权限和输入。
- 没有完整凭据时允许实现 dry-run 和产物验证，但不得伪造成功发布。
- 任何真实外部发布、覆盖提交或撤回操作都必须在执行前再次得到用户明确授权。

## Documentation

- 英文和中文 README、工作流文档必须同步更新。
- 平台、构建模式、产物名称和支持范围必须与实际 CI 一致。
- 修改工作流时同步更新 `.github/workflows/ci.md` 和 `ci.zh-cn.md`。
- 修改工作流文件名时同步更新 README Badge、校验脚本和全仓引用。
- 本文件必须保持简洁，任何修改后都不得超过 100 行。
