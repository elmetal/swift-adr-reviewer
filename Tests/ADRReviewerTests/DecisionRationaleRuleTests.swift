import Testing
@testable import ADRReviewer

@Suite struct DecisionRationaleRuleTests {
    private let rule = DecisionRationaleRule()

    private func check(_ decision: String, extraSections: String = "") -> [Diagnostic] {
        let content = """
        # タイトル
        ## 背景
        ビルドが遅い。
        ## 決定
        \(decision)
        \(extraSections)
        ## 結果
        本文
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "ビルドが遅いため、Swift を採用する。",
        "Swift を採用する。型安全なので不具合を減らせる。",
        "Swift を採用する。なぜなら、社内に経験者が多い。",
        "型安全であることから Swift を採用する。",
        "経験者が多いからだ。",
        "既存資産を踏まえ、Swift を採用する。",
        "保守性を重視して Swift を採用する。",
        "社内標準は Swift である。したがって Swift を採用する。",
        "Swift を採用する。利点はビルド速度である。",
        "We adopt Swift because the team knows it.",
        "We adopt Swift so that builds stay fast.",
        "Swift を採用する。\n\n### 理由の詳細\n\n経験者が多いためである。",
    ])
    func decisionWithReasonReportsNothing(decision: String) {
        #expect(check(decision).isEmpty)
    }

    @Test(arguments: [
        "Swift を採用する。",
        "Swift を採用する。モジュールは機能単位で分割する。",
        "- Swift を採用する\n- SwiftPM を使う",
    ])
    func decisionWithoutReasonIsWarningAtHeading(decision: String) {
        let diagnostics = check(decision)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "decision-rationale")
        #expect(diagnostics.first?.line == 4)
        #expect(diagnostics.first?.message.contains("理由") == true)
    }

    @Test(arguments: ["## 決定理由", "## 根拠", "## Rationale", "## 選定理由"])
    func rationaleSectionSatisfiesTheRule(heading: String) {
        #expect(check("Swift を採用する。", extraSections: "\(heading)\n経験者が多い。").isEmpty)
    }

    @Test func emptyRationaleSectionIsLeftToEmptySectionRule() {
        #expect(check("Swift を採用する。", extraSections: "## 決定理由\n").isEmpty)
    }

    @Test func reasonOnlyInContextDoesNotCount() {
        // 背景 already says ビルドが遅いため… but the decision itself gives no reason.
        let content = "## 背景\nビルドが遅いため困っている。\n## 決定\nSwift を採用する。\n"
        #expect(rule.check(Document(path: "adr.md", content: content)).count == 1)
    }

    @Test func markersInsideCodeBlocksDoNotCount() {
        #expect(check("```\n// 速いため\n```\nSwift を採用する。").count == 1)
    }

    @Test func missingOrEmptyDecisionIsLeftToOtherRules() {
        #expect(rule.check(Document(path: "adr.md", content: "## 背景\n本文")).isEmpty)
        #expect(check("").isEmpty)
    }

    @Test func customMarkers() {
        let custom = DecisionRationaleRule(markers: ["という判断"])
        let content = "## 決定\nSwift を採用するという判断。\n"
        #expect(custom.check(Document(path: "adr.md", content: content)).isEmpty)
        #expect(custom.check(Document(path: "adr.md", content: "## 決定\n速いため Swift を採用する。\n")).count == 1)
    }
}
