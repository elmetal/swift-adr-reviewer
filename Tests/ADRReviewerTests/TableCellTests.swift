import Testing
@testable import ADRReviewer

@Suite struct TableCellTests {
    @Test func collectsCellTextWithLines() {
        let content = """
        ## 評価
        | 観点 | 案A |
        |---|---|
        | 速度 | **◎** 速い |
        | コスト | `低` |
        ## 次
        本文
        """
        let document = Document(path: "adr.md", content: content)
        #expect(document.tableCells.map(\.text) == ["観点", "案A", "速度", "◎ 速い", "コスト", "低"])
        #expect(document.tableCells.map(\.line) == [2, 2, 4, 4, 5, 5])
        #expect(document.tableCells(in: document.sections[0]).count == 6)
        #expect(document.tableCells(in: document.sections[1]).isEmpty)
    }

    @Test func noTablesGivesNoCells() {
        #expect(Document(path: "adr.md", content: "本文だけ").tableCells.isEmpty)
    }
}
