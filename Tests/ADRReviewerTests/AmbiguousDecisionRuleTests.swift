import Testing
@testable import ADRReviewer

@Suite struct AmbiguousDecisionRuleTests {
    private let rule = AmbiguousDecisionRule()

    private func check(_ body: String, heading: String = "## 決定") -> [Diagnostic] {
        let content = """
        # タイトル
        ## 背景
        本文
        \(heading)
        \(body)
        ## 結果
        本文
        """
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        "Swift を採用する。",
        "モジュールは機能単位で分割する。共通処理は Core に置く。",
        "検討した結果、SwiftPM を使う。",
    ])
    func assertiveSentencesReportNothing(body: String) {
        #expect(check(body).isEmpty)
    }

    @Test(arguments: AmbiguousDecisionRule.defaultExpressions)
    func eachExpressionIsAnError(expression: String) {
        let diagnostics = check("この方式を採用\(expression)。")
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .error)
        #expect(diagnostics.first?.ruleID == "ambiguous-decision")
        #expect(diagnostics.first?.message.contains("「\(expression)」") == true)
    }

    @Test func reportsEachSentenceWithItsLine() {
        let body = """
        Swift を採用する。移行はできれば年内に行う。
        テストは基本的に XCTest を使う。
        """
        let diagnostics = check(body)
        #expect(diagnostics.map(\.line) == [5, 6])
        #expect(diagnostics[0].message.contains("「できれば」") == true)
        #expect(diagnostics[1].message.contains("「基本的に」") == true)
    }

    @Test func multipleExpressionsInOneSentenceGiveOneDiagnostic() {
        let diagnostics = check("できれば年内に、必要に応じて移行する。")
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message.contains("「必要に応じて」「できれば」") == true)
    }

    @Test func expressionsInOtherSectionsDoNotCount() {
        let content = "## 背景\n移行は難しいかもしれない。\n## 決定\nSwift を採用する。\n## 結果\n負荷が上がるかもしれない。\n"
        #expect(rule.check(Document(path: "adr.md", content: content)).isEmpty)
    }

    @Test func subsectionsOfDecisionAreIncluded() {
        #expect(check("### 詳細\n方式は適宜決める。").count == 1)
    }

    @Test func codeBlocksAreIgnored() {
        #expect(check("```\n// 必要に応じて変更\n```\nSwift を採用する。").isEmpty)
    }

    @Test func missingOrEmptySectionIsLeftToOtherRules() {
        #expect(rule.check(Document(path: "adr.md", content: "## 背景\n本文")).isEmpty)
        #expect(check("").isEmpty)
    }

    @Test func aliasHeadingsAreRecognised() {
        #expect(check("採用するかもしれない。", heading: "## Decision").count == 1)
        #expect(check("採用するかもしれない。", heading: "## 決定事項").count == 1)
    }

    @Test func customExpressions() {
        let custom = AmbiguousDecisionRule(expressions: ["など"])
        let content = "## 決定\nSwift などを使う。\n"
        #expect(custom.check(Document(path: "adr.md", content: content)).count == 1)
        #expect(custom.check(Document(path: "adr.md", content: "## 決定\n採用するかもしれない。\n")).isEmpty)
    }
}
