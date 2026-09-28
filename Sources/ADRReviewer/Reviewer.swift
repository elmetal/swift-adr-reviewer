/// Runs a set of rules against documents.
public struct Reviewer: Sendable {
    public var rules: [any Rule]

    public init(rules: [any Rule]) {
        self.rules = rules
    }

    /// A reviewer with every built-in rule at its default settings.
    public static let `default` = Reviewer(rules: [
        DocumentLengthRule(),
        RequiredSectionsRule(),
        EmptySectionRule(),
        StatusRule(),
        AlternativesRule(),
        SentenceLengthRule(),
        ConsequencesDrawbacksRule(),
        AmbiguousDecisionRule(),
        DecisionRationaleRule(),
        WeakArgumentRule(),
        DrawbackMitigationRule(),
        CircularRationaleRule(),
        UngroundedRationaleRule(),
        AlternativeRejectionRule(),
        DecisionInAlternativesRule(),
        RationaleEvidenceRule(),
    ])

    /// The reviewer with `configuration` applied: disabled rules removed and severity
    /// overrides wrapped around the remaining rules. Rule order is preserved.
    ///
    /// - Throws: ``ConfigurationError/unknownRules(_:)`` when the configuration names
    ///   a rule this reviewer does not have.
    public func applying(_ configuration: Configuration) throws -> Reviewer {
        let known = Set(rules.map(\.id))
        let unknown = configuration.rules.keys.filter { !known.contains($0) }.sorted()
        guard unknown.isEmpty else { throw ConfigurationError.unknownRules(unknown) }

        return Reviewer(rules: rules.compactMap { rule in
            guard let setting = configuration.rules[rule.id] else { return rule }
            guard setting.enabled ?? true else { return nil }
            guard let severity = setting.severity else { return rule }
            return SeverityOverridingRule(base: rule, severity: severity)
        })
    }

    public func review(_ document: Document) -> [Diagnostic] {
        rules.flatMap { $0.check(document) }
    }

    public func review(_ documents: [Document]) -> [Diagnostic] {
        documents.flatMap(review)
    }
}
