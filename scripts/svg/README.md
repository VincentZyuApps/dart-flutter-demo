# 🎨 SVG Generation Scripts

✨ Generate animated SVG language statistics cards for README display.

## 📦 Prerequisites

```bash
# 🏗️ Create virtual environment (one-time)
uv venv

# ⬇️ Install dependencies
uv pip install "fonttools[woff2]"
```

## 🚀 Usage

▶️ Run from the repository root:

```bash
# 📊 Generate language line count card
uv run python ./scripts/svg/generate_lang_line_stats.py

# 📏 Generate language byte size card
uv run python ./scripts/svg/generate_lang_byte_stats.py
```

## 🖼️ Output

📄 Outputs are written to `doc/`:

- 📈 `doc/lang-line-stats.svg`
- 📊 `doc/lang-byte-stats.svg`
