/// Flags reasons that merely restate the decision.
///
/// For every reason sentence (see ``Document/reasonSentences``) the rule measures
/// how much of it already appears in the decision (the other sentences of the 決定
/// section plus the document title), using character bigrams. When that share is
/// at least ``overlapThreshold`` and the sentence also contains a tautological
/// evaluation such as 良い, 最適 or ことにした, the reason is reported as circular.
public struct CircularRationaleRule: Rule {
    public static let defaultOverlapThreshold = 0.25

    /// Evaluations that assert the decision is right without saying why.
    public static let defaultTautologyMarkers: [String] = [
        "良い", "よい", "最適", "最善", "ベスト", "適切", "妥当", "正しい", "望ましい", "理想的",
        "ことにした", "決めた", "選んだ", "選択した", "採用した", "することにする",
        "best", "right choice", "optimal", "appropriate", "we decided", "we chose",
    ]

    public let id = "circular-rationale"

    /// Minimum share of the reason's bigrams that must occur in the decision.
    public var overlapThreshold: Double
    public var tautologyMarkers: [String]

    public init(
        overlapThreshold: Double = CircularRationaleRule.defaultOverlapThreshold,
        tautologyMarkers: [String] = CircularRationaleRule.defaultTautologyMarkers
    ) {
        self.overlapThreshold = overlapThreshold
        self.tautologyMarkers = tautologyMarkers
    }

    public var summary: String {
        "理由の文が決定の言い換え(決定と重なる語が多く、良い・最適・ことにした などの評価だけで根拠が無い)であれば warning を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        let decisionSentences = document.decisionSentences
        let titleBigrams = document.title.map { Bigrams.of($0.title) } ?? []

        return document.reasonSentences.compactMap { reason in
            guard let marker = tautologyMarkers.first(where: reason.contains) else { return nil }

            var decisionBigrams = titleBigrams
            for sentence in decisionSentences where sentence != reason {
                decisionBigrams.formUnion(Bigrams.of(sentence.text))
            }
            let overlap = Bigrams.containment(of: Bigrams.of(reason.text), in: decisionBigrams)
            guard overlap >= overlapThreshold else { return nil }

            return Diagnostic(
                path: document.path,
                line: reason.line,
                severity: .warning,
                ruleID: id,
                message: "理由「\(Self.excerpt(of: reason.text))」が決定の言い換えになっています(「\(marker)」)。決定が良い理由となる事実や制約を書いてください。"
            )
        }
    }

    private static func excerpt(of text: String, length: Int = 20) -> String {
        text.count <= length ? text : String(text.prefix(length)) + "…"
    }
}
