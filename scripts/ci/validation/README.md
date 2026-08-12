# ✅ YAML 校验工具

🔍 `check-yaml.py` 用于安全解析 YAML，并检查重复键和语法错误。修改任何 `.yml` 或 `.yaml` 文件后，都应运行该工具进行验证。

## 🚀 推荐用法

💡 请在仓库根目录通过 `uv` 直接运行校验器，脚本中的 PEP 723 配置会自动提供固定版本的 PyYAML 隔离依赖。

```bash
uv run scripts/ci/validation/check-yaml.py
```

## 🧪 使用仓库虚拟环境

如需显式维护仓库级 `.venv`，可以先创建虚拟环境并安装依赖，再通过该环境中的 Python 运行校验器。

```bash
uv venv
uv pip install PyYAML==6.0.2
uv run python scripts/ci/validation/check-yaml.py
```

## 📂 指定校验范围

不传路径时，工具会校验所有受 Git 跟踪的 `.yml` 和 `.yaml` 文件。也可以传入相对路径、绝对路径或目录。

```bash
uv run scripts/ci/validation/check-yaml.py pubspec.yaml
uv run scripts/ci/validation/check-yaml.py .github/workflows
uv run scripts/ci/validation/check-yaml.py /absolute/path/to/config.yaml
```

## 🎨 控制终端颜色

终端颜色默认为自动检测，也可以通过 `--color always` 或 `--color never` 明确控制。

```bash
uv run scripts/ci/validation/check-yaml.py --color always
uv run scripts/ci/validation/check-yaml.py --color never
```
