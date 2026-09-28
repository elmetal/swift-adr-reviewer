import Markdown

/// A Markdown heading.
public struct Heading: Sendable, Equatable {
    /// Heading level, 1 through 6.
    public var level: Int
    /// Heading text as plain text: Markdown formatting removed, inline code kept
    /// without backticks, surrounding whitespace trimmed.
    public var title: String
    /// 1-based line number in the document.
    public var line: Int

    public init(level: Int, title: String, line: Int) {
        self.level = level
        self.title = title
        self.line = line
    }
}

extension Heading {
    /// Headings in `markup`, in order of appearance. Both ATX (`## Title`) and setext
    /// (underlined) headings are recognised; text inside fenced code blocks is not.
    static func all(in markup: Markdown.Document) -> [Heading] {
        var collector = HeadingCollector()
        collector.visit(markup)
        return collector.headings
    }
}

private struct HeadingCollector: MarkupWalker {
    var headings: [Heading] = []

    mutating func visitHeading(_ heading: Markdown.Heading) {
        guard let line = heading.range?.lowerBound.line else { return }
        headings.append(Heading(level: heading.level, title: heading.proseText, line: line))
    }
}
