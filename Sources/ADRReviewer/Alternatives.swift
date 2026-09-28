/// One option listed in the 検討した選択肢 section.
public struct AlternativeOption: Sendable, Equatable {
    /// The option's label: a subheading title, or a list item's first line without its marker.
    public var title: String
    /// 1-based line of the subheading or list item.
    public var line: Int
    /// 1-based lines of the option, including its subheading or item line and everything
    /// that belongs to it (nested items, continuation lines, subsection body).
    public var lineRange: ClosedRange<Int>

    public init(title: String, line: Int, lineRange: ClosedRange<Int>) {
        self.title = title
        self.line = line
        self.lineRange = lineRange
    }
}

extension Section {
    /// `true` when a line outside code blocks starts with `|`.
    public var containsTable: Bool {
        bodyLinesOutsideCodeBlocks.contains { $0.text.drop(while: { $0 == " " || $0 == "\t" }).hasPrefix("|") }
    }
}

extension Document {
    /// The options enumerated in `section`: list items at the indentation of the first
    /// list item, plus the section's direct subheadings. Nested items are details of an
    /// option, not options. Tables are not enumerated; see ``Section/containsTable``.
    public func alternativeOptions(in section: Section) -> [AlternativeOption] {
        (listItemOptions(in: section) + subheadingOptions(in: section)).sorted { $0.line < $1.line }
    }

    private func listItemOptions(in section: Section) -> [AlternativeOption] {
        let lines = section.bodyLinesOutsideCodeBlocks
        let items = lines.compactMap { entry -> (line: Int, indent: Int, text: String)? in
            guard let (indent, text) = Self.listItem(entry.text) else { return nil }
            return (entry.line, indent, text)
        }
        guard let base = items.first?.indent else { return [] }
        let topLevel = items.filter { $0.indent == base }

        return topLevel.enumerated().map { index, item in
            let nextTopLevel = index + 1 < topLevel.endIndex ? topLevel[index + 1].line : nil
            var end = item.line
            for entry in lines where entry.line > item.line {
                if let nextTopLevel, entry.line >= nextTopLevel { break }
                let trimmed = entry.text.drop(while: { $0 == " " || $0 == "\t" })
                if trimmed.isEmpty { end = entry.line; continue }
                let indent = entry.text.prefix { $0 == " " || $0 == "\t" }.count
                if indent <= base && !trimmed.hasPrefix("#") && Self.listItem(entry.text) == nil {
                    // A non-indented paragraph or other block ends the list.
                    break
                }
                if trimmed.hasPrefix("#") { break }
                end = entry.line
            }
            // Trailing blank lines do not belong to the item.
            while end > item.line, lines.first(where: { $0.line == end })?.text.allSatisfy(\.isWhitespace) == true {
                end -= 1
            }
            return AlternativeOption(title: item.text, line: item.line, lineRange: item.line...end)
        }
    }

    private func subheadingOptions(in section: Section) -> [AlternativeOption] {
        let nested = sections.filter {
            $0.heading.level > section.heading.level && section.bodyLineRange.contains($0.heading.line)
        }
        guard let shallowest = nested.map(\.heading.level).min() else { return [] }
        return nested.filter { $0.heading.level == shallowest }.map { sub in
            AlternativeOption(
                title: sub.heading.title,
                line: sub.heading.line,
                lineRange: sub.heading.line...(sub.heading.line + sub.bodyLines.count)
            )
        }
    }

    /// The indentation width and text of a list item line (`-`, `*`, `+`, `1.`, `1)`), or `nil`.
    static func listItem(_ line: String) -> (indent: Int, text: String)? {
        let indent = line.prefix { $0 == " " || $0 == "\t" }
        let content = line.dropFirst(indent.count)
        let width = indent.reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }

        for marker in ["- ", "* ", "+ "] where content.hasPrefix(marker) {
            return (width, String(content.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces))
        }
        let digits = content.prefix { $0.isASCII && $0.isNumber }
        guard !digits.isEmpty else { return nil }
        let rest = content.dropFirst(digits.count)
        guard rest.hasPrefix(". ") || rest.hasPrefix(") ") else { return nil }
        return (width, String(rest.dropFirst(2)).trimmingCharacters(in: .whitespaces))
    }
}
