/// Reports prose sentences longer than a threshold. See ``Document/sentences``
/// for what counts as a sentence.
public struct SentenceLengthRule: Rule {
    public static let defaultMaximumLength = 100

    public let id = "sentence-length"

    /// A sentence longer than this many characters produces a warning.
    public var maximumLength: Int

    public init(maximumLength: Int = SentenceLengthRule.defaultMaximumLength) {
        precondition(maximumLength >= 1, "maximumLength must be at least 1")
        self.maximumLength = maximumLength
    }

    public var summary: String {
        "地の文の一文(。！？で区切り、空白を除く)が\(maximumLength)字を超えると warning を報告します。見出し・コードブロック・表は対象外です。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        document.sentences
            .filter { $0.length > maximumLength }
            .map { sentence in
                Diagnostic(
                    path: document.path,
                    line: sentence.line,
                    severity: .warning,
                    ruleID: id,
                    message: "一文が長すぎます。\(sentence.length)字あります(上限\(maximumLength)字)。「\(Self.excerpt(of: sentence.text))」を複数の文に分けてください。"
                )
            }
    }

    private static func excerpt(of text: String, length: Int = 15) -> String {
        text.count <= length ? text : String(text.prefix(length)) + "…"
    }
}
