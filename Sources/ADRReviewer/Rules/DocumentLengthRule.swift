/// Reports documents whose total character count exceeds the configured thresholds.
///
/// Characters are counted as Swift `Character`s (extended grapheme clusters)
/// over the whole document, including whitespace, newlines and Markdown syntax.
public struct DocumentLengthRule: Rule {
    public static let defaultWarningThreshold = 5_000
    public static let defaultErrorThreshold = 7_000

    public let id = "document-length"

    /// A document longer than this many characters produces a warning.
    public var warningThreshold: Int
    /// A document longer than this many characters produces an error.
    public var errorThreshold: Int

    /// - Precondition: `warningThreshold <= errorThreshold`.
    public init(
        warningThreshold: Int = DocumentLengthRule.defaultWarningThreshold,
        errorThreshold: Int = DocumentLengthRule.defaultErrorThreshold
    ) {
        precondition(warningThreshold <= errorThreshold, "warningThreshold must not exceed errorThreshold")
        self.warningThreshold = warningThreshold
        self.errorThreshold = errorThreshold
    }

    public func check(_ document: Document) -> [Diagnostic] {
        let count = document.content.count

        let severity: Severity
        let threshold: Int
        if count > errorThreshold {
            severity = .error
            threshold = errorThreshold
        } else if count > warningThreshold {
            severity = .warning
            threshold = warningThreshold
        } else {
            return []
        }

        return [
            Diagnostic(
                path: document.path,
                severity: severity,
                ruleID: id,
                message: "文書が長すぎます。\(count)字あります(上限\(threshold)字)。分割するか内容を絞ってください。"
            )
        ]
    }
}
