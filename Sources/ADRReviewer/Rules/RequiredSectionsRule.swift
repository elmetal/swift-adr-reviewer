/// Reports ADRs that are missing the standard sections. See ``ADRSection`` for
/// how headings are matched.
public struct RequiredSectionsRule: Rule {
    public typealias Section = ADRSection

    /// Sections every ADR must have (`error` when missing) or should have (`warning` when missing).
    public static let defaultSections: [Section] = ADRSection.standard

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
        let headings = document.headings

        return sections.compactMap { section in
            guard !headings.contains(where: section.matches) else { return nil }

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
