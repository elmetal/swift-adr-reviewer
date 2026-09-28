import Testing
@testable import ADRReviewer

@Suite struct RequiredSectionsRuleTests {
    private let rule = RequiredSectionsRule()

    private func check(_ content: String) -> [Diagnostic] {
        rule.check(Document(path: "adr.md", content: content))
    }

    private let complete = """
    # 1. Swift を採用する
    ## ステータス
    承認済み
    ## 背景
    …
    ## 決定
    …
    ## 結果
    …
    ## 検討した選択肢
    …
    """

    @Test func completeDocumentReportsNothing() {
        #expect(check(complete).isEmpty)
    }

    @Test func emptyDocumentReportsEverySection() {
        let diagnostics = check("")
        #expect(diagnostics.count == RequiredSectionsRule.defaultSections.count)
        #expect(diagnostics.map(\.severity) == [.warning, .error, .error, .error, .warning])
        #expect(diagnostics.allSatisfy { $0.ruleID == "required-sections" && $0.line == nil })
    }

    @Test func missingRequiredSectionIsError() {
        let diagnostics = check(complete.replacing("## 決定", with: "## 未定"))
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .error)
        #expect(diagnostics.first?.message.contains("必須セクション「決定」") == true)
    }

    @Test func missingRecommendedSectionIsWarning() {
        let diagnostics = check(complete.replacing("## ステータス", with: "## メモ"))
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.message.contains("推奨セクション「ステータス」") == true)
    }

    @Test(arguments: [
        "## コンテキスト", "## 状況", "## Context", "## context", "## 2. 背景と課題", "### 背景",
    ])
    func acceptsAliasesNumberingAndSuffixes(heading: String) {
        let diagnostics = check(complete.replacing("## 背景", with: heading))
        #expect(diagnostics.isEmpty)
    }

    @Test func headingsInsideCodeBlocksDoNotCount() {
        let content = """
        ```
        ## ステータス
        ## 背景
        ## 決定
        ## 結果
        ## 選択肢
        ```
        """
        #expect(check(content).count == RequiredSectionsRule.defaultSections.count)
    }

    @Test func bodyTextDoesNotCount() {
        let content = "背景と決定と結果とステータスと選択肢を本文に書いただけ"
        #expect(check(content).count == RequiredSectionsRule.defaultSections.count)
    }

    @Test func summaryListsSections() {
        #expect(rule.summary.contains("背景・決定・結果"))
        #expect(rule.summary.contains("ステータス・検討した選択肢"))
    }
}
