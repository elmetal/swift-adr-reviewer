/// Reports ADRs that are missing the standard sections.
///
/// Sections are recognised by Markdown ATX headings. A heading matches a section
/// when its title contains any of the section's aliases, so `## 背景と課題` or
/// `## 2. 決定事項` both count. Matching ignores ASCII case.
public struct RequiredSectionsRule: Rule {
    /// A section the rule looks for.
    public struct Section: Sendable, Equatable {
        /// Display name used in diagnostics.
        public var name: String
        /// Heading texts that identify the section.
        public var aliases: [String]
        /// Severity reported when the section is missing.
        public var severity: Severity

        public init(name: String, aliases: [String], severity: Severity) {
            self.name = name
            self.aliases = aliases
            self.severity = severity
        }
    }

    /// Sections every ADR must have (`error` when missing) or should have (`warning` when missing).
    public static let defaultSections: [Section] = [
        Section(name: "ステータス", aliases: ["ステータス", "状態", "Status"], severity: .warning),
        Section(name: "背景", aliases: ["背景", "コンテキスト", "文脈", "状況", "Context"], severity: .error),
        Section(name: "決定", aliases: ["決定", "Decision"], severity: .error),
        Section(name: "結果", aliases: ["結果", "影響", "帰結", "Consequences"], severity: .error),
        Section(
            name: "検討した選択肢",
            aliases: ["選択肢", "代替案", "候補", "Alternatives", "Options", "Considered"],
            severity: .warning
        ),
    ]

    public let id = "required-sections"

    public var sections: [Section]

    public init(sections: [Section] = RequiredSectionsRule.defaultSections) {
        self.sections = sections
    }

    public var summary: String {
        let required = sections.filter { $0.severity == .error }.map(\.name).joined(separator: "・")
        let recommended = sections.filter { $0.severity == .warning }.map(\.name).joined(separator: "・")
        var text = "Markdown の見出しから、必須セクション(\(required))が無ければ error"
        if !recommended.isEmpty {
            text += "、推奨セクション(\(recommended))が無ければ warning"
        }
        return text + " を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        let titles = document.headings.map { $0.title.lowercased() }

        return sections.compactMap { section in
            let present = titles.contains { title in
                section.aliases.contains { title.contains($0.lowercased()) }
            }
            guard !present else { return nil }

            let kind = section.severity == .error ? "必須" : "推奨"
            return Diagnostic(
                path: document.path,
                severity: section.severity,
                ruleID: id,
                message: "\(kind)セクション「\(section.name)」の見出しが見つかりません(認識する見出し: \(section.aliases.joined(separator: " / ")))。"
            )
        }
    }
}
