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
