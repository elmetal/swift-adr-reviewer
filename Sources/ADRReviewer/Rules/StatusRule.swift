/// Checks that the ステータス section holds one of the known status values.
///
/// The rule looks at the body of the first section matching ``ADRSection/status``.
/// A missing or empty section is left to ``RequiredSectionsRule`` and
/// ``EmptySectionRule``. When the status is 置き換え済み the body must also point
/// at the superseding ADR (a number or a link).
public struct StatusRule: Rule {
    /// A recognised status value and the spellings that denote it.
    public struct Status: Sendable, Equatable {
        public var name: String
        public var aliases: [String]

        public init(name: String, aliases: [String]) {
            self.name = name
            self.aliases = aliases
        }

        public static let proposed = Status(name: "提案中", aliases: ["提案中", "提案", "下書き", "Proposed", "Draft"])
        public static let accepted = Status(name: "承認済み", aliases: ["承認済み", "承認", "採用", "Accepted", "Approved"])
        public static let rejected = Status(name: "却下", aliases: ["却下", "Rejected"])
        public static let deprecated = Status(name: "廃止", aliases: ["廃止", "非推奨", "Deprecated"])
        public static let superseded = Status(name: "置き換え済み", aliases: ["置き換え済み", "置換済み", "置き換え", "Superseded"])

        public static let standard: [Status] = [.proposed, .accepted, .rejected, .deprecated, .superseded]

        func isMentioned(in text: String) -> Bool {
            aliases.contains { text.contains($0.lowercased()) }
        }
    }

    public let id = "status"

    public var statuses: [Status]

    public init(statuses: [Status] = Status.standard) {
        self.statuses = statuses
    }

    public var summary: String {
        let names = statuses.map(\.name).joined(separator: " / ")
        return "「ステータス」セクションの値が \(names) のいずれでもなければ warning、置き換え済みなのに置き換え先の ADR への参照が無ければ warning を報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        guard let section = document.sections(matching: .status).first, !section.isEmpty else { return [] }

        let body = section.bodyLines.joined(separator: "\n")
        let normalizedBody = body.lowercased()
        let firstContentLine = section.heading.line + 1
            + (section.bodyLines.firstIndex { !$0.allSatisfy(\.isWhitespace) } ?? 0)
        let mentioned = statuses.filter { $0.isMentioned(in: normalizedBody) }

        if mentioned.isEmpty {
            let names = statuses.map(\.name).joined(separator: " / ")
            return [
                Diagnostic(
                    path: document.path,
                    line: firstContentLine,
                    severity: .warning,
                    ruleID: id,
                    message: "ステータスの値を認識できません。\(names) のいずれかを書いてください。"
                )
            ]
        }

        if mentioned.contains(.superseded), !Self.referencesAnotherADR(body) {
            return [
                Diagnostic(
                    path: document.path,
                    line: firstContentLine,
                    severity: .warning,
                    ruleID: id,
                    message: "置き換え済みの場合は、置き換え先の ADR への参照(番号またはリンク)を書いてください。"
                )
            ]
        }

        return []
    }

    /// A decimal digit (ADR-0007, 7, ７) or a Markdown link counts as a reference.
    /// Only decimal digits count: kanji such as 参 or 拾 are numeric in Unicode but
    /// appear in ordinary prose (参照, 拾う).
    private static func referencesAnotherADR(_ text: String) -> Bool {
        text.contains("](") || text.unicodeScalars.contains { $0.properties.numericType == .decimal }
    }
}
