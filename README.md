# swift-adr-reviewer

A CLI tool written in Swift that reviews the quality of Architecture Decision Records (ADRs) written in Japanese.

日本語で書かれた ADR(Architecture Decision Record)の Markdown ファイルを検査し、構成や文章の問題を指摘する CLI ツールです。

## インストール

Swift 6.3 以降が必要です(macOS または Linux)。

### ソースからビルドする

```sh
git clone https://github.com/elmetal/swift-adr-reviewer.git
cd swift-adr-reviewer
swift build -c release
```

ビルドした実行ファイルを PATH の通った場所に置きます。

```sh
cp .build/release/adr-reviewer /usr/local/bin/
```

### ビルドせずに実行する

リポジトリ内で `swift run` を使えば、インストールせずに試せます。

```sh
swift run adr-reviewer docs/adr/0001-use-swift.md
```

## 使い方

検査したい ADR ファイルを引数に渡します。複数指定できます。

```sh
adr-reviewer docs/adr/0001-use-swift.md
adr-reviewer docs/adr/*.md
```

指摘は 1 行ずつ標準出力に表示されます。

```
docs/adr/0001-use-swift.md: error: 必須セクション「結果」の見出しが見つかりません(認識する見出し: 結果 / 影響 / 帰結 / Consequences)。 [required-sections]
docs/adr/0001-use-swift.md:3: error: セクション「ステータス」に本文がありません。内容を書くか見出しを削除してください。 [empty-section]
docs/adr/0001-use-swift.md:12: warning: 一文が長すぎます。141字あります(上限100字)。「このADRではアプリケーション…」を複数の文に分けてください。 [sentence-length]
```

error が 1 件以上あれば終了コードが `1` になるので、CI でマージをブロックする用途に使えます。出力形式や終了コードの詳細は `adr-reviewer --help` を参照してください。

### GitHub Actions で使う

Swift が入った環境(`swift:6.3` コンテナなど)で、このリポジトリをチェックアウトしてビルドします。

```yaml
jobs:
  adr:
    runs-on: ubuntu-latest
    container: swift:6.3
    steps:
      - uses: actions/checkout@v7
      - uses: actions/checkout@v7
        with:
          repository: elmetal/swift-adr-reviewer
          path: .adr-reviewer
      - run: swift build -c release --package-path .adr-reviewer
      - run: .adr-reviewer/.build/release/adr-reviewer docs/adr/*.md
```

## 想定している ADR の構成

Markdown の見出しで次のセクションを持つ ADR を想定しています。見出しの表記は多少ゆれても認識します(後述の「ルール」を参照)。

```markdown
# 1. Swift を採用する

## ステータス

承認済み

## 背景

...

## 決定

...

## 結果

...

## 検討した選択肢

- 案A: ...
- 案B: ...
```

## ルール

| ルール ID | 内容 | 重大度 |
|---|---|---|
| `document-length` | 文書全体の文字数(改行・空白込み)が 5,000 字を超える | warning |
| | 7,000 字を超える | error |
| `required-sections` | 必須セクション(背景・決定・結果)の見出しが無い | error |
| | 推奨セクション(ステータス・検討した選択肢)の見出しが無い | warning |
| `empty-section` | 見出しの下に本文が無いセクションがある | error |
| `status` | ステータスが 提案中 / 承認済み / 却下 / 廃止 / 置き換え済み のいずれでもない | warning |
| | 置き換え済みなのに置き換え先の ADR への参照(番号またはリンク)が無い | warning |
| `alternatives` | 検討した選択肢セクションにリスト項目・小見出しが 2 つ未満で、表も無い | warning |
| `sentence-length` | 地の文の一文が 100 字(空白を除く)を超える | warning |

セクションの見出しは、次の語を含んでいれば認識します(ASCII の大文字小文字は区別しません)。

| セクション | 認識する見出し |
|---|---|
| ステータス | ステータス / 状態 / Status |
| 背景 | 背景 / コンテキスト / 文脈 / 状況 / Context |
| 決定 | 決定 / Decision |
| 結果 | 結果 / 影響 / 帰結 / Consequences |
| 検討した選択肢 | 選択肢 / 代替案 / 候補 / Alternatives / Options / Considered |

ステータスの値は、提案中(Proposed / Draft / 下書き)、承認済み(Accepted / Approved / 承認 / 採用)、却下(Rejected)、廃止(Deprecated / 非推奨)、置き換え済み(Superseded / 置換済み)の表記を認識します。

現時点では閾値やセクション名は固定です。

## 開発

```sh
swift build
swift test
```

ルールは `Sources/ADRReviewer/Rules/` にあり、`Rule` プロトコルに準拠した型を `Reviewer.default` に追加すると有効になります。ルールの説明(`summary`)は `--help` のルール一覧に自動で載ります。

## ライセンス

[MIT](LICENSE)
