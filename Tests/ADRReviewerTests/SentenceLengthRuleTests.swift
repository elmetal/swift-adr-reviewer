import Testing
@testable import ADRReviewer

@Suite struct SentenceLengthRuleTests {
    private let rule = SentenceLengthRule()

    private func check(_ content: String) -> [Diagnostic] {
        rule.check(Document(path: "adr.md", content: content))
    }

    private func sentence(length: Int) -> String {
        String(repeating: "あ", count: length - 1) + "。"
    }

    @Test func defaultThreshold() {
        #expect(rule.maximumLength == 100)
    }

    @Test(arguments: [1, 50, 100])
    func atOrBelowThresholdReportsNothing(length: Int) {
        #expect(check(sentence(length: length)).isEmpty)
    }

    @Test(arguments: [101, 200])
    func aboveThresholdReportsWarning(length: Int) {
        let diagnostics = check(sentence(length: length))
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "sentence-length")
        #expect(diagnostics.first?.line == 1)
        #expect(diagnostics.first?.message.contains("\(length)字あります(上限100字)") == true)
        #expect(diagnostics.first?.message.contains("「あああああああああああああああ…」") == true)
    }

    @Test func reportsEachLongSentenceWithItsLine() {
        let content = """
        ## 背景

        短い文。\(sentence(length: 150))
        \(sentence(length: 120))短い文。
        """
        let diagnostics = check(content)
        #expect(diagnostics.map(\.line) == [3, 4])
    }

    @Test func wrappedLongSentenceIsStillOneSentence() {
        let content = String(repeating: "あ", count: 60) + "\n" + String(repeating: "い", count: 60) + "。"
        let diagnostics = check(content)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message.contains("121字") == true)
    }

    @Test func longCodeBlockLinesAreIgnored() {
        let content = "```\n" + String(repeating: "x", count: 300) + "\n```\n"
        #expect(check(content).isEmpty)
    }

    @Test func customThreshold() {
        let strict = SentenceLengthRule(maximumLength: 10)
        #expect(strict.check(Document(path: "adr.md", content: sentence(length: 11))).count == 1)
    }
}
