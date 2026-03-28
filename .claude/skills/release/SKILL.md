---
name: release
description: Build, archive, and release a new version of DiffViewer. Use when asked to release, publish, ship, or create a new version. Also use when the user says "リリース", "リリースして", "新バージョン", or "Homebrew更新".
---

# リリース

DiffViewer の新バージョンをビルドし、GitHub Release を作成し、Homebrew Cask を更新する。

## 手順

1. **バージョン番号を決める**
   - `$ARGUMENTS` にバージョンが指定されていればそれを使う
   - 指定がなければ、現在のバージョンを確認して次のバージョンをユーザーに提案する
   - 現在のバージョン確認: `gh release list --repo nyshk97/diff-viewer --limit 1`

2. **Xcode プロジェクトのバージョンを更新**
   - `DiffViewer/DiffViewer.xcodeproj/project.pbxproj` の `MARKETING_VERSION` を新しいバージョンに変更する

3. **アプリをビルド**
   ```bash
   cd DiffViewer
   xcodebuild -scheme DiffViewer -configuration Release -archivePath build/DiffViewer.xcarchive archive
   xcodebuild -exportArchive -archivePath build/DiffViewer.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/export
   ```

4. **ZIP を作成**
   ```bash
   cd build/export
   zip -r DiffViewer.zip DiffViewer.app
   ```

5. **GitHub Release を作成**
   ```bash
   gh release create v<version> build/export/DiffViewer.zip --title "v<version>" --repo nyshk97/diff-viewer
   ```

6. **Homebrew Cask を更新**
   - SHA256 を取得: `shasum -a 256 build/export/DiffViewer.zip`
   - `/opt/homebrew/Library/Taps/nyshk97/homebrew-tap/Casks/diff-viewer.rb` の `version` と `sha256` を更新する
   - homebrew-tap リポジトリにコミット & プッシュする

7. **結果を報告**
   - GitHub Release の URL を表示する
   - `brew upgrade diff-viewer` で更新可能であることを伝える

## ルール

- ビルド前に未コミットの変更がないか確認する。あればユーザーに報告して先にコミットを促す
- `ExportOptions.plist` が存在しない場合はエラーにせず、作成する
- ビルドが失敗した場合はエラー内容を表示して中断する
