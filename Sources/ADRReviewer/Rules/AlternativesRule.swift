/// Checks that the 検討した選択肢 section actually compares several options.
///
/// Options are counted as list items (`-`, `*`, `+`, `1.`, `1)`) at the indentation
/// of the first list item, plus direct subheadings of the section. A Markdown table anywhere in the section
/// is taken as a comparison and satisfies the rule on its own. Fenced code
/// blocks are ignored. A missing or empty section is left to
/// ``RequiredSectionsRule`` and ``EmptySectionRule``.
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

        let lines = section.bodyLinesOutsideCodeBlocks.map(\.text)
        if lines.contains(where: Self.isTableRow) { return [] }

        let listItems = Self.topLevelListItemCount(lines)
        let subheadings = Self.directSubheadings(of: section, in: document).count
        let options = listItems + subheadings
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

    private static func isTableRow(_ line: String) -> Bool {
        line.drop(while: { $0 == " " || $0 == "\t" }).hasPrefix("|")
    }

    /// Counts list items at the indentation of the first list item; deeper items are
    /// nested details (pros, cons, notes) of an option rather than options themselves.
    private static func topLevelListItemCount(_ lines: [String]) -> Int {
        let indents = lines.compactMap(listItemIndent)
        guard let base = indents.first else { return 0 }
        return indents.filter { $0 == base }.count
    }

    /// The indentation of a list item line, or `nil` when the line is not a list item.
    private static func listItemIndent(_ line: String) -> Int? {
        let indent = line.prefix { $0 == " " || $0 == "\t" }
        let content = line.dropFirst(indent.count)
        let width = indent.reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }

        for marker in ["- ", "* ", "+ "] where content.hasPrefix(marker) { return width }
        let digits = content.prefix { $0.isASCII && $0.isNumber }
        guard !digits.isEmpty else { return nil }
        let rest = content.dropFirst(digits.count)
        return rest.hasPrefix(". ") || rest.hasPrefix(") ") ? width : nil
    }

    private static func directSubheadings(of section: Section, in document: Document) -> [Heading] {
        let endLine = section.heading.line + section.bodyLines.count
        let nested = document.headings.filter {
            $0.line > section.heading.line && $0.line <= endLine && $0.level > section.heading.level
        }
        guard let shallowest = nested.map(\.level).min() else { return [] }
        return nested.filter { $0.level == shallowest }
    }
}
