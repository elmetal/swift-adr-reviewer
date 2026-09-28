import Markdown

/// An ADR document to be reviewed.
///
/// The Markdown is parsed once, when the document is created; the derived views
/// (``lines``, ``headings``, ``sections``, ``sentences``) are stored so that every
/// rule reads the same parse.
public struct Document: Sendable, Equatable {
    /// The path used to identify the document in diagnostics.
    public var path: String
    /// The full text of the document.
    public let content: String

    /// The document split into lines. Any newline sequence (LF, CRLF, …) is a separator.
    public let lines: [Substring]
    /// Headings in order of appearance. See ``Heading``.
    public let headings: [Heading]
    /// One section per heading, in order of appearance. See ``Section``.
    public let sections: [Section]
    /// Prose sentences in order of appearance. See ``Sentence``.
    public let sentences: [Sentence]
    /// Plain text of every table cell, with the cell's 1-based line, in order of appearance.
    public let tableCells: [TableCell]

    public init(path: String, content: String) {
        self.path = path
        self.content = content

        let markup = Markdown.Document(parsing: content)
        let lines = content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        let headings = Heading.all(in: markup)

        self.lines = lines
        self.headings = headings
        self.sections = Section.all(headings: headings, lines: lines, codeBlockLines: Section.codeBlockLines(in: markup))
        self.sentences = Sentence.all(in: markup)
        self.tableCells = TableCell.all(in: markup)
    }

    public static func == (lhs: Document, rhs: Document) -> Bool {
        lhs.path == rhs.path && lhs.content == rhs.content
    }
}
