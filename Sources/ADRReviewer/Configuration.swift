import Foundation

/// User configuration, read from `.adr-reviewer.json`.
///
/// ```json
/// {
///   "rules": {
///     "rationale-evidence": false,
///     "sentence-length": { "severity": "error" },
///     "document-length": { "enabled": true, "severity": "warning" }
///   }
/// }
/// ```
///
/// A rule setting is either a boolean (enabled or not) or an object with optional
/// `enabled` and `severity` keys. Rules not mentioned keep their defaults.
public struct Configuration: Sendable, Equatable, Codable {
    /// The conventional file name, looked up from the working directory upwards.
    public static let fileName = ".adr-reviewer.json"

    /// Settings keyed by rule id.
    public var rules: [String: RuleSetting]

    public init(rules: [String: RuleSetting] = [:]) {
        self.rules = rules
    }

    public static let empty = Configuration()

    /// Parses the JSON text of a configuration file.
    public init(json data: Data) throws {
        self = try JSONDecoder().decode(Configuration.self, from: data)
    }

    /// Reads and parses the file at `url`.
    public init(contentsOf url: URL) throws {
        try self.init(json: Data(contentsOf: url))
    }

    /// Looks for ``fileName`` in `directory` and each of its ancestors, nearest first.
    public static func locate(startingAt directory: URL) -> URL? {
        // Walk the path components explicitly: URL.deletingLastPathComponent() on "/"
        // yields "/.." rather than "/", which would loop forever.
        var components = directory.standardizedFileURL.pathComponents
        while !components.isEmpty {
            let candidate = NSString.path(withComponents: components + [fileName])
            if FileManager.default.fileExists(atPath: candidate) { return URL(fileURLWithPath: candidate) }
            components.removeLast()
        }
        return nil
    }

    enum CodingKeys: String, CodingKey { case rules }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rules = try container.decodeIfPresent([String: RuleSetting].self, forKey: .rules) ?? [:]
    }
}

/// How one rule is adjusted.
public struct RuleSetting: Sendable, Equatable, Codable {
    /// `false` removes the rule; `nil` keeps the default (enabled).
    public var enabled: Bool?
    /// Replaces the severity of every diagnostic the rule reports; `nil` keeps the default.
    public var severity: Severity?

    public init(enabled: Bool? = nil, severity: Severity? = nil) {
        self.enabled = enabled
        self.severity = severity
    }

    enum CodingKeys: String, CodingKey { case enabled, severity }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let flag = try? single.decode(Bool.self) {
            self.init(enabled: flag)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            enabled: try container.decodeIfPresent(Bool.self, forKey: .enabled),
            severity: try container.decodeIfPresent(Severity.self, forKey: .severity)
        )
    }
}

public enum ConfigurationError: Error, Equatable, CustomStringConvertible {
    /// The configuration names rule ids that do not exist.
    case unknownRules([String])

    public var description: String {
        switch self {
        case .unknownRules(let ids):
            "設定に存在しないルールがあります: \(ids.joined(separator: ", "))"
        }
    }
}

/// A rule whose diagnostics are reported with a fixed severity.
struct SeverityOverridingRule: Rule {
    var base: any Rule
    var severity: Severity

    var id: String { base.id }
    var summary: String { base.summary }

    func check(_ document: Document) -> [Diagnostic] {
        base.check(document).map { diagnostic in
            var overridden = diagnostic
            overridden.severity = severity
            return overridden
        }
    }
}
