import Testing
@testable import ADRReviewer

@Suite struct AlternativeRejectionRuleTests {
    private let rule = AlternativeRejectionRule()

    private func check(_ body: String) -> [Diagnostic] {
        let content = """
        # タイトル
        ## 決定
        Swift を採用する。
        ## 検討した選択肢
        \(body)
        ## 結果
        本文
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "- 案A: Swift(採用)\n- 案B: Kotlin。iOS の実績が少ないため不採用。",
        "- Swift: 型安全なので採用\n- Kotlin: 欠点はビルド環境の整備コスト",
        "- Swift\n  - 利点: 速い\n- Kotlin\n  - デメリット: 実績が少ない",
        "### 案A: Swift\n採用する。\n### 案B: Kotlin\n実績が少ないため見送る。",
        "- Swift (selected)\n- Kotlin: rejected because of tooling",
    ])
    func justifiedOptionsReportNothing(body: String) {
        #expect(check(body).isEmpty)
    }

    @Test func unjustifiedOptionsAreWarningsAtTheirLines() {
        let diagnostics = check("- 案A: Swift(採用)\n- 案B: Kotlin\n- 案C: Objective-C")
        #expect(diagnostics.map(\.line) == [6, 7])
        #expect(diagnostics.allSatisfy { $0.severity == .warning && $0.ruleID == "alternative-rejection" })
        #expect(diagnostics.first?.message.contains("「案B: Kotlin」") == true)
    }

    @Test func negatedChosenMarkerIsNotAJustificationByItself() {
        // 採用しない alone is a verdict, not a reason; but it is in the reason list as a rejection marker.
        #expect(check("- 案A: Swift(採用)\n- 案B: Kotlin は採用しない").isEmpty)
        #expect(check("- 案A: Swift(採用)\n- 案B: Kotlin").count == 1)
    }

    @Test func subheadingOptionWithoutReasonIsReported() {
        let diagnostics = check("### 案A\n採用する。\n### 案B\nKotlin である。")
        #expect(diagnostics.map(\.line) == [7])
    }

    @Test func tablesAreNotChecked() {
        #expect(check("| 案 | 評価 |\n|---|---|\n| Swift | 採用 |\n| Kotlin | x |").isEmpty)
    }

    @Test func missingOrEmptySectionIsLeftToOtherRules() {
        #expect(rule.check(Document(path: "adr.md", content: "## 決定\n本文")).isEmpty)
        #expect(check("").isEmpty)
    }
}
