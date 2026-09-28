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
    ])

    public func review(_ document: Document) -> [Diagnostic] {
        rules.flatMap { $0.check(document) }
    }

    public func review(_ documents: [Document]) -> [Diagnostic] {
        documents.flatMap(review)
    }
}
