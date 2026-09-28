import Testing
@testable import ADRReviewer

@Suite struct SentenceTests {
    private func sentences(_ content: String) -> [Sentence] {
        Document(path: "adr.md", content: content).sentences
    }

    @Test func splitsOnJapaneseTerminators() {
        #expect(sentences("一つ目。二つ目！三つ目？四つ目").map(\.text) == ["一つ目。", "二つ目！", "三つ目？", "四つ目"])
    }

    @Test func keepsRunsOfTerminatorsAndClosingBrackets() {
        #expect(sentences("本当！？「そうだ。」次。").map(\.text) == ["本当！？", "「そうだ。」", "次。"])
    }

    @Test func asciiPeriodIsNotATerminator() {
        #expect(sentences("バージョン1.2を使う。e.g. これ。").map(\.text) == ["バージョン1.2を使う。", "e.g.これ。"])
    }

    @Test func softBreaksJoinLinesWithoutSpaceAndRemoveWhitespace() {
        #expect(sentences("一行目に\n続く 文。").map(\.text) == ["一行目に続く文。"])
    }

    @Test func lineIsWhereTheSentenceStarts() {
        let content = """
        # 見出し

        一つ目。二つ目は
        次の行に続く。三つ目。

        - 四つ目。
        """
        #expect(sentences(content).map(\.line) == [3, 3, 4, 6])
    }

    @Test func skipsHeadingsCodeBlocksTablesAndHTML() {
        let content = """
        # 見出し。これは文ではない。

        ```
        コード。これも違う。
        ```

        | 列 | 値 |
        |---|---|
        | セル。 | x |

        <div>HTML。</div>

        地の文。
        """
        #expect(sentences(content).map(\.text) == ["地の文。"])
    }

    @Test func includesListItemsAndBlockQuotes() {
        let content = """
        - 項目。
          - ネスト。
        > 引用。
        """
        #expect(sentences(content).map(\.text) == ["項目。", "ネスト。", "引用。"])
    }

    @Test func inlineCodeCountsAndLinkURLsDoNot() {
        let content = "`swift build` を [公式ドキュメント](https://example.com/very/long/path) の通りに **実行** する。"
        #expect(sentences(content).map(\.text) == ["swiftbuildを公式ドキュメントの通りに実行する。"])
    }

    @Test func containsLinkIsSetForSentencesWithLinkOrImage() {
        let content = "リンク無し。[調査](https://example.com)を参照。![図](a.png)の通り。"
        #expect(sentences(content).map(\.containsLink) == [false, true, true])
    }

    @Test func containsMatchesIgnoringWhitespaceAndCase() {
        let sentence = Sentence(text: "WeadoptitsothatbuildsareFast.", line: 1)
        #expect(sentence.contains("so that"))
        #expect(sentence.contains("Builds Are"))
        #expect(!sentence.contains("slow"))
        #expect(!sentence.contains(" "))
    }

    @Test(arguments: [
        "以下の2つの選択肢を検討した。", "3案を比較した。", "第2の理由。", "4観点で評価した。", "5番目の案。", "２つの案。",
    ])
    func countingNumbersAreNotEvidence(text: String) {
        #expect(!Sentence(text: text.filter { !$0.isWhitespace }, line: 1).hasBacking)
    }

    @Test(arguments: [
        "ビルドが10分かかる。", "30%速い。", "採用企業は300社。", "2025年時点の調査。", "5人のチーム。", "v2に移行。", "3倍速い。",
    ])
    func measurementsAreEvidence(text: String) {
        #expect(Sentence(text: text, line: 1).hasEvidentialNumber)
    }

    @Test func hasBackingDetectsLinksNumbersAndSourceMarkers() {
        #expect(Sentence(text: "速い。", line: 1).hasBacking == false)
        #expect(Sentence(text: "速い。", line: 1, containsLink: true).hasBacking)
        #expect(Sentence(text: "30%速い。", line: 1).hasBacking)
        #expect(Sentence(text: "３０％速い。", line: 1).hasBacking)
        #expect(Sentence(text: "計測では速い。", line: 1).hasBacking)
        #expect(Sentence(text: "参照:社内資料。", line: 1).hasBacking)
    }

    @Test func emptyDocumentHasNoSentences() {
        #expect(sentences("").isEmpty)
        #expect(sentences("# 見出しだけ").isEmpty)
    }
}
