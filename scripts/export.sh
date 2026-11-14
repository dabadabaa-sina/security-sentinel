#!/usr/bin/env bash
# 导出 Security Sentinel 插件为可分发的 zip
# 用法: ./scripts/export.sh [输出目录]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION="$(grep -m1 '"version"' "$PLUGIN_ROOT/kimi.plugin.json" | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
OUT_DIR="${1:-$PLUGIN_ROOT/dist}"
PKG="security-sentinel-${VERSION}.zip"

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR/$PKG"

cd "$PLUGIN_ROOT"
# 仅打包插件本体，排除 dist/ 与开发杂物
zip -r "$OUT_DIR/$PKG" . \
  -x "dist/*" -x ".git/*" -x "*.DS_Store" -x "scripts/export.sh"

echo "导出完成: $OUT_DIR/$PKG"
echo "安装: /plugins install $OUT_DIR/$PKG"
