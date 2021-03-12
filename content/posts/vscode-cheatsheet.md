---
title: "Visual Studio Code Cheatsheet"
date: 2020-12-23T02:12:12+09:00
tags: ["vscode", "shortcut", "cheetsheet", "typescript", "go"]
---

# ショートカット

何回やっても忘れるのでまとめておく。

## コマンドパレットを開く

```
Shift + Command + P
```

- これが開ければ後のショートカットキーは調べられる。
- コマンドパレットは初期状態で `>` が入力されているが、消すとファイル検索ができる。

## Markdown のプレビュー

```
Command + K => V
```

- `Shift + Command + V` で開くとタブで開いてしまう。横に開くのが良い

## 設定を開く

```
Command + ,
```

- Configurations かと思ったけど英名は Settings。

# 設定について

## プロジェクト固有の設定

プロジェクト（ワークスペース）の `.vscode/settings.json` にプロジェクト固有のファイルを置くことができる。

```
Project Root/
`- .vscode/
   `- settings.json
```

- 設定を開くと User / Workspace のタブがあるが、Workspace のほうをいじるとこのファイルが変更されるという仕組み。
- もちろんこっちが優先。

# 環境構築

## 目的

- Go
- TypeScript
- UML(Plantuml)

## プラグイン

| プラグイン名              | 説明                                                                                                              |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Go                        | Go の公式プラグイン。                                                                                             |
| Draw.io Integration       | Draw.io を VSCode 内で動かすプラグイン。                                                                          |
| Paste Image               | 画像を Paste すると 指定したディレクトリに画像を保存しつつ Markdown 形式 で入力をしてくれる。まだ使いこなせてない |
| Prettier - Code formatter | いくつかの言語に対応している Prettier.                                                                            |
| vscode-proto3             | Protocol Buffer のプラグイン。色々な機能があるけど単純に Formatter として使っている。                             |

## 関連する話

### clang-format

Protocol Buffer のファイルを vscode-proto3 で formatter するためには clang-format が必要。

```
brew install clang-format
```

## settings.json

```
{
  //------------------
  // ファイルに関する設定
  //------------------
  // ファイルの自動保存
  "files.autoSave": "afterDelay",

  //------------------
  // エディタの設定
  //------------------
  // フォント。 1:2 じゃないと生きていけない
  // https://qiita.com/tawara_/items/374f3ca0a386fab8b305
  "editor.fontFamily": "HackGenNerd Console",
  // 元のファイルのインデントを気にせず設定を優先する
  "editor.detectIndentation": false,
  // ホワイトスペースの可視化
  "editor.renderWhitespace": "boundary",
  // フォーマットするタイミング
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.formatOnType": true,
  // デフォルトで使われる Formatter
  "editor.defaultFormatter": "esbenp.prettier-vscode",

  // ここから Go の設定
  "go.useLanguageServer": true,
  "go.languageServerExperimentalFeatures": {
    "diagnostics": true,
    "documentLink": true
  },
  "[go]": {
    // Go のときの default formatter は golang.go に変更する
    "editor.defaultFormatter": "golang.go"
  },

  // ここから Protocol Buffer の設定
  "[proto3]": {
    "editor.defaultFormatter": "zxh404.vscode-proto3"
  },
}
```
