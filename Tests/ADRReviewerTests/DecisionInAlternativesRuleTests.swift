import Testing
@testable import ADRReviewer

@Suite struct DecisionInAlternativesRuleTests {
    private let rule = DecisionInAlternativesRule()

    private func check(title: String = "1. Swift を採用する", decision: String = "Swift を採用する。", alternatives: String) -> [Diagnostic] {
        let content = """
        # \(title)
        ## 決定
        \(decision)
        ## 検討した選択肢
        \(alternatives)
        ## 結果
        本文
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "- Swift\n- Kotlin",
        "- 案A: Swift を採用する\n- 案B: Kotlin を採用する",
        "- Swift: 型安全。\n- Objective-C: 継続。",
        "### Swift\n速い。\n### Kotlin\n遅い。",
        "1. Kotlin\n2. Swift",
    ])
    func chosenOptionListedReportsNothing(alternatives: String) {
        #expect(check(alternatives: alternatives).isEmpty)
    }

    @Test(arguments: [
        "- Kotlin\n- Objective-C",
        "- 案A: Kotlin を採用する\n- 案B: Objective-C を継続する",
        "### Kotlin\n速い。\n### Objective-C\n遅い。",
    ])
    func chosenOptionMissingIsWarningAtHeading(alternatives: String) {
        let diagnostics = check(alternatives: alternatives)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "decision-in-alternatives")
        #expect(diagnostics.first?.line == 4)
    }

    @Test func decisionSentencesCountWhenTitleIsGeneric() {
        #expect(check(title: "ADR-0001", decision: "Swift を採用する。", alternatives: "- Swift\n- Kotlin").isEmpty)
        #expect(check(title: "ADR-0001", decision: "Swift を採用する。", alternatives: "- Kotlin\n- Rust").count == 1)
    }

    @Test func aSingleSharedBigramIsNotAMatch() {
        // 「する」 alone is shared, but that is one bigram.
        #expect(check(alternatives: "- 継続する\n- 中止する").count == 1)
    }

    @Test func tablesAndMissingSectionsAreNotChecked() {
        #expect(check(alternatives: "| 案 | 評価 |\n|---|---|\n| Kotlin | x |").isEmpty)
        #expect(rule.check(Document(path: "adr.md", content: "# Swift を採用する\n## 決定\nSwift。\n")).isEmpty)
        #expect(check(alternatives: "").isEmpty)
    }

    @Test func noDecisionTextDisablesTheRule() {
        let content = "## 検討した選択肢\n- Kotlin\n- Rust\n"
        #expect(rule.check(Document(path: "adr.md", content: content)).isEmpty)
    }
}
