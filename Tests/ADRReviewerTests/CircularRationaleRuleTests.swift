import Testing
@testable import ADRReviewer

@Suite struct CircularRationaleRuleTests {
    private let rule = CircularRationaleRule()

    private func check(decision: String = "Swift を採用する。", rationale: String) -> [Diagnostic] {
        let content = """
        # 1. Swift を採用する
        ## 背景
        現在のビルドは 10 分かかり遅い。
        ## 決定
        \(decision)
        ## 決定理由
        \(rationale)
        ## 結果
        リスクは無い。
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "Swift を採用するのが良いため。",
        "Swift を採用することにしたから。",
        "Swift が最適だと判断したため。",
    ])
    func restatementIsWarning(rationale: String) {
        let diagnostics = check(rationale: rationale)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "circular-rationale")
        #expect(diagnostics.first?.line == 7)
        #expect(diagnostics.first?.message.contains("言い換え") == true)
    }

    @Test(arguments: [
        "型安全なので不具合を減らせる。",
        "社内に Swift の経験者が多いため。",
        "ビルドが遅いため、Swift を採用する。",
        "ビルド時間を短くするのが良いため。",  // 良い but not about the decision wording
    ])
    func substantiveReasonReportsNothing(rationale: String) {
        #expect(check(rationale: rationale).isEmpty)
    }

    @Test func reasonInsideDecisionIsComparedWithOtherDecisionSentencesAndTitle() {
        let content = "# 1. Swift を採用する\n## 決定\nSwift が最適なので採用する。\n"
        #expect(rule.check(Document(path: "adr.md", content: content)).count == 1)
    }

    @Test func noReasonsReportsNothing() {
        #expect(rule.check(Document(path: "adr.md", content: "## 決定\nSwift を採用する。\n")).isEmpty)
    }
}
