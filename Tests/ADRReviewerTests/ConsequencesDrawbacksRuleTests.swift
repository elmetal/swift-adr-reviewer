import Testing
@testable import ADRReviewer

@Suite struct ConsequencesDrawbacksRuleTests {
    private let rule = ConsequencesDrawbacksRule()

    private func check(_ body: String, heading: String = "## 結果") -> [Diagnostic] {
        let content = """
        # タイトル
        ## 決定
        本文
        \(heading)
        \(body)
        ## 検討した選択肢
        - A
        - B
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "ビルドが速くなる。一方でデメリットとして学習コストがかかる。",
        "トレードオフ: 柔軟性は下がる。",
        "### 良い点\n速い。\n### 悪い点\n複雑。",
        "- 利点: 速い\n- リスク: 依存が増える",
        "懸念点として運用負荷がある。",
        "Pros: fast. Cons: complex.",
        "There is a trade-off with flexibility.",
        "Known drawbacks: none yet.",
        "Web 側のリリースが完了するまで機能は実現できない。",
        "案 A で得られたはずの即時性の利点は失われる。",
        "API のバージョン互換性を管理する必要が生じる。",
        "機能リリースは Web 側のスケジュールに依存する。",
    ])
    func mentioningADrawbackReportsNothing(body: String) {
        #expect(check(body).isEmpty)
    }

    @Test(arguments: [
        "ビルドが速くなる。開発体験が良くなる。",
        "### 良い点\n速い。\n### 効果\n生産性が上がる。",
        "契約化された API を経由するため、機能が突然壊れるリスクがなくなる。",
        "運用上の懸念は解消される。デメリットはない。",
        "There is no risk of breakage. It removes the risk of drift.",
    ])
    func onlyBenefitsIsWarningAtHeading(body: String) {
        let diagnostics = check(body)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "consequences-drawbacks")
        #expect(diagnostics.first?.line == 4)
        #expect(diagnostics.first?.message.contains("負の影響") == true)
    }

    @Test func negatedAndAffirmedKeywordInOneSentenceCounts() {
        #expect(check("移行のリスクはなくなるが、運用のリスクが残る。").isEmpty)
    }

    @Test func keywordsInsideCodeBlocksDoNotCount() {
        #expect(check("```\nリスク\n```\n速くなる。").count == 1)
    }

    @Test func keywordsInOtherSectionsDoNotCount() {
        let content = "## 背景\nリスクがある。\n## 結果\n速くなる。\n"
        #expect(rule.check(Document(path: "adr.md", content: content)).count == 1)
    }

    @Test func missingOrEmptySectionIsLeftToOtherRules() {
        #expect(rule.check(Document(path: "adr.md", content: "## 背景\n本文")).isEmpty)
        #expect(check("").isEmpty)
    }

    @Test func aliasHeadingsAreRecognised() {
        #expect(check("速くなる。", heading: "## Consequences").count == 1)
        #expect(check("速くなる。", heading: "## 影響").count == 1)
    }

    @Test func customKeywords() {
        let custom = ConsequencesDrawbacksRule(keywords: ["痛み"])
        let content = "## 結果\n痛みを伴う。\n"
        #expect(custom.check(Document(path: "adr.md", content: content)).isEmpty)
        #expect(custom.check(Document(path: "adr.md", content: "## 結果\nリスクがある。\n")).count == 1)
    }
}
