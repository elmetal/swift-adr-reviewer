/// Checks that every drawback recorded in the 結果 section is addressed.
///
/// A sentence of the 結果 section (subsections included) that states a drawback
/// keyword (see ``ConsequencesDrawbacksRule/defaultKeywords``; a negated mention
/// such as リスクがなくなる does not count) must be followed by
/// a mitigation: the same sentence or the next one contains a mitigation marker
/// such as 対策, 軽減, 許容 or 受け入れる. Alternatively, a subsection of 結果 whose
/// heading is a mitigation marker (e.g. `### 対策`) with a non-empty body counts as
/// addressing all drawbacks. A missing or empty 結果 section is left to the
/// existing rules.
public struct DrawbackMitigationRule: Rule {
    /// Expressions that show a drawback is being mitigated, accepted or monitored.
    public static let defaultMitigationMarkers: [String] = [
        "対策", "対応策", "対処", "軽減", "緩和", "低減", "抑え", "抑制", "許容", "受け入れ", "受容", "容認",
        "回避", "解消", "補う", "補完", "カバー", "備え", "監視", "モニタ", "フォロー", "見直す", "再検討",
        "mitigat", "accept", "workaround", "address", "monitor", "tolerat", "offset",
    ]

    public let id = "drawback-mitigation"

    public var drawbackKeywords: [String]
    public var mitigationMarkers: [String]

    public init(
        drawbackKeywords: [String] = ConsequencesDrawbacksRule.defaultKeywords,
        mitigationMarkers: [String] = DrawbackMitigationRule.defaultMitigationMarkers
    ) {
        self.drawbackKeywords = drawbackKeywords
        self.mitigationMarkers = mitigationMarkers
    }

    public var summary: String {
        "「結果」セクションでリスク・デメリットを述べた文の直後に対策・許容の記述(対策・軽減・許容・受け入れる など)が無ければ warning を報告します。「対策」小見出しがあれば対象外です。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard let section = document.sections(matching: .consequences).first, !section.isEmpty else { return [] }
        guard !hasMitigationSubsection(of: section, in: document) else { return [] }

        let sentences = document.sentences(in: section)
        return sentences.indices.compactMap { index in
            let sentence = sentences[index]
            guard let keyword = ConsequencesDrawbacksRule.statesDrawback(sentence, keywords: drawbackKeywords) else { return nil }
            if isMitigation(sentence) { return nil }
            if index + 1 < sentences.endIndex, isMitigation(sentences[index + 1]) { return nil }

            return Diagnostic(
                path: document.path,
                line: sentence.line,
                severity: .warning,
                ruleID: id,
                message: "\(keyword)「\(Self.excerpt(of: sentence.text))」に対策や許容の記述がありません。どう軽減するか、または受け入れるのかを続けて書いてください。"
            )
        }
    }

    private func isMitigation(_ sentence: Sentence) -> Bool {
        mitigationMarkers.contains(where: sentence.contains)
    }

    private func hasMitigationSubsection(of section: Section, in document: Document) -> Bool {
        document.sections.contains { candidate in
            candidate.heading.level > section.heading.level
                && section.bodyLineRange.contains(candidate.heading.line)
                && !candidate.isEmpty
                && mitigationMarkers.contains { candidate.heading.title.lowercased().contains($0.lowercased()) }
        }
    }

    private static func excerpt(of text: String, length: Int = 20) -> String {
        text.count <= length ? text : String(text.prefix(length)) + "…"
    }
}
