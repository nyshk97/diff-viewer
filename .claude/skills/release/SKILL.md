---
name: release
description: Build, archive, and release a new version of DiffViewer. Use when asked to release, publish, ship, or create a new version. Also use when the user says "リリース", "リリースして", "新バージョン", or "Homebrew更新".
---

# リリース

DiffViewer の新バージョンをビルドし、GitHub Release を作成し、Homebrew Cask を更新する。

**ビルドと公開は `scripts/release.sh`（= `mise run release <version>`）に集約されている。**
`xcodebuild` や `gh release create` を直接叩く手順をここに書き写さないこと。
書き写すと署名・notarize・配布 ZIP の検証を通らない経路ができ、未署名のアプリが公開される
（実際にこのファイルがその状態だった）。

## 手順

1. **バージョン番号を決める**
   - `$ARGUMENTS` にバージョンが指定されていればそれを使う
   - 指定がなければ、現在のバージョンを確認して次のバージョンをユーザーに提案する
   - 現在のバージョン確認: `gh release list --repo nyshk97/diff-viewer --limit 1`

2. **Xcode プロジェクトのバージョンを更新してコミットする**
   - `DiffViewer/DiffViewer.xcodeproj/project.pbxproj` の `MARKETING_VERSION` を新しいバージョンに変更する
   - `release.sh` はここを自動で更新しない。アプリ内バージョンとタグが食い違うと
     公開直前のチェックで止まる

3. **ビルドして公開する**
   ```bash
   mise run release <version>
   ```
   このタスクが以下を全部行う。**実行すると即公開される。**
   - 事前チェック（gh 認証 / タグ・リリースの重複をリモートに問い合わせ）
   - Release archive → export
   - Developer ID での再署名（Hardened Runtime + secure timestamp、get-task-allow 除去）
   - notarize → staple
   - 配布 ZIP を展開しての検証（`codesign --verify --deep --strict` / `stapler validate` /
     `spctl --assess` が `Notarized Developer ID`）
   - アプリ内バージョンとタグの一致確認
   - GitHub Release の作成

4. **Homebrew Cask を更新**
   - `release.sh` が出力した SHA256 を使う
   - `/opt/homebrew/Library/Taps/nyshk97/homebrew-tap/Casks/diff-viewer.rb` の `version` と `sha256` を更新する
   - homebrew-tap リポジトリにコミット & プッシュする

5. **結果を報告**
   - GitHub Release の URL を表示する
   - `brew upgrade nyshk97/tap/diff-viewer` で更新可能であることを伝える

## ルール

- ビルド前に未コミットの変更がないか確認する。あればユーザーに報告して先にコミットを促す
- ビルドが失敗した場合はエラー内容を表示して中断する
- **notarize は数分かかり、keychain の資格情報を使う。画面がロックされていると
  「プロファイルが無い」で落ちる**ので、リリース本番はユーザーの Terminal から実行してもらう
- 署名まわりだけ触ったときの自走確認は `mise run build:sign-only`（notarize を飛ばす）
