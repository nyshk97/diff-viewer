#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ZIP_PATH="$PROJECT_ROOT/build/DiffViewer.zip"

if [ ! -f "$ZIP_PATH" ]; then
  echo "==> build/DiffViewer.zip not found. Running build first..."
  "$SCRIPT_DIR/build.sh"
fi

echo "==> Installing to /Applications..."
cd /tmp
rm -rf DiffViewer.app
unzip -q -o "$ZIP_PATH"
rm -rf /Applications/DiffViewer.app
mv DiffViewer.app /Applications/

echo "==> Done: /Applications/DiffViewer.app"
