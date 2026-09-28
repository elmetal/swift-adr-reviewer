import Testing
@testable import ADRReviewer

@Suite struct ADRSectionTests {
    @Test func matchesAliasesIgnoringAsciiCase() {
        #expect(ADRSection.status.matches(Heading(level: 2, title: "status", line: 1)))
        #expect(ADRSection.context.matches(Heading(level: 2, title: "2. 背景と課題", line: 1)))
        #expect(!ADRSection.decision.matches(Heading(level: 2, title: "背景", line: 1)))
    }

    @Test func sectionsMatchingReturnsBodies() {
        let document = Document(path: "adr.md", content: "## ステータス\n承認済み\n## 背景\n本文\n")
        let matches = document.sections(matching: .status)
        #expect(matches.count == 1)
        #expect(matches.first?.bodyLines == ["承認済み"])
    }
}
