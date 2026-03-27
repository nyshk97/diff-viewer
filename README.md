# DiffViewer

複数のローカル Git リポジトリの差分をまとめて確認できる macOS アプリ。
グローバルショートカット（`Cmd + Ctrl + D`）でいつでも呼び出せるランチャー型の diff ビューア。

## インストール

```
brew install nyshk97/tap/diff-viewer
```

## セットアップ

監視したいリポジトリのパスを設定ファイルに記述する。

```
mkdir -p ~/.config/diff-viewer
```

```json
// ~/.config/diff-viewer/config.json
{
  "repositories": [
    "/Users/you/project-a",
    "/Users/you/project-b"
  ]
}
```

## 使い方

1. アプリを起動する（メニューバーに常駐）
2. `Cmd + Ctrl + D` でパネルを表示
3. もう一度 `Cmd + Ctrl + D` で閉じる
