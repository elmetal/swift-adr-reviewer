/// Checks that the decision comes with a reason.
///
/// The rule is satisfied when the document has a section matching
/// ``ADRSection/rationale`` (決定理由 / 根拠 / Rationale …), or when at least one
/// prose sentence of the 決定 section (subsections included) contains a reason
/// marker such as ため, ので, なぜなら or したがって. A missing or empty decision
/// section is left to ``RequiredSectionsRule`` and ``EmptySectionRule``.
///
/// Detection is marker based, so a reason phrased without any marker is not
/// recognised; the rule therefore reports a warning rather than an error.
public struct DecisionRationaleRule: Rule {
    /// Expressions that introduce or conclude a reason. ASCII case is ignored.
    public static let defaultMarkers: [String] = [
        // 理由・目的を導く
        "ため", "ので", "なぜなら", "理由", "根拠", "ことから", "からだ", "からです", "から。", "から、",
        "を踏まえ", "を考慮", "観点から", "重視", "を優先",
        // 帰結を導く
        "したがって", "そのため", "よって", "ゆえに", "だから", "これにより",
        // 利点を挙げる
        "利点", "メリット", "強み", "優れ",
        // English
        "because", "since", "therefore", "so that", "in order to", "rationale", "reason", "benefit",
    ]

    public let id = "decision-rationale"

    public var markers: [String]

    public init(markers: [String] = DecisionRationaleRule.defaultMarkers) {
        self.markers = markers
    }

    public var summary: String {
        "「決定理由」セクションが無く、「決定」セクションの文に理由を示す表現(ため・ので・なぜなら・したがって など)も無ければ warning を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard document.sections(matching: .rationale).isEmpty else { return [] }
        guard let decision = document.sections(matching: .decision).first, !decision.isEmpty else { return [] }

        let hasReason = document.sentences(in: decision).contains { sentence in
            markers.contains(where: sentence.contains)
        }
        guard !hasReason else { return [] }

        return [
            Diagnostic(
                path: document.path,
                line: decision.heading.line,
                severity: .warning,
                ruleID: id,
                message: "「決定」に理由が書かれていません。なぜその選択をしたのかを「〜のため」「〜なので」「なぜなら」などで説明するか、「決定理由」セクションを追加してください。"
            )
        ]
    }
}
