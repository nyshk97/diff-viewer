#!/bin/bash
# ビルドし直して /Applications/DiffViewer.app を置き換える（ローカル確認用）。
#
# notarize はしない（ローカルに置くだけなら quarantine が付かず不要で、数分を毎回払う意味がない）。
# 署名は build.sh が Developer ID で行うので、TCC 権限はリビルドしても維持される。
# 配布用の notarize 済み ZIP が要るときは scripts/build.sh を引数なしで実行する。
#
# ZIP は経由しない。「前回の ZIP が残っていて古いアプリが入る」経路を作らないため、
# 毎回ビルドして export されたバンドルから直接入れる。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="/tmp/DiffViewerExport/DiffViewer.app"
APP_DST="/Applications/DiffViewer.app"

"$SCRIPT_DIR/build.sh" --skip-notarize

[ -d "$APP_SRC" ] || { echo "NG: $APP_SRC がありません" >&2; exit 1; }

# ===== 旧プロセスを終了して、完全に消えるまで待つ =====
# 常駐アプリなので、旧バイナリが動いたまま open しても既存プロセスが前面化されるだけで
# 新ビルドは起動しない（pgrep が旧 PID を拾って「起動できた」と誤認する）。
# quit は非同期で、エラーを返しても進行中のことがあるのでポーリングで待つ。
if pgrep -x DiffViewer >/dev/null; then
  echo "==> 起動中の DiffViewer を終了..."
  osascript -e 'tell application "DiffViewer" to quit' >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do
    pgrep -x DiffViewer >/dev/null || break
    sleep 1
  done
  if pgrep -x DiffViewer >/dev/null; then
    echo "NG: DiffViewer が終了しません。手動で終了してから再実行してください。" >&2
    exit 1
  fi
fi

# ===== 差し替え =====
# cp -R は symlink を実体化して署名を壊すので ditto を使う。
echo "==> Installing to /Applications..."
rm -rf "$APP_DST" 2>/dev/null || true
ditto "$APP_SRC" "$APP_DST"

# ===== 起動して、新しいプロセスが生きているか確認 =====
# 直前に「プロセスが 0 個」を確認済みなので、ここで見つかるプロセスは必ず新バイナリのもの。
open "$APP_DST"
for _ in $(seq 1 15); do
  pgrep -x DiffViewer >/dev/null && break
  sleep 1
done
if ! pgrep -x DiffViewer >/dev/null; then
  echo "NG: 起動後に DiffViewer のプロセスが見つかりません。" >&2
  echo "    調査: log show --predicate 'process == \"DiffViewer\"' --last 5m" >&2
  echo "          ~/Library/Logs/DiagnosticReports/" >&2
  exit 1
fi

echo ""
echo "==> Done: $APP_DST"
ps -o pid,lstart,comm -p "$(pgrep -x DiffViewer | head -1)"
echo "binary mtime: $(stat -f %Sm "$APP_DST/Contents/MacOS/DiffViewer")"
