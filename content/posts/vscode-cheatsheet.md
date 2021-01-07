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

# 設定

## しておきたい設定

共通部分だけ。

```
{
  "files.autoSave": "afterDelay",
  "editor.detectIndentation": false,
  "editor.renderWhitespace": "boundary",
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.formatOnType": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
}
```

## プロジェクト固有の設定

プロジェクト（ワークスペース）の `.vscode/settings.json` にプロジェクト固有のファイルを置くことができる。

```
Project Root/
`- .vscode/
   `- settings.json
```

- 設定を開くと User / Workspace のタブがあるが、Workspace のほうをいじるとこのファイルが変更されるという仕組み。
- もちろんこっちが優先。

# 言語毎の設定

## Go

### プラグイン

| プラグイン名 | 説明                                                   |
| ------------ | ------------------------------------------------------ |
| Go           | Go Team at Google が提供している。これ入れれば終わり。 |

### 設定

```json
{
  // ここから Go の設定
  // LSP を利用する設定
  "go.useLanguageServer": true,
  "go.languageServerExperimentalFeatures": {
    "diagnostics": true,
    "documentLink": true
  },
  // Go のときの Formatter は golang.go に変更する
  "[go]": {
    "editor.defaultFormatter": "golang.go"
  }
}
```

## TypeScript
