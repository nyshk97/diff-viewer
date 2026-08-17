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

```bash
mise run build
```

`==> Done: <repo>/build/DiffViewer.zip` と SHA256 が出力されること（Release archive → export → zip まで通る）。

`mise run install` は `/Applications/DiffViewer.app` を置き換える。`mise run release <version>` は
**実行すると GitHub Release が即公開される**ので、導線の確認だけなら `mise run release --help` で
引数の解釈（`<version>` が必須）を見るに留める。

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
