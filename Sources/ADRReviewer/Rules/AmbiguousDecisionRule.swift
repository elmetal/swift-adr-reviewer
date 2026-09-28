/// Reports hedging or non-committal expressions in the 決定 section.
///
/// Every prose sentence in the first section matching ``ADRSection/decision``
/// (subsections included, code blocks and tables excluded) is searched for the
/// configured expressions. A decision written as "かもしれない", "検討する" or
/// "できれば" is not a decision, so each offending sentence is an error. A missing
/// or empty section is left to ``RequiredSectionsRule`` and ``EmptySectionRule``.
public struct AmbiguousDecisionRule: Rule {
    /// Expressions that make a decision non-committal.
    public static let defaultExpressions: [String] = [
        "と思われる", "と思う", "と考えられる", "かもしれない", "かもしれません",
        "適宜", "必要に応じて", "場合によっては",
        "検討する", "検討します", "検討したい", "予定", "つもり",
        "できれば", "可能であれば", "可能なら", "なるべく", "できるだけ", "基本的に",
        "たぶん", "おそらく", "望ましい", "したい",
    ]

    public let id = "ambiguous-decision"

    public var expressions: [String]

    public init(expressions: [String] = AmbiguousDecisionRule.defaultExpressions) {
        self.expressions = expressions
    }

    public var summary: String {
        "「決定」セクションの文に曖昧な表現(かもしれない・検討する・できれば・基本的に など)があれば error を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard let section = document.sections(matching: .decision).first, !section.isEmpty else { return [] }

        return document.sentences(in: section).compactMap { sentence in
            let found = expressions.filter { sentence.text.contains($0) }
            guard !found.isEmpty else { return nil }

            let quoted = found.map { "「\($0)」" }.joined()
            return Diagnostic(
                path: document.path,
                line: sentence.line,
                severity: .error,
                ruleID: id,
                message: "決定に曖昧な表現\(quoted)があります。「\(Self.excerpt(of: sentence.text))」を断定した文に書き直してください。"
            )
        }
    }

    private static func excerpt(of text: String, length: Int = 20) -> String {
        text.count <= length ? text : String(text.prefix(length)) + "…"
    }
}
