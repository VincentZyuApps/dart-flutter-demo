# 🎨 SVG Generation Scripts

✨ Generate animated SVG language statistics cards for README display.

## 📦 Prerequisites

```bash
# 🏗️ Create virtual environment (one-time)
uv venv

# ⬇️ Install dependencies
uv pip install "fonttools[woff2]" brotli
```

## 🚀 Usage

▶️ Run from the repository root:

```bash
# 📊 Generate language line count card
uv run python ./scripts/svg/generate-lang-line-stats.py

# 📏 Generate language byte size card
uv run python ./scripts/svg/generate-lang-byte-stats.py
```

## 🖼️ Output

📄 Outputs are written to `doc/images/svg/`:

- 📈 `doc/images/svg/lang-line-stats.svg`
- 📊 `doc/images/svg/lang-byte-stats.svg`

Language detection is shared by both cards and follows GitHub Linguist-style names and colors for Git-visible repository text files, including tracked files and unignored files waiting to be committed. It includes application code, PowerShell and Shell scripts, Markdown, YAML, JSON, XML, web languages, package configuration, and platform build files while excluding generated icons, screenshots, generated SVG cards, temporary files, and build output.
