import Foundation
import Testing
@testable import ADRReviewer

@Suite struct ConfigurationTests {
    private func decode(_ json: String) throws -> Configuration {
        try Configuration(json: Data(json.utf8))
    }

    @Test func decodesBooleanAndObjectSettings() throws {
        let configuration = try decode("""
        {
          "rules": {
            "rationale-evidence": false,
            "document-length": true,
            "sentence-length": { "severity": "error" },
            "status": { "enabled": false, "severity": "warning" }
          }
        }
        """)
        #expect(configuration.rules["rationale-evidence"] == RuleSetting(enabled: false))
        #expect(configuration.rules["document-length"] == RuleSetting(enabled: true))
        #expect(configuration.rules["sentence-length"] == RuleSetting(severity: .error))
        #expect(configuration.rules["status"] == RuleSetting(enabled: false, severity: .warning))
    }

    @Test func emptyObjectIsEmptyConfiguration() throws {
        #expect(try decode("{}") == .empty)
        #expect(try decode(#"{"rules": {}}"#) == .empty)
    }

    @Test func invalidSeverityFails() {
        #expect(throws: (any Error).self) { try decode(#"{"rules": {"status": {"severity": "fatal"}}}"#) }
    }

    @Test func locateWalksUpToTheNearestFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("adr-config-\(UUID().uuidString)")
        let nested = root.appendingPathComponent("a/b/c")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(Configuration.locate(startingAt: nested) == nil)

        let file = root.appendingPathComponent("a").appendingPathComponent(Configuration.fileName)
        try Data("{}".utf8).write(to: file)
        #expect(Configuration.locate(startingAt: nested)?.standardizedFileURL == file.standardizedFileURL)
        #expect(Configuration.locate(startingAt: root) == nil)
    }
}

@Suite struct ReviewerConfigurationTests {
    private let document = Document(path: "adr.md", content: String(repeating: "あ", count: 5_500))

    @Test func defaultReviewerIsUnchangedByEmptyConfiguration() throws {
        let reviewer = try Reviewer.default.applying(.empty)
        #expect(reviewer.rules.map(\.id) == Reviewer.default.rules.map(\.id))
    }

    @Test func disabledRulesAreRemoved() throws {
        let configuration = Configuration(rules: ["document-length": RuleSetting(enabled: false)])
        let reviewer = try Reviewer.default.applying(configuration)
        #expect(!reviewer.rules.contains { $0.id == "document-length" })
        #expect(reviewer.rules.count == Reviewer.default.rules.count - 1)
        #expect(!reviewer.review(document).contains { $0.ruleID == "document-length" })
    }

    @Test func severityOverrideAppliesToEveryDiagnosticOfTheRule() throws {
        let configuration = Configuration(rules: ["document-length": RuleSetting(severity: .error)])
        let reviewer = try Reviewer.default.applying(configuration)
        let diagnostics = reviewer.review(document).filter { $0.ruleID == "document-length" }
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.severity == .error)
        #expect(reviewer.rules.first { $0.id == "document-length" }?.summary == DocumentLengthRule().summary)
    }

    @Test func explicitlyEnabledRuleStays() throws {
        let configuration = Configuration(rules: ["document-length": RuleSetting(enabled: true)])
        #expect(try Reviewer.default.applying(configuration).rules.count == Reviewer.default.rules.count)
    }

    @Test func unknownRuleIdsAreRejected() {
        let configuration = Configuration(rules: ["sentence-lenght": RuleSetting(enabled: false), "nope": RuleSetting()])
        #expect(throws: ConfigurationError.unknownRules(["nope", "sentence-lenght"])) {
            try Reviewer.default.applying(configuration)
        }
    }
}
