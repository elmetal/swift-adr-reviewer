import Testing
@testable import ADRReviewer

@Suite struct DrawbackMitigationRuleTests {
    private let rule = DrawbackMitigationRule()

    private func check(_ consequences: String) -> [Diagnostic] {
        let content = """
        # タイトル
        ## 決定
        Swift を採用する。
        ## 結果
        \(consequences)
        ## 検討した選択肢
        - A
        - B
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "学習コストがかかるリスクがあるが、勉強会で軽減する。",
        "デメリットは学習コストである。対策として勉強会を開く。",
        "- リスク: ビルド時間の増加。許容範囲と判断する。",
        "懸念はベンダーロックインである。これは受け入れる。",
        "Risk: vendor lock-in. We accept this for now.",
        "### デメリット\n学習コストがかかる。\n### 対策\n勉強会を開く。",
        "### 悪い点\n- 学習コスト\n- 依存の増加\n### 軽減策\nどちらも段階的な導入で抑える。",
    ])
    func addressedDrawbacksReportNothing(consequences: String) {
        #expect(check(consequences).isEmpty)
    }

    @Test(arguments: [
        "学習コストがかかるリスクがある。",
        "デメリットは学習コストである。ビルドは速くなる。",
        "- 利点: 速い\n- リスク: 依存が増える",
    ])
    func unaddressedDrawbackIsWarningAtSentence(consequences: String) {
        let diagnostics = check(consequences)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "drawback-mitigation")
        #expect(diagnostics.first?.message.contains("対策や許容") == true)
    }

    @Test(arguments: [
        "契約化された API を経由するため、機能が突然壊れるリスクがなくなる。",
        "運用上の懸念は解消される。",
        "案 A の利点は失われる。互換性を管理する必要が生じる。",  // costs, not risks
    ])
    func negatedOrCostOnlySentencesAreNotChecked(consequences: String) {
        #expect(check(consequences).isEmpty)
    }

    @Test func reportsEachUnaddressedDrawbackWithItsLine() {
        let consequences = """
        リスクAがある。
        リスクBがある。対策として監視する。
        懸念Cがある。
        """
        #expect(check(consequences).map(\.line) == [5, 7])
    }

    @Test func mitigationTwoSentencesLaterDoesNotCount() {
        #expect(check("リスクAがある。ビルドは速くなる。対策として監視する。").count == 1)
    }

    @Test func emptyMitigationSubsectionDoesNotCount() {
        #expect(check("学習コストがかかるリスクがある。\n### 対策\n").count == 1)
    }

    @Test func missingOrEmptySectionIsLeftToOtherRules() {
        #expect(rule.check(Document(path: "adr.md", content: "## 決定\n本文")).isEmpty)
        #expect(check("").isEmpty)
    }

    @Test func drawbacksInOtherSectionsAreNotChecked() {
        let content = "## 背景\nリスクがある。\n## 結果\n速くなる。\n"
        #expect(rule.check(Document(path: "adr.md", content: content)).isEmpty)
    }

    @Test func customMarkers() {
        let custom = DrawbackMitigationRule(drawbackKeywords: ["痛み"], mitigationMarkers: ["我慢"])
        #expect(custom.check(Document(path: "adr.md", content: "## 結果\n痛みがある。我慢する。\n")).isEmpty)
        #expect(custom.check(Document(path: "adr.md", content: "## 結果\n痛みがある。\n")).count == 1)
        #expect(custom.check(Document(path: "adr.md", content: "## 結果\nリスクがある。\n")).isEmpty)
    }
}
