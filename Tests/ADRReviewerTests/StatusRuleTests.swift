import Testing
@testable import ADRReviewer

@Suite struct StatusRuleTests {
    private let rule = StatusRule()

    private func check(_ content: String) -> [Diagnostic] {
        rule.check(Document(path: "adr.md", content: content))
    }

    private func adr(status: String) -> String {
        """
        # 1. タイトル

        ## ステータス

        \(status)

        ## 背景
        本文
        """
    }

    @Test(arguments: [
        "提案中", "承認済み", "承認", "採用", "却下", "廃止", "非推奨",
        "Accepted", "accepted", "Proposed", "Deprecated",
        "承認済み(2026-09-28)", "提案中 → 承認済み",
    ])
    func recognisedValuesReportNothing(status: String) {
        #expect(check(adr(status: status)).isEmpty)
    }

    @Test(arguments: ["TBD", "検討中", "未定"])
    func unrecognisedValueIsWarningAtValueLine(status: String) {
        let diagnostics = check(adr(status: status))
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "status")
        #expect(diagnostics.first?.line == 5)
        #expect(diagnostics.first?.message.contains("提案中 / 承認済み") == true)
    }

    @Test(arguments: [
        "置き換え済み: ADR-0007", "Superseded by [ADR 7](0007-foo.md)", "0007 に置き換え", "置き換え済み(7番)",
    ])
    func supersededWithReferenceReportsNothing(status: String) {
        #expect(check(adr(status: status)).isEmpty)
    }

    @Test(arguments: ["置き換え済み", "Superseded", "置換済み(別の ADR を参照)"])
    func supersededWithoutReferenceIsWarning(status: String) {
        let diagnostics = check(adr(status: status))
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.message.contains("置き換え先") == true)
    }

    @Test func missingStatusSectionIsLeftToOtherRules() {
        #expect(check("# タイトル\n## 背景\n本文").isEmpty)
    }

    @Test func emptyStatusSectionIsLeftToOtherRules() {
        #expect(check("## ステータス\n\n## 背景\n本文").isEmpty)
    }

    @Test func aliasHeadingsAreRecognised() {
        #expect(check("## Status\nTBD\n").count == 1)
        #expect(check("## 状態\nTBD\n").count == 1)
    }

    @Test func summaryListsValues() {
        #expect(rule.summary.contains("提案中 / 承認済み / 却下 / 廃止 / 置き換え済み"))
    }
}
