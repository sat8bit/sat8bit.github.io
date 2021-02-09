---
title: "Firebase Tutorial"
date: 2021-02-09T22:07:53+09:00
draft: false
---

# 概要

Firebase を使って色々やるチュートリアル。

> Firebase は、高品質のアプリを迅速に開発できる Google のモバイル プラットフォームで、ビジネスの成長に役立ちます。

# 事前準備：プロジェクトの作成と開発の準備

## プロジェクトの作成

トップページから、プロジェクトを作る。

http://console.firebase.google.com/

愛着が湧く名前が良いと思う。今回は `matomelien` とした。まとめサイト関連のサービス作るの好き。

## リポジトリの整備

`git` のリポジトリを整備していく。

Firebase では、一つのリポジトリに Firebase の各サービスに対するソースコードをまとめる構成がとれそうなので、まとめる。

```
ROOT/
├── functions  // Firebase Functions
...
└── public     // Firebase Hosting
```

プロジェクト名でディレクトリを作って `git init .` しておく。

```
$ mkdir matomelien
$ cd matomelien
$ git init .
```

以降はこのディレクトリをルートとする。

## Firebase CLI のインストール

node 及び npm のインストール手順はここでは割愛する。

Global に firebase-tools をインストールしておく。

```
$ npm install -g firebase-tools
```

以降は以下のバージョンを使って作業をしている。

```bash
$ node --version
v14.14.0
$ npm --version
6.14.8
$ firebase --version
9.3.0
```

## プロジェクトの初期化

チュートリアルに沿って以下のコマンドでログインする。

```
$ firebase login
```

# Functions で API を作る

今回は TypeScript を使う前提で進める。

ドキュメント：https://firebase.google.com/docs/functions/

## Functions の初期化

以下のコマンドを実行する。

```
firebase init functions
```

すると、まずどうやってプロジェクトを作成するか聞かれる。今回は既に `matomelien` を作成済なので、`Use an exists project` を選択。

```
? Please select an option:
❯ Use an existing project
  Create a new project
  Add Firebase to an existing Google Cloud Platform project
  Don't set up a default project
```

ログインしているユーザに紐づく Project の一覧を出してくれるので、選択。上は typo したやつ。

```
? Select a default Firebase project for this directory: (Use arrow keys)
  matomelian (matomelian)
❯ matomelien (matomelien)
```

言語選び。TypeScript を選択。

```
? What language would you like to use to write Cloud Functions?
  JavaScript
❯ TypeScript
```

ESLint は私の場合は入れておく。

```
? Do you want to use ESLint to catch probable bugs and enforce style? (Y/n)
```

`npm install` していい？と聞かれるのでまぁそのまま OK。

```
✔  Wrote functions/package.json
✔  Wrote functions/.eslintrc.js
✔  Wrote functions/tsconfig.json
✔  Wrote functions/tsconfig.dev.json
✔  Wrote functions/src/index.ts
✔  Wrote functions/.gitignore
? Do you want to install dependencies with npm now? (Y/n)
```

完了すると、雛形を一通り作成してくれる。これで初期化は完了。

## Http Request で起動する Hello World! の local 実行と Deploy

functions/src/index.ts で export した function が deploy される。

`functions/src/index.ts` にコメントアウトされた雛形があるので、このコメントアウトを外してみる。

```diff
 import * as functions from "firebase-functions";

-// // Start writing Firebase Functions
-// // https://firebase.google.com/docs/functions/typescript
-//
-// export const helloWorld = functions.https.onRequest((request, response) => {
-//   functions.logger.info("Hello logs!", {structuredData: true});
-//   response.send("Hello from Firebase!");
-// });
+// Start writing Firebase Functions
+// https://firebase.google.com/docs/functions/typescript
+
+export const helloWorld = functions.https.onRequest((request, response) => {
+  functions.logger.info("Hello logs!", {structuredData: true});
+  response.send("Hello from Firebase!");
+});
```

localhost で実行する前に TypeScript だと build してトランスパイルする必要があるので、行う。

https://firebase.google.com/docs/functions/typescript?hl=ja#emulating_typescript_functions

```
$ cd functions
$ npm run build
```

成功したら、以下のコマンドを使って emulator を起動する。

```
$ firebase emulators:start
（略）
✔  functions[helloWorld]: http function initialized (http://localhost:5001/matomelien/us-central1/helloWorld).
（略）
```

上の表にある URL にアクセスする。

![](/images/2021-02-09-22-47-04.png)

動いてることが確認できたので、実際に本番にデプロイする。  
ここでエラーが。有料プランにあげてって言われている。前無料でできたのにな・・・

```
$ firebase deploy --only functions
（略）
Error: Your project matomelien must be on the Blaze (pay-as-you-go) plan to complete this command. Reqthis command. Required API cloudbuild.googleapis.com can't be enabled until the upgras cograde, visit uired API cloudbuild.googleapis.com cde is complete. To upgrade, visit the following URL:

https://console.firebase.google.com/project/matomelien/usage/details
```

調べたら元々 `Node8` のランタイムを無料プランで提供してたけど、それが去年非推奨になって `Node10` 以降でしか使えなくなった。  
`Node10` 以降は Blaze（従量課金プラン）でしか提供していない模様。

https://qiita.com/azukiazusa/items/edd6ca9cba2d48c4c3e2

Pricing はここ。

https://firebase.google.com/pricing