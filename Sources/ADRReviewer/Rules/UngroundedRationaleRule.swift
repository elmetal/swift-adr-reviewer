/// Flags reasons that are not connected to the context.
///
/// For every reason sentence (see ``Document/reasonSentences``) the rule removes
/// the character bigrams that belong to the decision (title and 決定 sentences) and
/// measures how much of the rest occurs in the 背景 section. A reason whose share
/// is below ``groundingThreshold`` is reported unless it, or the sentence right
/// after it, carries backing (a link, a number, a source). Very short remainders are skipped, and so is
/// the whole rule when the document has no 背景 sentences.
public struct UngroundedRationaleRule: Rule {
    public static let defaultGroundingThreshold = 0.2
    public static let defaultMinimumBigrams = 8

    public let id = "ungrounded-rationale"

    /// Minimum share of the reason's own bigrams that must occur in the context.
    public var groundingThreshold: Double
    /// Reasons with fewer own bigrams than this are not judged.
    public var minimumBigrams: Int

    public init(
        groundingThreshold: Double = UngroundedRationaleRule.defaultGroundingThreshold,
        minimumBigrams: Int = UngroundedRationaleRule.defaultMinimumBigrams
    ) {
        self.groundingThreshold = groundingThreshold
        self.minimumBigrams = minimumBigrams
    }

    public var summary: String {
        "理由の文が「背景」の記述とほとんど重ならず、リンク・数値・出典などの裏付けも無ければ warning を報告します(文字 bigram の重なりで判定)。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        let contextBigrams = document.contextSentences.reduce(into: Set<String>()) { $0.formUnion(Bigrams.of($1.text)) }
        guard !contextBigrams.isEmpty else { return [] }

        var decisionBigrams = document.title.map { Bigrams.of($0.title) } ?? []
        for sentence in document.decisionSentences {
            decisionBigrams.formUnion(Bigrams.of(sentence.text))
        }

        let all = document.sentences
        return document.reasonSentences.compactMap { reason in
            guard !reason.hasBacking else { return nil }
            if let index = all.firstIndex(of: reason), index + 1 < all.endIndex, all[index + 1].hasBacking {
                return nil
            }

            let own = Bigrams.of(reason.text).subtracting(decisionBigrams)
            guard own.count >= minimumBigrams else { return nil }
            let grounding = Bigrams.containment(of: own, in: contextBigrams)
            guard grounding < groundingThreshold else { return nil }

            return Diagnostic(
                path: document.path,
                line: reason.line,
                severity: .warning,
                ruleID: id,
                message: "理由「\(Self.excerpt(of: reason.text))」は「背景」に書かれていない事柄に基づいています。背景に事実として書くか、リンク・数値などの裏付けを添えてください。"
            )
        }
    }

    private static func excerpt(of text: String, length: Int = 20) -> String {
        text.count <= length ? text : String(text.prefix(length)) + "…"
    }
}
