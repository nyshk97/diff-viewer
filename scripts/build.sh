#!/bin/bash
# DiffViewer 配布用ビルド
#
# Release archive → export → Developer ID で再署名（Hardened Runtime + secure timestamp）
# → notarize → staple → 配布 ZIP を作る。
# 出力: build/DiffViewer.zip と、その sha256。
#
# --skip-notarize: 署名検証まで実行して終了する（notarize / staple / 配布 ZIP をスキップ）。
#     署名まわりの変更をリリース本番より前に自走検証する用。ZIP は作らない。
#
# 成果物のパスは 4 つに分ける。canonical な build/DiffViewer.zip には
# 「全検証を通ったもの」しか置かない（notarize は途中で落ちる工程が多く、canonical 名で
# 作ってから検証すると、落ち方次第で未完成品がその名前に残るため）。
#   提出用: build/DiffViewer-notarize.zip   （notarytool submit 用・trap で削除）
#   展開先: mktemp -d                        （最終検証用・trap で削除）
#   一時名: build/.DiffViewer.zip.tmp        （staple 後に作る・trap で削除）
#   配布用: build/DiffViewer.zip             ← 全検証を通った後に mv で置くだけ
set -euo pipefail

SKIP_NOTARIZE=0
for arg in "$@"; do
  case "$arg" in
    --skip-notarize) SKIP_NOTARIZE=1 ;;
    *) echo "不明な引数: ${arg}（使えるのは --skip-notarize のみ）" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_ROOT/DiffViewer/DiffViewer.xcodeproj"
ARCHIVE_PATH="/tmp/DiffViewer.xcarchive"
EXPORT_PATH="/tmp/DiffViewerExport"
APP_PATH="$EXPORT_PATH/DiffViewer.app"
OUTPUT_DIR="$PROJECT_ROOT/build"

# Developer ID（配布用）の Team。Apple Development 側の U4WAHGGBR7 とは別物なので取り違えない。
TEAM_ID="VYDUR99LAM"
# notarytool の keychain プロファイル（自作 Mac アプリ全体で共通）。中身は App Store Connect の API キー。
# 未作成の場合: xcrun notarytool store-credentials nyshk97-notary \
#   --key ~/Library/CloudStorage/Dropbox/secrets/AuthKey_M4FG2B8JFX.p8 \
#   --key-id M4FG2B8JFX --issuer 024fc873-10f9-49a4-8d6f-20fb5c7bd522
NOTARY_PROFILE="${NOTARY_PROFILE:-nyshk97-notary}"

DIST_ZIP="$OUTPUT_DIR/DiffViewer.zip"
SUBMIT_ZIP="$OUTPUT_DIR/DiffViewer-notarize.zip"
TMP_ZIP="$OUTPUT_DIR/.DiffViewer.zip.tmp"
STAGE_DIR=""

# 成功・失敗どちらでも中間生成物を残さない。`rm` は環境によって trash 系の関数に
# 置き換わっていて存在しないパスで非ゼロ終了するので、必ず握りつぶす。
cleanup() {
  rm -rf "$SUBMIT_ZIP" "$TMP_ZIP" 2>/dev/null || true
  if [ -n "$STAGE_DIR" ]; then rm -rf "$STAGE_DIR" 2>/dev/null || true; fi
}
trap cleanup EXIT

# ===== 署名 ID の解決（ビルド前に落とす）=====
# ハッシュはマシンごとに違うので直書きしない。Team ID で絞って keychain から引く
# （keychain に他 Team の Developer ID があっても誤爆しない）。
SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
  | awk -F'"' "/Developer ID Application.*\\($TEAM_ID\\)/ {print \$2; exit}")"
if [ -z "$SIGN_IDENTITY" ]; then
  echo "NG: Developer ID Application（Team ${TEAM_ID}）の証明書が keychain にありません。" >&2
  echo "    Xcode → Settings → Accounts → Manage Certificates から取得してください。" >&2
  exit 1
fi
echo "==> 署名 ID: $SIGN_IDENTITY"

# ===== 古い成果物を消す =====
# 残っていると「ビルドに失敗したのに前回の ZIP が公開される」経路ができる。
mkdir -p "$OUTPUT_DIR"
rm -rf "$DIST_ZIP" "$SUBMIT_ZIP" "$TMP_ZIP" "$ARCHIVE_PATH" "$EXPORT_PATH" 2>/dev/null || true

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

[ -d "$APP_PATH" ] || { echo "NG: export に失敗しました: $APP_PATH がありません" >&2; exit 1; }

