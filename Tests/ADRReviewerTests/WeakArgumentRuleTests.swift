import Testing
@testable import ADRReviewer

@Suite struct WeakArgumentRuleTests {
    private let rule = WeakArgumentRule()

    private func check(_ decision: String, rationale: String? = nil) -> [Diagnostic] {
        var content = """
        # タイトル
        ## 背景
        本文
        ## 決定
        \(decision)

        """
        if let rationale { content += "## 決定理由\n\(rationale)\n" }
        content += "## 結果\nリスクがある。\n"
        return rule.check(Document(path: "adr.md", content: content))
    }

    @Test(arguments: [
        ("業界標準なので Swift を採用する。", "多数派への訴え"),
        ("みんな使っているから採用する。", "多数派への訴え"),
        ("Apple が推奨しているため SwiftUI を使う。", "権威への訴え"),
        ("最新の技術なので採用する。", "新しさへの訴え"),
        ("現行の仕組みはレガシーなので置き換える。", "新しさへの訴え"),
        ("すでに投資しているので継続する。", "埋没費用"),
        ("せっかく作ったので使い続ける。", "埋没費用"),
        ("It is widely used, so we adopt it.", "多数派への訴え"),
    ])
    func patternWithoutBackingIsWarning(sentence: String, patternName: String) {
        let diagnostics = check(sentence)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "weak-argument")
        #expect(diagnostics.first?.line == 5)
        #expect(diagnostics.first?.message.contains(patternName) == true)
    }

    @Test(arguments: [
        "業界標準である(https://example.com/survey)ため採用する。",
        "[調査](https://example.com/survey)によると業界標準なので採用する。",
        "採用企業は 2025 年時点で 300 社を超え、業界標準になっているため採用する。",
        "業界標準である。出典: State of Swift 調査。",
        "最新版はビルドが 30% 速いと計測できたため採用する。",
    ])
    func patternWithBackingInSameSentenceReportsNothing(sentence: String) {
        #expect(check(sentence).isEmpty)
    }

    @Test func backingInTheNextSentenceCounts() {
        #expect(check("業界標準なので採用する。詳細は[調査結果](https://example.com)を参照。").isEmpty)
    }

    @Test func backingTwoSentencesLaterDoesNotCount() {
        #expect(check("業界標準なので採用する。他に理由もある。詳細は[調査結果](https://example.com)を参照。").count == 1)
    }

    @Test func rationaleSectionIsChecked() {
        let diagnostics = check("Swift を採用する。", rationale: "モダンな言語だから。")
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.line == 7)
    }

    @Test func otherSectionsAreNotChecked() {
        let content = "## 背景\n業界標準になりつつある。\n## 決定\nSwift を採用する。\n## 結果\nリスクは主流から外れること。\n"
        #expect(rule.check(Document(path: "adr.md", content: content)).isEmpty)
    }

    @Test func multiplePatternsInOneSentenceGiveOneDiagnostic() {
        let diagnostics = check("業界標準で最新なので採用する。")
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message.contains("多数派への訴え「業界標準」") == true)
        #expect(diagnostics.first?.message.contains("新しさへの訴え「最新」") == true)
    }

    @Test func assertiveReasoningReportsNothing() {
        #expect(check("型安全性により実行時エラーを減らせるため Swift を採用する。").isEmpty)
    }

    @Test func customPatterns() {
        let custom = WeakArgumentRule(patterns: [.init(name: "好み", expressions: ["好きだから"])])
        #expect(custom.check(Document(path: "adr.md", content: "## 決定\n好きだから採用する。\n")).count == 1)
        #expect(custom.check(Document(path: "adr.md", content: "## 決定\n業界標準なので採用する。\n")).isEmpty)
    }
}
