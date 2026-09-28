import Testing
@testable import ADRReviewer

@Suite struct DocumentLengthRuleTests {
    private let rule = DocumentLengthRule()

    private func document(length: Int) -> Document {
        Document(path: "adr.md", content: String(repeating: "あ", count: length))
    }

    @Test func defaultThresholds() {
        #expect(rule.warningThreshold == 5_000)
        #expect(rule.errorThreshold == 7_000)
    }

    @Test(arguments: [0, 4_999, 5_000])
    func atOrBelowWarningThresholdReportsNothing(length: Int) {
        #expect(rule.check(document(length: length)).isEmpty)
    }

    @Test(arguments: [5_001, 6_000, 7_000])
    func aboveWarningThresholdReportsWarning(length: Int) {
        let diagnostics = rule.check(document(length: length))
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .warning)
        #expect(diagnostics.first?.ruleID == "document-length")
        #expect(diagnostics.first?.path == "adr.md")
        #expect(diagnostics.first?.line == nil)
    }

    @Test(arguments: [7_001, 10_000])
    func aboveErrorThresholdReportsError(length: Int) {
        let diagnostics = rule.check(document(length: length))
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .error)
    }

    @Test func messageIncludesActualCountAndThreshold() {
        let diagnostics = rule.check(document(length: 5_500))
        #expect(diagnostics.first?.message.contains("5500字") == true)
        #expect(diagnostics.first?.message.contains("上限5000字") == true)
    }

    @Test func summaryMentionsThresholds() {
        let rule = DocumentLengthRule(warningThreshold: 10, errorThreshold: 20)
        #expect(rule.summary.contains("10字"))
        #expect(rule.summary.contains("20字"))
    }

    @Test func countsCharactersNotBytes() {
        // 5,001 Japanese characters are 15,003 UTF-8 bytes; must be a warning, not an error.
        let diagnostics = rule.check(document(length: 5_001))
        #expect(diagnostics.first?.severity == .warning)
    }

    @Test func countsWhitespaceAndNewlines() {
        let content = String(repeating: "あ\n", count: 2_501)  // 5,002 characters
        let diagnostics = rule.check(Document(path: "adr.md", content: content))
        #expect(diagnostics.first?.severity == .warning)
    }

    @Test func customThresholds() {
        let rule = DocumentLengthRule(warningThreshold: 10, errorThreshold: 20)
        #expect(rule.check(document(length: 10)).isEmpty)
        #expect(rule.check(document(length: 11)).first?.severity == .warning)
        #expect(rule.check(document(length: 21)).first?.severity == .error)
    }
}
