# 動作確認手順

## ユニットテスト

```bash
cd DiffViewer && xcodebuild test -scheme DiffViewer -destination 'platform=macOS' -only-testing:DiffViewerTests 2>&1 | tail -15
```

- `GitServiceTests.testJapaneseFilenameNotEscaped` — 日本語ファイル名がエスケープされずに取得されること
- `GitServiceTests.testJapaneseFileNotDetectedAsBinary` — 日本語ファイル名のテキストファイルがバイナリ判定されないこと

## ビルド確認

```bash
cd DiffViewer && xcodebuild -scheme DiffViewer -configuration Debug build 2>&1 | tail -3
```

`** BUILD SUCCEEDED **` が出力されること。

## 配布物のビルド確認

### 署名まわりだけ確認する（notarize を飛ばす・数十秒）

```bash
mise run build:sign-only
```

- `==> 署名 OK（adhoc でない / Team VYDUR99LAM / timestamp あり / runtime / get-task-allow なし）` が出ること
- **`build/DiffViewer.zip` が作られていないこと**（`ls build/`）。このモードは配布 ZIP を作らない。
  作ってしまうと未検証の成果物が後段（release / install）に拾われる

署名属性を自分の目で見るなら:

```bash
codesign -dvv /tmp/DiffViewerExport/DiffViewer.app 2>&1 | grep -E "Signature|TeamIdentifier|Timestamp|flags"
codesign -d --entitlements - /tmp/DiffViewerExport/DiffViewer.app   # get-task-allow が出ないこと
lipo -archs /tmp/DiffViewerExport/DiffViewer.app/Contents/MacOS/DiffViewer   # x86_64 arm64
```

### notarize 込みのフルビルド（数分）

```bash
mise run build
```

`==> Done: <repo>/build/DiffViewer.zip` と SHA256 が出力されること。途中で以下が全部通る:

- `status: Accepted`（notarize）
- `The staple and validate action worked!`
- 配布 ZIP を展開しての `stapler validate` と `spctl --assess` → `source=Notarized Developer ID`

**`xcrun notarytool history --keychain-profile nyshk97-notary` が通らないときは画面ロックを疑う**
（資格情報は data-protection keychain にあり、ロック中は「プロファイルが無い」ように見える）。
判定は `ioreg -n Root -d1 -a | plutil -extract IOConsoleLocked xml1 -o - -` が `<true/>` かどうか。

### 成果物が中途半端に残らないことの確認

notarize は途中で落ちる工程が多いので、失敗しても `build/DiffViewer.zip` を残さない作りになっている。
存在しないプロファイルを渡すと安全に再現できる:

```bash
NOTARY_PROFILE=nonexistent-profile-for-test bash scripts/build.sh; echo "exit=$?"
ls build/
```

`exit=1` で終わり、`build/` が空になること（提出用の `DiffViewer-notarize.zip` も `trap` で消える）。

### インストールと起動確認

```bash
mise run install
```

`install.sh` は notarize を飛ばしてビルドし、**起動中のアプリを終了 → プロセスが消えるのを待つ →
差し替え → 起動 → 新しい PID の生存確認**まで行う。常駐アプリなので、旧プロセスが残ったまま
`open` しても既存プロセスが前面化されるだけで「起動できた」と誤認する。

`mise run release <version>` は**実行すると GitHub Release が即公開される**ので、導線の確認だけなら
`mise run release --help` で引数の解釈（`<version>` が必須）を見るに留める。

### Gatekeeper の確認（配布経路の模擬）

`brew` 経由で入るアプリには quarantine 属性が付く。属性を付けた状態で起動できるかが staple の効き目そのもの。

```bash
xattr -w com.apple.quarantine "0081;$(printf %x $(date +%s));Safari;$(uuidgen)" /Applications/DiffViewer.app
open /Applications/DiffViewer.app && pgrep -x DiffViewer
```

Gatekeeper のダイアログが出ずに起動すれば pass。**確認後は属性を消して起動し直す**
（付いたままだと App Translocation で `/private/var/folders/.../AppTranslocation/` から実行され続ける）:

```bash
osascript -e 'tell application "DiffViewer" to quit'
xattr -d com.apple.quarantine /Applications/DiffViewer.app
open /Applications/DiffViewer.app
ps -o pid,comm -p "$(pgrep -x DiffViewer | head -1)"   # /Applications/... から動いていること
```

## UI の動作確認（手動）

XCUITest は以下の理由で使えないため、UI の確認は手動で行う。

### XCUITest が使えない理由

- DiffViewer はメニューバーアプリ（`Info.plist` の `LSUIElement = YES`）
- UI は `FloatingPanel` で表示されており、通常のウィンドウではない
- XCUITest のアクセシビリティAPIからはこれらの UI 要素が見えない（`staticTexts.count = 0` になる）
- XCUITest を使うにはアプリ本体のウィンドウ表示方法を変更する必要があり、テストのためにプロダクションコードを修正することになるため不適切

### 手動確認が必要なケース

- ファイル名の表示に関する変更
- diff の表示に関する変更
- レイアウトやスタイルの変更
