#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_ROOT/DiffViewer/DiffViewer.xcodeproj"
ARCHIVE_PATH="/tmp/DiffViewer.xcarchive"
EXPORT_PATH="/tmp/DiffViewerExport"
OUTPUT_DIR="$PROJECT_ROOT/build"

echo "==> Archiving..."
xcodebuild -project "$PROJECT" \
  -scheme DiffViewer \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  -quiet

echo "==> Exporting..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$PROJECT_ROOT/ExportOptions.plist" \
  -quiet

echo "==> Packaging..."
mkdir -p "$OUTPUT_DIR"
cd "$EXPORT_PATH"
zip -r -q "$OUTPUT_DIR/DiffViewer.zip" DiffViewer.app

echo "==> Done: $OUTPUT_DIR/DiffViewer.zip"
shasum -a 256 "$OUTPUT_DIR/DiffViewer.zip"
