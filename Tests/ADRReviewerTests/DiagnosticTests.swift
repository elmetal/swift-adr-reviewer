import Testing
@testable import ADRReviewer

@Suite struct DiagnosticTests {
    @Test func formatsWithoutLine() {
        let diagnostic = Diagnostic(path: "docs/adr.md", severity: .warning, ruleID: "rule", message: "msg")
        #expect(diagnostic.formatted == "docs/adr.md: warning: msg [rule]")
    }

    @Test func formatsWithLine() {
        let diagnostic = Diagnostic(path: "docs/adr.md", line: 12, severity: .error, ruleID: "rule", message: "msg")
        #expect(diagnostic.formatted == "docs/adr.md:12: error: msg [rule]")
    }

    @Test func severityOrdering() {
        #expect(Severity.warning < Severity.error)
    }
}
