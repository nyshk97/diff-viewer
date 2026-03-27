# Diff Viewer 実装計画

## 開発環境

- Xcode（Mac App Store からインストール）
- Swift / SwiftUI + AppKit（NSPanel）
- macOS 26.3.1 以降

### 開発の流れ

1. Xcode で macOS App プロジェクトを作成（SwiftUI, Swift）
2. Xcode 上で `Cmd + R` でビルド＆実行して動作確認
3. コード変更 → `Cmd + R` で再実行、を繰り返す

## フェーズ構成

### フェーズ 1: プロジェクト作成とランチャーモードの土台

**ゴール:** ショートカットキーで空のウィンドウがトグル表示される状態

1. Xcode で macOS App プロジェクトを作成
2. `Info.plist` に `LSUIElement = YES` を設定（Dock に表示しない）
3. `MenuBarExtra` でメニューバーにアイコンを表示（終了ボタンのみ）
4. `NSPanel` のサブクラスを作成
   - `styleMask`: `.nonactivatingPanel`, `.titled`, `.fullSizeContentView`
   - `isFloatingPanel = true`
   - `level = .floating`
   - `collectionBehavior`: `.fullScreenAuxiliary`（フルスクリーン上でも表示可能に）
   - `titleVisibility = .hidden`, `titlebarAppearsTransparent = true`
   - `hidesOnDeactivate = false`（ショートカットでのみ閉じる）
   - `isReleasedWhenClosed = false`
5. ウィンドウサイズを画面の 80% に設定し、中央に配置
6. グローバルショートカット `Cmd + Ctrl + D` でパネルをトグル表示
   - ライブラリ: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)（Swift Package Manager で追加）
7. パネル内に SwiftUI ビューを `NSHostingView` でホスト

### フェーズ 2: 設定ファイルの読み込み

**ゴール:** `~/.config/diff-viewer/config.json` からリポジトリ一覧を読める状態

1. 設定ファイルの JSON 構造を定義
   ```json
   {
     "repositories": [
       "/Users/d0ne1s/project-a",
       "/Users/d0ne1s/project-b"
     ]
   }
   ```
2. `Codable` な構造体で設定をデコード
3. ファイルが存在しない場合のエラーハンドリング

### フェーズ 3: Git diff の取得とパース

**ゴール:** 各リポジトリの diff データを構造化して取得できる状態

1. `Process` (Foundation) で `git diff` / `git diff --staged` を実行
2. unified diff 形式の出力をパースする
   - ファイル名、変更行（追加/削除）、行番号を抽出
   - パース結果をモデルに格納:
     ```
     Repository → [FileDiff] → [DiffHunk] → [DiffLine]
     ```
3. 未ステージとステージ済みを区別してモデルに持つ

### フェーズ 4: diff 表示 UI（メイン）

**ゴール:** GitHub Dark モード風の side-by-side diff ビューが動作する状態

1. 全体レイアウト
   - ダークテーマの背景色（GitHub Dark: `#0d1117`）
   - スクロール可能な縦一列レイアウト
   - 変更がない場合は中央に「変更なし」メッセージ
2. リポジトリセクション
   - 変更があるリポジトリのみ表示
   - リポジトリ名をセクションヘッダーとして表示
3. ファイルセクション
   - ファイルパスをヘッダーに表示
   - 折りたたみ可能（`DisclosureGroup` など）
   - デフォルトは展開状態
4. side-by-side diff ビュー
   - 左: 変更前（削除行は赤系の背景）
   - 右: 変更後（追加行は緑系の背景）
   - 行番号を左端に表示
   - 等幅フォント（`SF Mono` または `Menlo`）
   - GitHub Dark のカラースキーム:
     - 背景: `#0d1117`
     - 削除行背景: `rgba(248, 81, 73, 0.15)`
     - 追加行背景: `rgba(63, 185, 80, 0.15)`
     - 削除テキスト: `#ffa198`
     - 追加テキスト: `#7ee787`
     - 通常テキスト: `#e6edf3`
5. 未ステージとステージ済みの区別
   - ファイルヘッダーに「Unstaged」「Staged」のラベルを表示するなどして区別

### フェーズ 5: 表示タイミングの統合

**ゴール:** ショートカットで表示するたびに最新の diff が読み込まれる状態

1. パネルが表示されるタイミングで diff を再取得
2. 読み込み中の表示（スピナーなど簡易的なもの）
3. エラー時の表示（git が見つからない、パスが無効など）

## プロジェクト構成（想定）

```
DiffViewer/
├── DiffViewerApp.swift          # アプリエントリポイント、MenuBarExtra
├── AppDelegate.swift            # NSPanel の管理、ショートカット登録
├── FloatingPanel.swift          # NSPanel サブクラス
├── Models/
│   ├── Config.swift             # 設定ファイルのモデル
│   ├── DiffModels.swift         # Repository, FileDiff, DiffHunk, DiffLine
├── Services/
│   ├── ConfigService.swift      # 設定ファイルの読み込み
│   ├── GitService.swift         # git diff の実行とパース
├── Views/
│   ├── ContentView.swift        # メインビュー（リポジトリ一覧）
│   ├── RepositorySection.swift  # リポジトリセクション
│   ├── FileDiffView.swift       # ファイル単位の diff 表示
│   ├── SideBySideDiffView.swift # side-by-side diff ビュー
│   ├── EmptyStateView.swift     # 変更なし表示
├── Theme/
│   └── Colors.swift             # GitHub Dark カラー定義
```

## 依存ライブラリ

| ライブラリ | 用途 | 追加方法 |
|---|---|---|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | グローバルショートカット | Swift Package Manager |

## 注意点

- App Sandbox を無効にする必要がある（任意のパスで `git` コマンドを実行するため）
- アクセシビリティ権限は KeyboardShortcuts ライブラリを使う場合は不要（Carbon API ベースのため）
- `git` コマンドは `/usr/bin/git`（Xcode Command Line Tools に含まれる）を使用
