import Testing
@testable import ADRReviewer

@Suite struct UngroundedRationaleRuleTests {
    private let rule = UngroundedRationaleRule()

    private func check(context: String = "現在のビルドは 10 分かかり遅い。開発者の待ち時間が増えている。チームには Swift の経験者が多い。", rationale: String) -> [Diagnostic] {
        let content = """
        # 1. Swift を採用する
        ## 背景
        \(context)
        ## 決定
        Swift を採用する。
        ## 決定理由
        \(rationale)
        ## 結果
        リスクは無い。
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "ビルドが遅いため、Swift を採用する。",
        "社内に Swift の経験者が多いため。",
        "開発者の待ち時間を減らすため。",
        "ビルド速度の観点から。",
    ])
    func reasonGroundedInContextReportsNothing(rationale: String) {
        #expect(check(rationale: rationale).isEmpty)
    }

    @Test(arguments: [
        "型安全なので不具合を減らせる。",
        "採用市場で有利になるため。",
        "モダンな言語で書きやすいため。",
    ])
    func reasonAbsentFromContextIsWarning(rationale: String) {
        let diagnostics = check(rationale: rationale)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "ungrounded-rationale")
        #expect(diagnostics.first?.line == 7)
        #expect(diagnostics.first?.message.contains("背景") == true)
    }

    @Test(arguments: [
        "型安全なので不具合が 30% 減る。",
        "型安全なので不具合を減らせる([調査](https://example.com))。",
        "型安全なので不具合を減らせる。出典: 社内計測。",
    ])
    func reasonWithBackingReportsNothing(rationale: String) {
        #expect(check(rationale: rationale).isEmpty)
    }

    @Test func veryShortReasonIsNotJudged() {
        #expect(check(rationale: "速いため。").isEmpty)
    }

    @Test func noContextSectionDisablesTheRule() {
        let content = "# 1. Swift を採用する\n## 決定\nSwift を採用する。\n## 決定理由\n採用市場で有利になるため。\n"
        #expect(rule.check(Document(path: "adr.md", content: content)).isEmpty)
    }

    @Test func reportsEachUngroundedReasonWithItsLine() {
        let diagnostics = check(rationale: "採用市場で有利になるため。\nビルドが遅いため。\nモダンな言語で書きやすいため。")
        #expect(diagnostics.map(\.line) == [7, 9])
    }
}
