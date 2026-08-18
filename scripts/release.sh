#!/bin/bash
# GitHub Release を作成して公開する。使い方: ./scripts/release.sh <version>
#
# 必ず build.sh を通す（署名 + notarize + staple + 配布 ZIP の検証）。
# 「ZIP があれば再ビルドしない」形にすると、--skip-notarize で作業した後などに
# 古い未署名 ZIP をそのまま公開しうるため、条件分岐は置かない。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ZIP_PATH="$PROJECT_ROOT/build/DiffViewer.zip"
GITHUB_REPO="nyshk97/diff-viewer"
STAGE_DIR=""

cleanup() {
  if [ -n "$STAGE_DIR" ]; then rm -rf "$STAGE_DIR" 2>/dev/null || true; fi
}
trap cleanup EXIT

if [ $# -eq 0 ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.0.0"
  exit 1
fi

VERSION="$1"
TAG="v$VERSION"

# ===== 事前チェック（5〜10 分のビルドを始める前に落とす）=====
# タグ・リリースの重複はリモートに問い合わせる。ローカルタグは別マシンの古い状態が
# 残っていることがあり、あてにならない。
if ! gh auth status >/dev/null 2>&1; then
  echo "NG: gh が未認証です。gh auth login を先に済ませてください。" >&2
  exit 1
fi
if gh release view "$TAG" --repo "$GITHUB_REPO" >/dev/null 2>&1; then
  echo "NG: リリース $TAG は既に存在します。" >&2
  exit 1
fi
if [ -n "$(git ls-remote --tags origin "refs/tags/$TAG")" ]; then
  echo "NG: タグ $TAG は既にリモートにあります。" >&2
  exit 1
fi

# ===== ビルド（署名 + notarize + 検証）=====
"$SCRIPT_DIR/build.sh"

[ -f "$ZIP_PATH" ] || { echo "NG: $ZIP_PATH がありません" >&2; exit 1; }

# ===== 公開直前ガード =====
# build.sh 内でも検証しているが、公開するバイトそのものをもう一度見る。
# stapler validate は spctl と違って staple ticket の存在を直接確認できる。
echo "==> 公開前の最終確認..."
STAGE_DIR="$(mktemp -d)"
ditto -x -k "$ZIP_PATH" "$STAGE_DIR"
STAGED_APP="$STAGE_DIR/DiffViewer.app"
xcrun stapler validate "$STAGED_APP"

# アプリ内バージョンとタグの食い違いを止める。
# release.sh は MARKETING_VERSION を更新しないので、pbxproj を先に上げ忘れると
# 「v1.8.0 として公開したアプリが自称 1.7.1」という状態で出てしまう。
APP_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$STAGED_APP/Contents/Info.plist")"
if [ "$APP_VERSION" != "$VERSION" ]; then
  echo "NG: アプリ内バージョン ($APP_VERSION) と指定バージョン ($VERSION) が一致しません。" >&2
  echo "    DiffViewer/DiffViewer.xcodeproj/project.pbxproj の MARKETING_VERSION を" >&2
  echo "    $VERSION に更新してコミットしてから再実行してください。" >&2
  exit 1
fi

echo "==> Creating GitHub release $TAG..."
gh release create "$TAG" \
  "$ZIP_PATH" \
  --repo "$GITHUB_REPO" \
  --title "$TAG" \
  --notes "DiffViewer $VERSION"

SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
echo ""
echo "==> Release created: $TAG"
echo "==> SHA256: $SHA256"
echo ""
echo "Update homebrew-tap cask with:"
echo "  version \"$VERSION\""
echo "  sha256 \"$SHA256\""
