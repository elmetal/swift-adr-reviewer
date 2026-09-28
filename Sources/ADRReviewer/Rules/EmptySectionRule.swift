/// Reports headings that have nothing but whitespace beneath them.
///
/// A section extends to the next heading of the same or a higher level, so a
/// heading whose only content is subsections is not considered empty.
public struct EmptySectionRule: Rule {
    public let id = "empty-section"

    public init() {}

    public var summary: String {
        "見出しの下に本文が無いセクション(次の同レベル以上の見出しまで空白のみ)を error として報告します。"
    }

    public func check(_ document: Document) -> [Diagnostic] {
        document.sections.filter(\.isEmpty).map { section in
            Diagnostic(
                path: document.path,
                line: section.heading.line,
                severity: .error,
                ruleID: id,
                message: "セクション「\(section.heading.title)」に本文がありません。内容を書くか見出しを削除してください。"
            )
        }
    }
}
