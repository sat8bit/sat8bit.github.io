---
title: "Hugo と Github Pages でブログを作る"
date: 2021-02-09T23:23:16+09:00
draft: false
---

# 概要

Hugo と Github Pages、及び Github Actions を使ってブログを作る。

# 各仕組みの説明

## Hugo について

https://gohugo.io/

> The world’s fastest framework for building websites

大雑把に言うと、静的コンテンツを生成する仕組み。ブログ形式以外にも色々できる。

今回はこれを使って Markdown のテキストファイルからブログを作る。

## Github Pages について

https://docs.github.com/ja/github/working-with-github-pages/about-github-pages

> GitHub Pages を使って、あなたやあなたの Organization、またはあなたのプロジェクトについてのウェブサイトを、GitHub リポジトリから直接ホストできます。

大雑把に言うと、Github に push した静的なウェブコンテンツ（html, js, css, img, ...）を、ホストする仕組み。

ホスティングのされ方は `https://<account>.github.io` か、 `https://<account>.github.io/<repository>/`。  
また、独自ドメインも設定できる。

`https://<account>.github.io` を使うためには、`<account>.github.io` というリポジトリを作成して、Pages の設定を行えば良い。  
上記の名前以外のリポジトリは `https://<account>.github.io/<repository>` にホスティングされる。

今回は前者の `https://<account>.github.io` で構築する。

## Github Actions について

https://github.co.jp/features/actions

> GitHub Actions を使用すると、ワールドクラスの CI / CD ですべてのソフトウェアワークフローを簡単に自動化できます。 GitHub から直接コードをビルド、テスト、デプロイでき、コードレビュー、ブランチ管理、問題のトリアージを希望どおりに機能させます。

大雑把に言うと、Github への push や merge、レビューなどのイベントに対してなにか処理（ワークフロー）を実行する仕組み。

今回は、Markdown ファイルを push したら Hugo で静的コンテンツを生成して push するところまで、ワークフローで行う。  
既に先駆者の方がそれ用の Action を作成してくださっていて、使うだけなので難しいことはない。

# localhost で Hugo !

## セットアップ

まずは、[Quick start](https://gohugo.io/getting-started/quick-start/) に沿ってインストールを行う。

```
$ brew install hugo
```

さっそくサイトを構築する。  
今回ホスティングの関係で、サイト名は各人で固定になるはず。

```
$ hugo new site sat8bit.github.io
$ cd sat8bit.github.io
$ git init .
```

hugo はデフォルトで theme が入っていないので、このままだと動かない。以下のサイトからテンプレートを選ぶ。

https://themes.gohugo.io/

今回は Quick start に沿って [Ananke theme](https://themes.gohugo.io/gohugo-theme-ananke/) を利用する。

```
$ git submodule add https://github.com/budparr/gohugo-theme-ananke.git themes/ananke
```

theme を反映するためには config.toml に記述する必要があるので、以下を追加する。  
名称は `themes` 配下のディレクトリ名。

```diff
+theme = "ananke"
 baseURL = "http://example.org/"
 languageCode = "en-us"
 title = "My New Hugo Site"
```

ここまで終わったら、local で起動してみる。

```
$ hugo serve
```

上記コマンドで出力された URL にアクセスすると、以下の画面が表示される。

![](/images/2021-02-09-23-44-24.png)

## ブログを追加する

Hugo は `hugo new <category>/<filename>.<filetype>` というコマンドでコンテンツを生成できる。  
またデフォルトでは `posts` カテゴリがトップページにリスティングされる。

なので、例えば hello-world という記事を書くときはこんなコマンドになる。

```
$ hugo new posts/hello-world.md
```

こんなファイルが生成される。

```
$ cat content/posts/hello-world.md
---
title: "Hello World"
date: 2021-02-09T23:50:59+09:00
draft: true
---
```

`---` で挟まれた部分はメタ情報になるので、その下に記事を書いていく。

```diff
 draft: true
 ---

+# Hello! World.
+
+こんにちは、世界。
```

この状態で `hugo serve` を実行しても、記事は表示されない。メタ情報の `draft` が `true` になっていて、下書き扱いになっているからである。

下書きを確認するために以下のコマンドで hugo を起動する。

```
hugo serve -D
```

![](/images/2021-02-09-23-56-41.png)

表示される。

つまり、記事を書いて、ローカルでの確認が終わったらファイル側のメタ情報の `draft` を削除するか、`false` にすれば公開、というサイクルになる。

## 静的コンテンツの生成

今回は Github Actions でやるので、手でやることはないが一応触っておいたほうが良いと思う。

以下のコマンドを実行すると、 `public` 配下に静的コンテンツが生成される。

```
$ hugo
```

確認。

```
public
├── 404.html
├── ananke
│   └── dist
│       └── main.css_5c99d70a7725bacd4c701e995b969fea.css
├── categories
│   ├── index.html
│   └── index.xml
├── images
│   └── gohugo-default-sample-hero-image.jpg
├── index.html
├── index.xml
├── sitemap.xml
└── tags
    ├── index.html
    └── index.xml
```

このディレクトリをホスティングすることで、ブログを公開する。

なお、今回はお試しなので生成されたファイルは削除する。

```
$ rm -rf public
```

# Github Actions で 静的コンテンツを生成して Push する

既に Actions があるので、これを使って設定を行っていく。

https://github.com/peaceiris/actions-hugo

と言っても、上の README を参考に設定していけば動く。

```yaml
name: github pages

on:
  push:
    branches:
      - master # Set a branch to deploy

jobs:
  deploy:
    runs-on: ubuntu-18.04
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: true # Fetch Hugo themes (true OR recursive)
          fetch-depth: 0 # Fetch all history for .GitInfo and .Lastmod

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: "0.79.1"
          # extended: true

      - name: Build
        run: hugo

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

上記のファイルを `.github/workflows/gh-pages.yml` とかの名前で保存しておしまい。

`gh-pages.yml` のファイル名は変更してよいが、`.github/workflows` は Actions のファイルの置き場所なので変更しない。

Github に push したら、Github 上の Actions タブで実際に動作したか確認する。

![](/images/2021-02-15-01-05-39.png)

こんな感じで緑のチェックになってれば OK。

gh-pages というブランチに push されているので、確認する。

![](/images/2021-02-15-01-06-23.png)

# Github Pages を設定して公開する

最後に公開する設定を行う。

Settings タブを開くと Options が選択された状態で開くので、下部の `GitHub Pages` で Source を `gh-pages` に変更する。

公開するディレクトリだけを push しているので、 / (root) を選択して `Save` する。

![](/images/2021-02-15-01-08-54.png)

公開設定をしても、暫くは表示されないのでちょっとまってから以下の URL にアクセスする。

```
https://<account名>.github.io
```

設定画面にリンクが表示されるはずなので、そこを押すほうが確実。

上記で設定が整ったら、あとは Markdown でメモとか書いて適当に Push すれば良さそうです。
