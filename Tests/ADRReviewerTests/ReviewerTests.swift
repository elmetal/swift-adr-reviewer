import Testing
@testable import ADRReviewer

@Suite struct ReviewerTests {
    @Test func defaultReviewerIncludesDocumentLengthRule() {
        #expect(Reviewer.default.rules.contains { $0 is DocumentLengthRule })
    }

    @Test func reviewsMultipleDocuments() {
        let reviewer = Reviewer(rules: [DocumentLengthRule(warningThreshold: 1, errorThreshold: 2)])
        let documents = [
            Document(path: "ok.md", content: "a"),
            Document(path: "warn.md", content: "ab"),
            Document(path: "error.md", content: "abc"),
        ]
        let diagnostics = reviewer.review(documents)
        #expect(diagnostics.map(\.path) == ["warn.md", "error.md"])
        #expect(diagnostics.map(\.severity) == [.warning, .error])
    }
}
