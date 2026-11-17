#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

mkdir -p "$TARGET_DIR"
cp -R "$SCRIPT_DIR/nvim/"* "$TARGET_DIR/"
echo "synvim installed to $TARGET_DIR"
