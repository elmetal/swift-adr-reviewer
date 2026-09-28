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

extension Document {
    /// The document split into lines. Any newline sequence (LF, CRLF, …) is a separator.
    public var lines: [Substring] {
        content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    }

    /// Headings in the document, in order of appearance, as parsed by swift-markdown.
    /// Both ATX (`## Title`) and setext (underlined) headings are recognised; text
    /// inside fenced code blocks is not.
    public var headings: [Heading] {
        var collector = HeadingCollector()
        collector.visit(Markdown.Document(parsing: content))
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
