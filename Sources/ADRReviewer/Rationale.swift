/// Where a document states its reasons.
extension Document {
    /// Sentences that give a reason for the decision: every sentence of the
    /// 決定理由 sections, plus the sentences of the 決定 section that contain a
    /// reason marker (see ``DecisionRationaleRule/defaultMarkers``).
    public var reasonSentences: [Sentence] {
        let fromRationale = sections(matching: .rationale).flatMap(sentences(in:))
        let fromDecision = decisionSentences.filter { sentence in
            DecisionRationaleRule.defaultMarkers.contains(where: sentence.contains)
        }
        return (fromRationale + fromDecision).sorted { $0.line < $1.line }
    }

    /// Sentences of the 決定 section (subsections included).
    public var decisionSentences: [Sentence] {
        sections(matching: .decision).flatMap(sentences(in:))
    }

    /// Sentences of the 背景 section (subsections included).
    public var contextSentences: [Sentence] {
        sections(matching: .context).flatMap(sentences(in:))
    }

    /// The document title: the first level-1 heading, if any.
    public var title: Heading? {
        headings.first { $0.level == 1 }
    }
}
