/// Checks that the 検討した選択肢 section actually compares several options.
///
/// Options are those enumerated by ``Document/alternativeOptions(in:)``: list items
/// at the indentation of the first list item plus direct subheadings. A Markdown
/// table anywhere in the section is taken as a comparison and satisfies the rule on
/// its own. A missing or empty section is left to ``RequiredSectionsRule`` and
/// ``EmptySectionRule``.
public struct AlternativesRule: Rule {
    public static let defaultMinimumOptions = 2

    public let id = "alternatives"

    /// Fewer options than this produces a warning.
    public var minimumOptions: Int

    public init(minimumOptions: Int = AlternativesRule.defaultMinimumOptions) {
        precondition(minimumOptions >= 1, "minimumOptions must be at least 1")
        self.minimumOptions = minimumOptions
    }

    public var summary: String {
        "「検討した選択肢」セクションに、リスト項目または小見出しが\(minimumOptions)つ未満で、表も無ければ warning を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard let section = document.sections(matching: .alternatives).first, !section.isEmpty else { return [] }
        if section.containsTable { return [] }

        let options = document.alternativeOptions(in: section).count
        guard options < minimumOptions else { return [] }

        return [
            Diagnostic(
                path: document.path,
                line: section.heading.line,
                severity: .warning,
                ruleID: id,
                message: "検討した選択肢が\(options)個しか見つかりません。比較した選択肢を\(minimumOptions)つ以上、リスト・小見出し・表のいずれかで書いてください。"
            )
        ]
    }
}
