/// One of the standard ADR sections, identified by heading text.
///
/// A heading matches when its title contains any of the aliases, so `## 背景と課題`
/// or `## 2. 決定事項` both count. Matching ignores ASCII case.
public struct ADRSection: Sendable, Equatable {
    /// Display name used in diagnostics.
    public var name: String
    /// Heading texts that identify the section.
    public var aliases: [String]
    /// Severity reported by ``RequiredSectionsRule`` when the section is missing.
    public var severity: Severity
    /// Heading texts that disqualify a match even when an alias is present, so that
    /// e.g. 決定理由 is not taken for the 決定 section.
    public var exclusions: [String]

    public init(name: String, aliases: [String], severity: Severity, exclusions: [String] = []) {
        self.name = name
        self.aliases = aliases
        self.severity = severity
        self.exclusions = exclusions
    }

    public func matches(_ heading: Heading) -> Bool {
        let title = heading.title.lowercased()
        guard aliases.contains(where: { title.contains($0.lowercased()) }) else { return false }
        return !exclusions.contains { title.contains($0.lowercased()) }
    }

    public static let status = ADRSection(
        name: "ステータス", aliases: ["ステータス", "状態", "Status"], severity: .warning
    )
    public static let context = ADRSection(
        name: "背景", aliases: ["背景", "コンテキスト", "文脈", "状況", "Context"], severity: .error
    )
    public static let decision = ADRSection(
        name: "決定", aliases: ["決定", "Decision"], severity: .error, exclusions: rationaleAliases
    )
    public static let consequences = ADRSection(
        name: "結果", aliases: ["結果", "影響", "帰結", "Consequences"], severity: .error
    )
    public static let alternatives = ADRSection(
        name: "検討した選択肢",
        aliases: ["選択肢", "代替案", "候補", "Alternatives", "Options", "Considered"],
        severity: .warning
    )

    /// An optional section that explains why the decision was made. Not part of
    /// ``standard``: a rationale may instead be written inside the decision section.
    public static let rationale = ADRSection(name: "決定理由", aliases: rationaleAliases, severity: .warning)

    private static let rationaleAliases = ["理由", "根拠", "Rationale", "Justification", "Basis", "Reason", "Why"]

    /// The standard sections, in the order they usually appear.
    public static let standard: [ADRSection] = [.status, .context, .decision, .consequences, .alternatives]
}

extension Document {
    /// Sections whose heading matches `section`, in order of appearance.
    public func sections(matching section: ADRSection) -> [Section] {
        sections.filter { section.matches($0.heading) }
    }
}
