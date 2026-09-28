import Testing
@testable import ADRReviewer

@Suite struct RationaleEvidenceRuleTests {
    private let rule = RationaleEvidenceRule()

    private func check(decision: String = "Swift を採用する。", rationale: String? = nil) -> [Diagnostic] {
        var content = """
        # 1. Swift を採用する
        ## 背景
        ビルドが遅い。
        ## 決定
        \(decision)

        """
        if let rationale { content += "## 決定理由\n\(rationale)\n" }
        content += "## 結果\nリスクは無い。\n"
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "ビルドが 10 分から 3 分に短縮できるため。",
        "[社内計測](https://example.com/bench)でビルドが速かったため。",
        "経験者が多いため。参照: 2026 年のスキル調査。",
        "経験者が多いため。\n\n出典は社内アンケート。",
    ])
    func atLeastOneBackedReasonReportsNothing(rationale: String) {
        #expect(check(rationale: rationale).isEmpty)
    }

    @Test func backedReasonInsideDecisionCounts() {
        #expect(check(decision: "ビルドが 3 倍速いため Swift を採用する。").isEmpty)
    }

    @Test(arguments: [
        "経験者が多いため。",
        "経験者が多いため。\n型安全なので不具合を減らせる。\n将来性があるため。",
        "以下の 2 つの理由による。\n経験者が多いため。\n将来性があるため。",
    ])
    func noBackedReasonIsOneWarningAtRationaleHeading(rationale: String) {
        let diagnostics = check(rationale: rationale)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "rationale-evidence")
        #expect(diagnostics.first?.line == 6)
    }

    @Test func anchorsToDecisionHeadingWhenThereIsNoRationaleSection() {
        let diagnostics = check(decision: "経験者が多いため Swift を採用する。")
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.line == 4)
    }

    @Test func backingTwoSentencesAfterTheReasonDoesNotCount() {
        // In the 決定 section only the sentence with a reason marker is a reason.
        #expect(check(decision: "経験者が多いため Swift を採用する。別の話。参照: 調査。").count == 1)
    }

    @Test func noReasonsIsLeftToDecisionRationaleRule() {
        #expect(check().isEmpty)
    }
}
