import Testing
@testable import ADRReviewer

@Suite struct EmptySectionRuleTests {
    private let rule = EmptySectionRule()

    private func check(_ content: String) -> [Diagnostic] {
        rule.check(Document(path: "adr.md", content: content))
    }

    @Test func filledSectionsReportNothing() {
        let content = """
        # タイトル
        ## 背景
        本文
        ## 決定
        本文
        """
        #expect(check(content).isEmpty)
    }

    @Test func reportsEachEmptySectionWithHeadingLine() {
        let content = """
        # タイトル
        ## 背景

        ## 決定
        本文
        ## 結果
        """
        let diagnostics = check(content)
        #expect(diagnostics.map(\.line) == [2, 6])
        #expect(diagnostics.allSatisfy { $0.severity == .error && $0.ruleID == "empty-section" })
        #expect(diagnostics.first?.message.contains("「背景」") == true)
    }

    @Test func parentWithOnlySubsectionsIsNotEmpty() {
        let content = """
        ## 検討した選択肢
        ### 案A
        説明
        ### 案B
        説明
        """
        #expect(check(content).isEmpty)
    }

    @Test func emptySubsectionIsReported() {
        let content = """
        ## 検討した選択肢
        ### 案A
        説明
        ### 案B
        """
        let diagnostics = check(content)
        #expect(diagnostics.map(\.line) == [4])
        #expect(diagnostics.first?.message.contains("「案B」") == true)
    }

    @Test func emptyDocumentReportsNothing() {
        #expect(check("").isEmpty)
    }
}
