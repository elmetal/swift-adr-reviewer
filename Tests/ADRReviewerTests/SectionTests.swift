import Testing
@testable import ADRReviewer

@Suite struct SectionTests {
    private func sections(_ content: String) -> [Section] {
        Document(path: "adr.md", content: content).sections
    }

    @Test func bodyRunsUntilNextHeadingOfSameOrHigherLevel() {
        let content = """
        # タイトル
        ## 背景
        背景の本文
        ### 詳細
        詳細の本文
        ## 決定
        決定の本文
        """
        let result = sections(content)
        #expect(result.map(\.heading.title) == ["タイトル", "背景", "詳細", "決定"])
        #expect(result[0].bodyLines == ["## 背景", "背景の本文", "### 詳細", "詳細の本文", "## 決定", "決定の本文"])
        #expect(result[1].bodyLines == ["背景の本文", "### 詳細", "詳細の本文"])
        #expect(result[2].bodyLines == ["詳細の本文"])
        #expect(result[3].bodyLines == ["決定の本文"])
    }

    @Test func lastSectionRunsToEndOfDocument() {
        let result = sections("## 結果\n一行目\n\n二行目\n")
        #expect(result.count == 1)
        #expect(result[0].bodyLines == ["一行目", "", "二行目", ""])
    }

    @Test func adjacentHeadingsGiveEmptyBody() {
        let result = sections("## 背景\n## 決定\n本文")
        #expect(result[0].bodyLines.isEmpty)
        #expect(result[0].isEmpty)
        #expect(!result[1].isEmpty)
    }

    @Test func whitespaceOnlyBodyIsEmpty() {
        #expect(sections("## 背景\n\n  \t\n")[0].isEmpty)
    }

    @Test func codeBlockCountsAsBody() {
        #expect(!sections("## 背景\n```\n```\n")[0].isEmpty)
    }

    @Test func codeBlockLinesAreExcludedFromBodyLinesOutsideCodeBlocks() {
        let content = """
        ## 背景
        前
        ```
        - 中
        ```
        後
        ## 決定
        本文
        """
        let section = sections(content)[0]
        #expect(section.codeBlockLines == [3, 4, 5])
        #expect(section.bodyLinesOutsideCodeBlocks.map(\.line) == [2, 6])
        #expect(section.bodyLinesOutsideCodeBlocks.map(\.text) == ["前", "後"])
    }

    @Test func indentedCodeBlockIsExcluded() {
        let content = "## 背景\n前\n\n    - 中(インデントコード)\n\n後\n"
        let section = sections(content)[0]
        // cmark extends an indented code block's range over the blank line that follows it.
        #expect(section.bodyLinesOutsideCodeBlocks.map(\.text) == ["前", "", "後", ""])
    }

    @Test func noHeadingsGivesNoSections() {
        #expect(sections("本文だけ").isEmpty)
    }
}
