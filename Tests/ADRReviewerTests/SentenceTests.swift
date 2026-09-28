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

    @Test func emptyDocumentHasNoSentences() {
        #expect(sentences("").isEmpty)
        #expect(sentences("# 見出しだけ").isEmpty)
    }
}
