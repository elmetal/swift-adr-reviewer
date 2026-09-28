/// Checks that every option in 検討した選択肢 says why it was (not) chosen.
///
/// Each option enumerated by ``Document/alternativeOptions(in:)`` must, within
/// its own lines, either give a reason (a reason marker such as ため / ので, or a
/// pro/con keyword such as 利点 / 欠点 / デメリット) or be marked as the chosen one
/// (採用 / 選定 / selected, without a negation). Sections that use a table are
/// not checked, and a missing or empty section is left to the existing rules.
public struct AlternativeRejectionRule: Rule {
    /// Expressions that justify keeping or dropping an option.
    public static let defaultReasonMarkers: [String] =
        DecisionRationaleRule.defaultMarkers + ConsequencesDrawbacksRule.defaultKeywords
        + ["不採用", "却下", "見送", "採用しない", "採用せず", "pros", "rejected", "not chosen"]

    /// Expressions that mark the option that was chosen.
    public static let defaultChosenMarkers: [String] = ["採用", "選定", "選択", "決定", "chosen", "selected", "adopt"]
    /// Negations that turn a chosen marker into a rejection.
    public static let defaultNegations: [String] = [
        "不採用", "採用しない", "採用せず", "採用は見送", "採用を見送", "採用しなかった", "選ばない", "選ばなかった",
        "not adopt", "not chosen", "not selected", "rejected",
    ]

    public let id = "alternative-rejection"

    public var reasonMarkers: [String]
    public var chosenMarkers: [String]
    public var negations: [String]

    public init(
        reasonMarkers: [String] = AlternativeRejectionRule.defaultReasonMarkers,
        chosenMarkers: [String] = AlternativeRejectionRule.defaultChosenMarkers,
        negations: [String] = AlternativeRejectionRule.defaultNegations
    ) {
        self.reasonMarkers = reasonMarkers
        self.chosenMarkers = chosenMarkers
        self.negations = negations
    }

    public var summary: String {
        "「検討した選択肢」の各項目に、却下理由や利点・欠点(ため・ので・欠点・デメリット など)も採用の明記も無ければ warning を報告します。表で比較している場合は対象外です。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard let section = document.sections(matching: .alternatives).first, !section.isEmpty else { return [] }
        if section.containsTable { return [] }

        return document.alternativeOptions(in: section).compactMap { option in
            let text = document.lines[(option.lineRange.lowerBound - 1)...(option.lineRange.upperBound - 1)]
                .joined(separator: "\n")
                .filter { !$0.isWhitespace }
                .lowercased()

            let hasReason = reasonMarkers.contains { text.contains(Self.normalize($0)) }
            let isChosen = chosenMarkers.contains { text.contains(Self.normalize($0)) }
                && !negations.contains { text.contains(Self.normalize($0)) }
            guard !hasReason, !isChosen else { return nil }

            return Diagnostic(
                path: document.path,
                line: option.line,
                severity: .warning,
                ruleID: id,
                message: "選択肢「\(Self.excerpt(of: option.title))」に却下理由も利点・欠点も書かれていません。なぜ選ばなかったのか(または選んだのか)を書いてください。"
            )
        }
    }

    private static func normalize(_ expression: String) -> String {
        expression.filter { !$0.isWhitespace }.lowercased()
    }

    private static func excerpt(of text: String, length: Int = 20) -> String {
        text.count <= length ? text : String(text.prefix(length)) + "…"
    }
}
