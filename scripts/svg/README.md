# 🎨 SVG 生成脚本

✨ 生成用于 README 展示的动态 SVG 语言统计卡片。

## 📦 环境准备

```bash
# 🏗️ 创建虚拟环境（只需执行一次）
uv venv

# ⬇️ 安装依赖
uv pip install "fonttools[woff2]" brotli
```

## 🚀 使用方法

▶️ 请在仓库根目录运行：

```bash
# 📈 生成语言行数统计卡片
uv run python ./scripts/svg/generate-lang-line-stats.py

# 📊 生成语言字节数统计卡片
uv run python ./scripts/svg/generate-lang-byte-stats.py
```

## 🖼️ 输出文件

📄 生成结果会写入 `doc/images/svg/`：

- 📈 `doc/images/svg/lang-line-stats.svg`
- 📊 `doc/images/svg/lang-byte-stats.svg`

## 🧩 统计范围

两个统计卡片共用 `common.py` 中的语言识别、颜色和文件枚举逻辑。统计规则参考 GitHub Linguist 的语言名称与配色，处理 Git 可见的仓库文本文件，包括已跟踪文件和尚未提交但未被忽略的文件。

统计范围包含应用源码、PowerShell 与 Shell 脚本、Markdown、YAML、JSON、XML、网页语言、软件包配置和各平台构建文件；图标资源、截图、生成的 SVG 卡片、临时文件与构建产物不会计入统计。
