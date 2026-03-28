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

## ~~フェーズ 1: プロジェクト作成とランチャーモードの土台~~ ✅ 完了

## ~~フェーズ 2: 設定ファイルの読み込み~~ ✅ 完了

## ~~フェーズ 3: Git diff の取得とパース~~ ✅ 完了

## ~~フェーズ 4: diff 表示 UI~~ ✅ 完了

## ~~フェーズ 5: 表示タイミングの統合~~ ✅ 完了

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
