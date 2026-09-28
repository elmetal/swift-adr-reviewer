/// A check that inspects a document and reports findings.
public protocol Rule: Sendable {
    /// Stable identifier used in diagnostics, e.g. `document-length`.
    var id: String { get }

    /// One-line, human-readable description of what the rule checks. Shown in `--help`.
    var summary: String { get }

    func check(_ document: Document) -> [Diagnostic]
}
