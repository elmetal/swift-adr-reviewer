/// Checks that the chosen option appears among the alternatives considered.
///
/// The decision is represented by the character bigrams of the document title and
/// the sentences of the 決定 section. Each option of 検討した選択肢 (see
/// ``Document/alternativeOptions(in:)``) is compared by its title, after removing
/// the bigrams that occur in two or more option titles (boilerplate such as
/// 「を採用する」 or 「案A:」 does not distinguish options). The rule is satisfied when
/// at least one option shares enough of its remaining bigrams with the decision.
/// Sections compared in a table (in the section itself or its enclosing section),
/// and missing or empty sections, are not checked.
public struct DecisionInAlternativesRule: Rule {
    /// Minimum share of the smaller bigram set that must be shared.
    public static let defaultMatchThreshold = 0.4
    /// Minimum number of shared bigrams, so that a single common bigram is not a match.
    public static let defaultMinimumSharedBigrams = 2

    public let id = "decision-in-alternatives"

    public var matchThreshold: Double
    public var minimumSharedBigrams: Int

    public init(
        matchThreshold: Double = DecisionInAlternativesRule.defaultMatchThreshold,
        minimumSharedBigrams: Int = DecisionInAlternativesRule.defaultMinimumSharedBigrams
    ) {
        self.matchThreshold = matchThreshold
        self.minimumSharedBigrams = minimumSharedBigrams
    }

    public var summary: String {
        "決定した案(タイトルと「決定」の文)が「検討した選択肢」のどの項目とも一致しなければ warning を報告します(文字 bigram の重なりで判定)。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard let section = document.sections(matching: .alternatives).first, !section.isEmpty else { return [] }
        if document.comparesOptionsInTable(section) { return [] }
        let options = document.alternativeOptions(in: section)
        guard !options.isEmpty else { return [] }

        var decision = document.title.map { Bigrams.of($0.title) } ?? []
        for sentence in document.decisionSentences {
            decision.formUnion(Bigrams.of(sentence.text))
        }
        guard !decision.isEmpty else { return [] }

        let titleBigrams = options.map { Bigrams.of($0.title) }
        var seen: Set<String> = []
        var boilerplate: Set<String> = []
        for bigrams in titleBigrams {
            boilerplate.formUnion(bigrams.intersection(seen))
            seen.formUnion(bigrams)
        }

        let matched = titleBigrams.contains { title in
            let bigrams = title.subtracting(boilerplate)
            let shared = bigrams.intersection(decision).count
            guard shared >= minimumSharedBigrams, !bigrams.isEmpty else { return false }
            return Double(shared) / Double(min(bigrams.count, decision.count)) >= matchThreshold
        }
        guard !matched else { return [] }

        return [
            Diagnostic(
                path: document.path,
                line: section.heading.line,
                severity: .warning,
                ruleID: id,
                message: "決定した案が「検討した選択肢」のどの項目とも一致しません。選んだ案も選択肢の一つとして挙げ、他の案と同じ観点で比較してください。"
            )
        ]
    }
}
