---
layout: default
title: cmd-eikana - Apple Silicon版
---

<div style="display: flex; align-items: center; gap: 16px;">
  <img src="img/icon.png" width="64" height="64" alt="cmd-eikana">
  <h1 style="margin: 0;">cmd-eikana - Apple Silicon版</h1>
</div>

macOSで左右のコマンドキーを単体で押したときに英数/かなを切り替えるユーティリティです。USキーボードでもJISキーボードの「英数」「かな」キーと同様の操作感を実現できます。

本アプリケーションは [iMasanari/cmd-eikana](https://github.com/iMasanari/cmd-eikana) をApple Silicon向けにフォークしたものです。オリジナル版の詳細な説明は[公式サイト](https://ei-kana.appspot.com/)をご覧ください。

---

## 差分の確認

- [オリジナル版との差分](https://github.com/iMasanari/cmd-eikana/compare/master...glyzinie:cmd-eikana:main)
- [dominion525版との差分](https://github.com/dominion525/cmd-eikana/compare/master...glyzinie:cmd-eikana:main)
- [オリジナル版とdominion525版の差分](https://github.com/iMasanari/cmd-eikana/compare/master...dominion525:cmd-eikana:master)

---

## ダウンロード

<div style="text-align: center; margin: 2em 0;">
  <a href="https://github.com/glyzinie/cmd-eikana/releases/latest" style="display: inline-flex; align-items: center; background: #4a90d9; color: white; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-size: 1.1em;">
    Download cmd-eikana-v0.0.1
    <span style="background: #666; color: white; padding: 4px 10px; border-radius: 4px; margin-left: 12px; font-size: 0.85em;">macOS 26.0+ / Apple Silicon</span>
  </a>
  <div style="margin-top: 1em;">
    <a href="https://github.com/glyzinie/cmd-eikana">View project on GitHub</a>
  </div>
</div>

---

## キーバインド

| 入力 | 出力 | 備考 |
|:-----|:-----|:-----|
| 左⌘（単押し） | 英数 | 他のキーと組み合わせない場合 |
| 右⌘（単押し） | かな | 他のキーと組み合わせない場合 |
| ⌘ + 他のキー | 通常動作 | ショートカットとして機能 |

コマンドキーを単独で押して離したときに入力切り替えが発動します。⌘+C や ⌘+V などのショートカットは通常通り使用できます。

---

## クレジット

- オリジナル版: [iMasanari/cmd-eikana](https://github.com/iMasanari/cmd-eikana)
- オリジナル公式サイト: [https://ei-kana.appspot.com/](https://ei-kana.appspot.com/)
- Fork Maintainer: [dominion525](https://github.com/dominion525)
- Fork Maintainer: [Wis (Glyzinie)](https://github.com/glyzinie)

## ライセンス

MIT License

- Copyright (c) 2016 iMasanari
- Copyright (c) 2025 Dominion525
- Copyright (c) 2026 Wis
