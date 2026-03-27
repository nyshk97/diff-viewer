# Diff Viewer 実装計画

> **凡例:** 手動作業が必要なステップには 🔧 を付けている（Xcode の GUI 操作、インストール作業など）

## ~~フェーズ 0: 開発環境の準備~~ ✅ 完了

~~**ゴール:** Xcode でアプリをビルド＆実行できる状態~~

1. ~~🔧 **Xcode をインストール**~~ ✅
2. ~~🔧 **Xcode Command Line Tools を確認**~~ ✅

### Xcode の基本操作（初めての人向け）

- **プロジェクトを開く:** `.xcodeproj` ファイルをダブルクリック、または Xcode の File → Open
- **ビルド＆実行:** `Cmd + R`（アプリがビルドされて起動する）
- **ビルドだけ:** `Cmd + B`（実行はしない）
- **停止:** `Cmd + .`（実行中のアプリを止める）
- **ファイル編集:** 左のファイルツリーからファイルを選んでエディタで編集
- **エラー確認:** ビルドに失敗すると左のナビゲーターにエラーが表示される
- **コンソール出力:** 画面下部のデバッグエリアに `print()` の出力が表示される（表示されていなければ `Cmd + Shift + C`）

## フェーズ 1: プロジェクト作成とランチャーモードの土台

**ゴール:** ショートカットキーで空のウィンドウがトグル表示される状態

1. ~~🔧 **Xcode でプロジェクトを新規作成**~~ ✅
2. ~~🔧 **App Sandbox を無効にする**~~ ✅
3. ~~🔧 **KeyboardShortcuts ライブラリを追加**~~ ✅
4. `Info.plist` に `LSUIElement = YES` を設定（Dock に表示しない）
5. `MenuBarExtra` でメニューバーにアイコンを表示（終了ボタンのみ）
6. `NSPanel` のサブクラスを作成
   - `styleMask`: `.nonactivatingPanel`, `.titled`, `.fullSizeContentView`
   - `isFloatingPanel = true`
   - `level = .floating`
   - `collectionBehavior`: `.fullScreenAuxiliary`（フルスクリーン上でも表示可能に）
   - `titleVisibility = .hidden`, `titlebarAppearsTransparent = true`
   - `hidesOnDeactivate = false`（ショートカットでのみ閉じる）
   - `isReleasedWhenClosed = false`
7. ウィンドウサイズを画面の 80% に設定し、中央に配置
8. グローバルショートカット `Cmd + Ctrl + D` でパネルをトグル表示
9. パネル内に SwiftUI ビューを `NSHostingView` でホスト
10. 🔧 **動作確認:** Xcode で `Cmd + R` を押してビルド＆実行し、`Cmd + Ctrl + D` でウィンドウが出ることを確認

### フェーズ 2: 設定ファイルの読み込み

**ゴール:** `~/.config/diff-viewer/config.json` からリポジトリ一覧を読める状態

1. 🔧 **設定ファイルを作成する**
   - ターミナルで `mkdir -p ~/.config/diff-viewer` を実行
   - `~/.config/diff-viewer/config.json` を以下の内容で作成:
     ```json
     {
       "repositories": [
         "/Users/d0ne1s/project-a",
         "/Users/d0ne1s/project-b"
       ]
     }
     ```
   - パスは自分の監視したいリポジトリに書き換える
2. 設定ファイルの JSON 構造を定義
3. `Codable` な構造体で設定をデコード
4. ファイルが存在しない場合のエラーハンドリング

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

## 手動作業まとめ

全フェーズを通して、手動作業（🔧）が必要な箇所の一覧:

| タイミング | 作業内容 |
|---|---|
| フェーズ 0-1 | Xcode を Mac App Store からインストール（約30GB） |
| フェーズ 0-2 | Xcode Command Line Tools の確認/インストール |
| フェーズ 1-1 | Xcode でプロジェクトを新規作成 |
| フェーズ 1-2 | Xcode で App Sandbox を無効化 |
| フェーズ 1-3 | Xcode で KeyboardShortcuts パッケージを追加 |
| フェーズ 1-10 | Xcode でビルド＆実行して動作確認 |
| フェーズ 2-1 | 設定ファイル `~/.config/diff-viewer/config.json` を作成 |

それ以外のステップは全てコード変更のみで完結する。

## 注意点

- App Sandbox を無効にする必要がある（任意のパスで `git` コマンドを実行するため）
- アクセシビリティ権限は KeyboardShortcuts ライブラリを使う場合は不要（Carbon API ベースのため）
- `git` コマンドは `/usr/bin/git`（Xcode Command Line Tools に含まれる）を使用
