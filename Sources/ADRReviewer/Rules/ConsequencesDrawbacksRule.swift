/// Checks that the 結果 section records the downsides of the decision, not only
/// its benefits.
///
/// The section body (outside code blocks, subheadings included) must mention at
/// least one drawback keyword such as デメリット, トレードオフ or リスク. A missing
/// or empty section is left to ``RequiredSectionsRule`` and ``EmptySectionRule``.
public struct ConsequencesDrawbacksRule: Rule {
    /// Words that indicate a downside is being discussed. ASCII case is ignored.
    public static let defaultKeywords: [String] = [
        "デメリット", "トレードオフ", "リスク", "懸念", "欠点", "短所", "制約", "代償", "課題",
        "負の影響", "悪い点", "悪化", "犠牲", "マイナス", "弱み",
        "trade-off", "tradeoff", "drawback", "downside", "risk", "cons",
    ]

    public let id = "consequences-drawbacks"

    public var keywords: [String]

    public init(keywords: [String] = ConsequencesDrawbacksRule.defaultKeywords) {
        self.keywords = keywords
    }

    public var summary: String {
        "「結果」セクションに負の影響を示す語(デメリット・トレードオフ・リスク・懸念など)が1つも無ければ warning を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard let section = document.sections(matching: .consequences).first, !section.isEmpty else { return [] }

        let body = section.bodyLinesOutsideCodeBlocks.map(\.text).joined(separator: "\n").lowercased()
        guard !keywords.contains(where: { body.contains($0.lowercased()) }) else { return [] }

        return [
            Diagnostic(
                path: document.path,
                line: section.heading.line,
                severity: .warning,
                ruleID: id,
                message: "「結果」セクションに負の影響(デメリット・トレードオフ・リスク・懸念など)が書かれていません。決定の代償も記録してください。"
            )
        ]
    }
}
