import Testing
@testable import ADRReviewer

@Suite struct AlternativesRuleTests {
    private let rule = AlternativesRule()

    private func check(_ body: String, heading: String = "## 検討した選択肢") -> [Diagnostic] {
        let content = """
        # タイトル
        \(heading)
        \(body)
        ## 結果
        本文
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "- 案A\n- 案B",
        "* 案A\n* 案B",
        "+ 案A\n+ 案B",
        "1. 案A\n2. 案B",
        "1) 案A\n2) 案B",
        "### 案A\n説明\n### 案B\n説明",
        "- 案A\n### 案B\n説明",
        "- 案A\n  - 利点\n  - 欠点\n- 案B",
        "以下を比較した。\n\n- 案A\n- 案B\n",
        "  - 案A\n  - 案B",
        "- 案A\n\t- 詳細\n- 案B",
    ])
    func twoOrMoreOptionsReportNothing(body: String) {
        #expect(check(body).isEmpty)
    }

    @Test(arguments: [
        "| 案 | 利点 |\n|---|---|\n| A | 速い |\n| B | 安い |",
        "|案|\n|-|\n|A|",
    ])
    func tableSatisfiesTheRule(body: String) {
        #expect(check(body).isEmpty)
    }

    @Test(arguments: [
        "- 案A",
        "案Aと案Bを比較した。",
        "- 案A\n  - 案B(ネストは数えない)",
        "### 案A\n#### 利点\n#### 欠点",
    ])
    func fewerThanTwoOptionsIsWarningAtHeading(body: String) {
        let diagnostics = check(body)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "alternatives")
        #expect(diagnostics.first?.line == 2)
    }

    @Test func messageIncludesCount() {
        #expect(check("- 案A").first?.message.contains("1個しか") == true)
        #expect(check("案A").first?.message.contains("0個しか") == true)
    }

    @Test func codeBlocksAreIgnored() {
        let body = "```\n- not\n- an option\n| nor | a table |\n```\n案Aのみ"
        #expect(check(body).count == 1)
    }

    @Test func missingOrEmptySectionIsLeftToOtherRules() {
        let missing = Document(path: "adr.md", content: "## 背景\n本文")
        #expect(rule.check(missing).isEmpty)
        #expect(check("").isEmpty)
    }

    @Test func aliasHeadingsAreRecognised() {
        #expect(check("- 案A", heading: "## Alternatives").count == 1)
        #expect(check("- 案A", heading: "## 代替案").count == 1)
    }

    @Test func customMinimum() {
        let strict = AlternativesRule(minimumOptions: 3)
        let content = "## 検討した選択肢\n- A\n- B\n"
        #expect(strict.check(Document(path: "adr.md", content: content)).count == 1)
    }
}
