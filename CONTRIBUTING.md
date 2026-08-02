# 🤝 Contributing

This repository uses Flutter 3.41.5 and keeps all supported platform projects in source control.

## ✅ Change Requirements

- Keep English and Simplified Chinese documentation synchronized.
- Preserve `io.github.vincentzyuapps.dartflutterdemo` as the application identity.
- Keep `android/`, `ios/`, `windows/`, `linux/`, and `macos/` in source control.
- Do not run `flutter create` or patch generated runners in normal build workflows.
- Put reusable system-information code in `packages/system_info_vincentzyu/`.
- Keep Windows native FFI first and PowerShell as the last fallback.
- Never commit signing credentials, certificates, API keys, or developer-team identifiers.
- Run Flutter checks through GitHub Actions rather than a local Flutter toolchain.

## 📝 Commit Format

Use a Conventional Commit summary on the first line, for example:

```text
feat(system-info): add typed diagnostics
```

Place CI directives at the end of the commit message when needed:

```text
[build-release]
[build-profile]
[build-debug]
[run-performance]
[release-performance]
```

The brackets are a style convention. CI matches the hyphenated keywords. `run-performance` keeps a report for seven days, while `release-performance` creates a permanent Performance Pre-release.

---

# 🤝 贡献指南

本仓库使用 Flutter 3.41.5，并将所有受支持平台的工程文件纳入版本控制。

## ✅ 修改要求

- 保持英文与简体中文文档同步。
- 保持 `io.github.vincentzyuapps.dartflutterdemo` 作为应用标识。
- 将 `android/`、`ios/`、`windows/`、`linux/` 和 `macos/` 保留在版本控制中。
- 正常构建工作流不得运行 `flutter create`，也不得临时 patch 生成的 Runner。
- 将可复用的系统信息代码放在 `packages/system_info_vincentzyu/` 中。
- Windows 保持原生 FFI 优先，并仅将 PowerShell 用作最后的降级路径。
- 不得提交签名凭据、证书、API Key 或开发团队标识。
- Flutter 检查统一通过 GitHub Actions 运行，不使用本地 Flutter 工具链。

## 📝 Commit 格式

第一行使用 Conventional Commits 摘要，例如：

```text
feat(system-info): add typed diagnostics
```

需要触发 CI 时，将相应指令放在 commit message 末尾：

```text
[build-release]
[build-profile]
[build-debug]
[run-performance]
[release-performance]
```

方括号只是提交信息的风格约定，CI 实际匹配的是带连字符的关键词。`run-performance` 将报告保留七天，`release-performance` 则创建永久 Performance Pre-release。
