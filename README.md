cmd-eikana
===

![Build](https://github.com/glyzinie/cmd-eikana/actions/workflows/build.yml/badge.svg)
![License](https://img.shields.io/github/license/glyzinie/cmd-eikana)
![Platform](https://img.shields.io/badge/platform-macOS%2026.0%2B-blue)

This is a fork of [iMasanari/cmd-eikana](https://github.com/iMasanari/cmd-eikana) for Apple Silicon Macs.

左右のコマンドキーを単体で押した時に英数/かなを切り替えるアプリです。
設定をいじることでキーリマップアプリとしても利用できます。

## Fork版について

このリポジトリは [iMasanari](https://github.com/iMasanari) 氏による [オリジナル版](https://github.com/iMasanari/cmd-eikana) のフォークにさらに変更を加えたものです。

### オリジナル版との違い
- Apple Silicon (arm64) ネイティブ専用ビルド
- 最小動作要件: macOS 26.0 以降
- Swift 6.0 / Xcode 26 系ツールチェーン
- ログイン項目の登録に最新の ServiceManagement API (`SMAppService`) を使用
- Bundle ID: `io.github.glyzinie.cmd-eikana`

## オリジナル版からの移行

オリジナル版（iMasanari/cmd-eikana）から移行する場合、Bundle IDが異なるためアクセシビリティの設定が競合することがあります。

1. オリジナル版のcmd-eikanaを終了
2. システム設定 →「プライバシーとセキュリティ」→「アクセシビリティ」を開く
3. 古いcmd-eikanaのエントリを削除（-ボタン）
4. 本フォーク版を起動し、新しくアクセシビリティを許可

## 終了方法

右上のステータスバーにある「⌘」アイコンを開き、「Quit」を選びます。

## アンインストール方法

cmd-eikana.appをゴミ箱に入れてください。
また、設定ファイルが`~/Library/Preferences/io.github.glyzinie.cmd-eikana.plist`にあります。
綺麗さっぱり消したいという場合はこちらもゴミ箱に入れてください。

## 動作確認環境

- macOS 26 以降 (Apple Silicon)

## ビルド方法

```bash
xcodebuild -project "cmd-eikana.xcodeproj" -scheme "cmd-eikana" \
  -configuration Release -destination 'platform=macOS,arch=arm64' clean build
```

**注意:** ソースからビルドした場合は開発署名となるため、初回起動時にGatekeeperによってブロックされます。右クリック（またはControl+クリック）→「開く」で起動してください。

## Credits

- Original Author: [iMasanari](https://github.com/iMasanari)
- Fork Maintainer: [dominion525](https://github.com/dominion525)

## ライセンス

MIT License

- Copyright (c) 2016 iMasanari
- Copyright (c) 2025 Dominion525
- Copyright (c) 2026 Wis
