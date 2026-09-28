/// How serious a finding is.
public enum Severity: String, Sendable, Comparable, CaseIterable {
    case warning
    case error

    private var rank: Int {
        switch self {
        case .warning: 0
        case .error: 1
        }
    }

    public static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// A single finding reported by a rule.
public struct Diagnostic: Sendable, Equatable {
    /// Path of the document the finding belongs to.
    public var path: String
    /// 1-based line number, or `nil` when the finding applies to the whole document.
    public var line: Int?
    public var severity: Severity
    /// Identifier of the rule that produced this finding.
    public var ruleID: String
    public var message: String

    public init(path: String, line: Int? = nil, severity: Severity, ruleID: String, message: String) {
        self.path = path
        self.line = line
        self.severity = severity
        self.ruleID = ruleID
        self.message = message
    }
}

extension Diagnostic {
    /// Compiler-style single-line representation: `path[:line]: severity: message [rule-id]`.
    public var formatted: String {
        var location = path
        if let line {
            location += ":\(line)"
        }
        return "\(location): \(severity.rawValue): \(message) [\(ruleID)]"
    }
}
