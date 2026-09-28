/// A check that inspects a document and reports findings.
public protocol Rule: Sendable {
    /// Stable identifier used in diagnostics, e.g. `document-length`.
    var id: String { get }

    func check(_ document: Document) -> [Diagnostic]
}