# ===== 配布用に再署名 =====
# archive/export の署名は開発用で notarize 要件を満たさない:
#   - get-task-allow entitlement が付く（配布で禁止 → Invalid）
#   - secure timestamp が無い（"Signed Time" だけ。Apple TSA の Timestamp が必須 → Invalid）
# entitlements を渡さない（= 空）ことで get-task-allow を落とす。このアプリは entitlement 不要
# （sandbox 無効・特別な権限なし）。埋め込み framework も無いので単一バンドルの再署名で足りる。
echo "==> Signing (Hardened Runtime + secure timestamp)..."
codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_PATH"

# ===== 署名検証（notarize の前提条件を全部見る）=====
# codesign の出力は一旦変数に取ってから判定する。`codesign ... | grep -q` の直結は
# grep -q のパイプ早期終了で codesign が SIGPIPE 終了し、pipefail 下で誤検知するため。
echo "==> Verifying signature..."
codesign --verify --strict --verbose=2 "$APP_PATH"

fail=0
info="$(codesign -dvv "$APP_PATH" 2>&1)"
case "$info" in *"Signature=adhoc"*) echo "NG: adhoc 署名が残存" >&2; fail=1 ;; esac
case "$info" in *"TeamIdentifier=$TEAM_ID"*) ;; *) echo "NG: TeamIdentifier が $TEAM_ID でない" >&2; fail=1 ;; esac
case "$info" in *"Timestamp="*) ;; *) echo "NG: secure timestamp なし" >&2; fail=1 ;; esac
case "$info" in *"(runtime"*) ;; *) echo "NG: Hardened Runtime が無効" >&2; fail=1 ;; esac
ent="$(codesign -d --entitlements - "$APP_PATH" 2>&1)"
case "$ent" in *get-task-allow*) echo "NG: get-task-allow が残存（配布で禁止）" >&2; fail=1 ;; esac
[ "$fail" -eq 0 ] || exit 1
echo "==> 署名 OK（adhoc でない / Team $TEAM_ID / timestamp あり / runtime / get-task-allow なし）"

if [ "$SKIP_NOTARIZE" -eq 1 ]; then
  echo ""
  echo "==> --skip-notarize: 署名検証まで完了（配布 ZIP は作っていません）"
  echo "    app: $APP_PATH"
  exit 0
fi

# ===== notarize =====
echo "==> Notarizing (数分かかります)..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$SUBMIT_ZIP"
# notarytool の exit code だけに頼らず status を見る。
submit_out="$(xcrun notarytool submit "$SUBMIT_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)" || true
echo "$submit_out"
case "$submit_out" in
  *"status: Accepted"*) ;;
  *"No Keychain password item found for profile"*)
    echo "NG: keychain プロファイル '$NOTARY_PROFILE' が見えません。" >&2
    echo "    画面がロックされていると資格情報が見えなくなります（解除すれば直る）。" >&2
    echo "    判定: ioreg -n Root -d1 -a | plutil -extract IOConsoleLocked xml1 -o - -" >&2
    exit 1 ;;
  *) echo "NG: notarize が Accepted になりませんでした" >&2; exit 1 ;;
esac

echo "==> Stapling..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

# ===== 配布 ZIP（staple が通ってから初めて作る）=====
# zip -r は symlink を実体化して署名を壊すうえ、既存 zip に追記するので使わない。
echo "==> Packaging..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$TMP_ZIP"

# ===== 配布 ZIP そのものを展開して検証 =====
# 検証対象は「配布されるバイト」でなければ意味がない。再 zip の過程で署名が壊れる経路は
# ここでしか捕まらない。spctl だけでは staple ticket の有無を保証できないので
# stapler validate を併用する。
echo "==> Verifying distribution zip..."
STAGE_DIR="$(mktemp -d)"
ditto -x -k "$TMP_ZIP" "$STAGE_DIR"
STAGED_APP="$STAGE_DIR/DiffViewer.app"
codesign --verify --deep --strict "$STAGED_APP"
xcrun stapler validate "$STAGED_APP"
assess="$(spctl --assess --type execute -vv "$STAGED_APP" 2>&1)" || true
echo "$assess"
case "$assess" in
  *"Notarized Developer ID"*) ;;
  *) echo "NG: Gatekeeper 評価が Notarized Developer ID になりませんでした" >&2; exit 1 ;;
esac

# 全検証を通ってから canonical 名に置く。ここまで来なければ build/DiffViewer.zip は作られない。
mv "$TMP_ZIP" "$DIST_ZIP"

echo ""
echo "==> Done: $DIST_ZIP"
shasum -a 256 "$DIST_ZIP"
