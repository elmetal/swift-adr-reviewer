/// Checks that the 結果 section records the downsides of the decision, not only
/// its benefits.
///
/// At least one sentence of the section (subsections included, code blocks
/// excluded) must state a drawback, or a subheading of the section must name one.
/// A sentence states a drawback when it contains a drawback keyword (デメリット,
/// リスク, …) or a cost expression (必要が生じる, 失われる, 依存する, …) that is not
/// negated in place (リスクがなくなる, 懸念は解消, no risk …). A missing or empty
/// section is left to ``RequiredSectionsRule`` and ``EmptySectionRule``.
public struct ConsequencesDrawbacksRule: Rule {
    /// Words that name a downside explicitly. ASCII case is ignored.
    public static let defaultKeywords: [String] = [
        "デメリット", "トレードオフ", "リスク", "懸念", "欠点", "短所", "制約", "代償", "課題",
        "負の影響", "悪い点", "悪化", "犠牲", "マイナス", "弱み",
        "trade-off", "tradeoff", "drawback", "downside", "risk", "cons",
    ]

    /// Expressions that describe a cost or loss without naming it as a drawback.
    /// Used by this rule only: such sentences state accepted costs rather than
    /// risks that call for a mitigation.
    public static let defaultCostExpressions: [String] = [
        "必要が生じ", "必要がある", "必要になる", "必要となる", "失われ", "失う", "依存する", "依存が", "依存に",
        "できない", "できなくな", "負担", "手間", "増加", "増える", "遅くな", "複雑", "コスト",
        "cost", "slower", "harder", "depends on", "dependency", "lose", "cannot", "no longer",
    ]

    /// Suffixes that, right after a keyword, negate it: リスク|がなくなる, 懸念|は解消 …
    public static let defaultNegatingSuffixes: [String] = [
        "がない", "はない", "が無い", "は無い", "がなくな", "はなくな", "もない", "も無い", "はほぼない", "は殆どない",
        "を排除", "を解消", "が解消", "は解消", "を回避", "を避け", "が減", "を減", "を下げ", "が下が",
        "を低減", "が低減", "を抑え", "が小さ", "は小さ", "は低い", "が低い", "から解放", "を取り除", "が取り除",
        "がかからな", "はかからな", "は不要", "が不要", "は増えな", "が増えな", "はな", "がな",
    ]

    /// Sentence texts (whitespace removed, lowercase) that negate an English keyword.
    public static let defaultNegatedPhrases: [String] = [
        "norisk", "withoutrisk", "riskfree", "eliminatestherisk", "removestherisk", "reducestherisk",
        "nodrawback", "nodownside", "notrade-off", "nocost", "nolongerdepends",
    ]

    public let id = "consequences-drawbacks"

    public var keywords: [String]
    public var costExpressions: [String]

    public init(
        keywords: [String] = ConsequencesDrawbacksRule.defaultKeywords,
        costExpressions: [String] = ConsequencesDrawbacksRule.defaultCostExpressions
    ) {
        self.keywords = keywords
        self.costExpressions = costExpressions
    }

    public var summary: String {
        "「結果」セクションに負の影響を示す記述(デメリット・トレードオフ・リスク・懸念、失われる・必要が生じる など)が1つも無ければ warning を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard let section = document.sections(matching: .consequences).first, !section.isEmpty else { return [] }

        let expressions = keywords + costExpressions
        let inSentences = document.sentences(in: section).contains { Self.statesDrawback($0, keywords: expressions) != nil }
        let inSubheadings = document.sections.contains { sub in
            section.bodyLineRange.contains(sub.heading.line)
                && keywords.contains { sub.heading.title.lowercased().contains($0.lowercased()) }
        }
        guard !inSentences, !inSubheadings else { return [] }

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

    /// The first keyword that `sentence` states as a drawback, i.e. that occurs at least
    /// once without a negating suffix right after it, or `nil`.
    static func statesDrawback(_ sentence: Sentence, keywords: [String]) -> String? {
        let text = sentence.text.lowercased()
        guard !defaultNegatedPhrases.contains(where: text.contains) else { return nil }

        return keywords.first { keyword in
            let needle = keyword.filter { !$0.isWhitespace }.lowercased()
            guard !needle.isEmpty else { return false }
            var searchStart = text.startIndex
            while let range = text.range(of: needle, range: searchStart..<text.endIndex) {
                let rest = text[range.upperBound...]
                if !defaultNegatingSuffixes.contains(where: rest.hasPrefix) { return true }
                searchStart = range.upperBound
            }
            return false
        }
    }
}
