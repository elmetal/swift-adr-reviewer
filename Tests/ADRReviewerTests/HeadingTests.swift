import Testing
@testable import ADRReviewer

@Suite struct HeadingTests {
    private func headings(_ content: String) -> [Heading] {
        Document(path: "adr.md", content: content).headings
    }

    @Test func parsesLevelsTitlesAndLines() {
        let content = """
        # タイトル
        本文
        ## 背景
        ###   決定   
        ###### 深い
        """
        #expect(headings(content) == [
            Heading(level: 1, title: "タイトル", line: 1),
            Heading(level: 2, title: "背景", line: 3),
            Heading(level: 3, title: "決定", line: 4),
            Heading(level: 6, title: "深い", line: 5),
        ])
    }

    @Test func ignoresNonHeadings() {
        let content = """
        #ハッシュタグ
        ####### 7個は見出しではない
        普通の行 # 途中のハッシュ
          ## インデントされた見出し
        """
        #expect(headings(content) == [Heading(level: 2, title: "インデントされた見出し", line: 4)])
    }

    @Test func stripsClosingHashes() {
        #expect(headings("## 背景 ##").map(\.title) == ["背景"])
        #expect(headings("## C#").map(\.title) == ["C#"])
        #expect(headings("#").map(\.title) == [""])
    }

    @Test func skipsFencedCodeBlocks() {
        let content = """
        ## 背景
        ```sh
        # これはコメント
        ```
        ~~~
        ## これも無視
        ~~~
        ## 決定
        """
        #expect(headings(content).map(\.title) == ["背景", "決定"])
    }

    @Test func handlesCRLF() {
        #expect(headings("## 背景\r\n## 決定\r\n").map(\.title) == ["背景", "決定"])
    }
}
