/// Flags well-known weak argument patterns in the decision and rationale sections
/// when they come without backing.
///
/// Each sentence of the sections matching ``ADRSection/decision`` and
/// ``ADRSection/rationale`` is searched for the configured patterns (appeal to
/// popularity, authority, novelty, sunk cost). A match is reported only when
/// neither that sentence nor the one right after it has backing: a link, a
/// number, or a reference to a source or measurement (see ``Sentence/hasBacking``).
public struct WeakArgumentRule: Rule {
    /// A family of weak argument, with the expressions that signal it.
    public struct Pattern: Sendable, Equatable {
        public var name: String
        public var expressions: [String]

        public init(name: String, expressions: [String]) {
            self.name = name
            self.expressions = expressions
        }

        public static let popularity = Pattern(
            name: "多数派への訴え",
            expressions: [
                "みんな使っ", "皆が使っ", "多くの企業", "多くのプロジェクト", "多くの現場", "広く使われ", "広く採用",
                "デファクト", "業界標準", "一般的だから", "一般的なので", "主流", "人気", "流行",
                "popular", "widely used", "widely adopted", "de facto", "industry standard", "everyone uses",
            ]
        )
        public static let authority = Pattern(
            name: "権威への訴え",
            expressions: [
                "が推奨", "も推奨", "推奨している", "推奨されて", "公式が", "有識者", "専門家", "有名な", "著名な",
                "recommended by", "experts", "well-known",
            ]
        )
        public static let novelty = Pattern(
            name: "新しさへの訴え",
            expressions: [
                "新しいから", "新しいので", "新しいため", "最新", "モダン", "時代遅れ", "古いから", "古いので", "古いため", "レガシー",
                "newer", "modern", "latest", "outdated", "legacy",
            ]
        )
        public static let sunkCost = Pattern(
            name: "埋没費用",
            expressions: [
                "すでに投資", "既に投資", "これまでの投資", "せっかく", "作ってしまった", "作ったので", "作ったため",
                "既に作", "すでに作", "無駄になる", "もったいない",
                "already invested", "sunk cost", "would be wasted",
            ]
        )

        public static let standard: [Pattern] = [.popularity, .authority, .novelty, .sunkCost]
    }

    public let id = "weak-argument"

    public var patterns: [Pattern]

    public init(patterns: [Pattern] = Pattern.standard) {
        self.patterns = patterns
    }

    public var summary: String {
        let names = patterns.map(\.name).joined(separator: "・")
        return "「決定」「決定理由」セクションの文に弱い論証のパターン(\(names))があり、その文にも直後の文にも裏付け(リンク・数値・出典)が無ければ warning を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        let sections = document.sections(matching: .decision) + document.sections(matching: .rationale)

        return sections.flatMap { section -> [Diagnostic] in
            let sentences = document.sentences(in: section)
            return sentences.indices.compactMap { index in
                let sentence = sentences[index]
                let found = patterns.compactMap { pattern -> (Pattern, String)? in
                    guard let expression = pattern.expressions.first(where: sentence.contains) else { return nil }
                    return (pattern, expression)
                }
                guard !found.isEmpty else { return nil }

                let next = index + 1 < sentences.endIndex ? sentences[index + 1] : nil
                guard !sentence.hasBacking, !(next?.hasBacking ?? false) else { return nil }

                let described = found.map { "\($0.0.name)「\($0.1)」" }.joined(separator: "、")
                return Diagnostic(
                    path: document.path,
                    line: sentence.line,
                    severity: .warning,
                    ruleID: id,
                    message: "根拠が弱い可能性があります(\(described))。「\(Self.excerpt(of: sentence.text))」に、出典のリンク・数値・計測結果などの裏付けを添えてください。"
                )
            }
        }
    }

    private static func excerpt(of text: String, length: Int = 20) -> String {
        text.count <= length ? text : String(text.prefix(length)) + "…"
    }
}
