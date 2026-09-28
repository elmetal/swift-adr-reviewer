/// Checks that the reasoning is backed by at least one piece of evidence.
///
/// Looks at every reason sentence (see ``Document/reasonSentences``) and the
/// sentence right after each; if none of them carries backing (a link, a decimal
/// number, or a source/measurement marker, see ``Sentence/hasBacking``), the rule
/// warns once. Documents without reason sentences are left to
/// ``DecisionRationaleRule``.
public struct RationaleEvidenceRule: Rule {
    public let id = "rationale-evidence"

    public init() {}

    public var summary: String {
        "決定の理由のどの文にも(直後の文にも)数値・リンク・出典などの裏付けが無ければ warning を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        let reasons = document.reasonSentences
        guard !reasons.isEmpty else { return [] }

        let all = document.sentences
        let backed = reasons.contains { reason in
            if reason.hasBacking { return true }
            guard let index = all.firstIndex(of: reason), index + 1 < all.endIndex else { return false }
            return all[index + 1].hasBacking
        }
        guard !backed else { return [] }

        let anchor = document.sections(matching: .rationale).first?.heading
            ?? document.sections(matching: .decision).first?.heading
        return [
            Diagnostic(
                path: document.path,
                line: anchor?.line,
                severity: .warning,
                ruleID: id,
                message: "決定の理由に数値・リンク・出典などの裏付けが一つもありません。少なくとも主要な理由には計測結果や参照先を添えてください。"
            )
        ]
    }
}
