import Markdown

/// A sentence of prose, with the line it starts on.
public struct Sentence: Sendable, Equatable {
    /// The sentence text including its terminator, with whitespace removed.
    public var text: String
    /// 1-based line number where the sentence starts.
    public var line: Int

    public init(text: String, line: Int) {
        self.text = text
        self.line = line
    }

    /// Number of characters in the sentence.
    public var length: Int { text.count }
}

extension Document {
    /// Sentences that start within the body of `section` (subsections included).
    public func sentences(in section: Section) -> [Sentence] {
        sentences.filter { section.bodyLineRange.contains($0.line) }
    }
}

extension Sentence {
    /// Prose sentences in `markup`, in order of appearance.
    ///
    /// Only paragraphs are considered (including those inside list items and block
    /// quotes). Headings, code blocks, tables and HTML are skipped. Inside a paragraph,
    /// inline code counts as text, link and image URLs do not, and soft line breaks
    /// join the lines without inserting a space. Sentences end at 。！？!? followed
    /// by any closing quotes or brackets; the trailing text without a terminator is
    /// also a sentence. Whitespace is removed from sentences.
    static func all(in markup: Markdown.Document) -> [Sentence] {
        var collector = ParagraphCollector()
        collector.visit(markup)
        return collector.paragraphs.flatMap(sentences(in:))
    }

    private static let terminators: Set<Character> = ["。", "！", "？", "!", "?"]
    private static let closers: Set<Character> = ["」", "』", "）", ")", "]", "］", "〕", "\"", "'", "”", "’"]

    private static func sentences(in paragraph: ProseParagraph) -> [Sentence] {
        var result: [Sentence] = []
        var current: [Character] = []
        var currentLine: Int? = nil
        var terminated = false

        func flush() {
            if let line = currentLine, !current.isEmpty {
                result.append(Sentence(text: String(current), line: line))
            }
            current = []
            currentLine = nil
            terminated = false
        }

        for (character, line) in zip(paragraph.characters, paragraph.lines) {
            if character.isWhitespace { continue }
            if terminated, !terminators.contains(character), !closers.contains(character) {
                flush()
            }
            if currentLine == nil { currentLine = line }
            current.append(character)
            if terminators.contains(character) { terminated = true }
        }
        flush()
        return result
    }
}

/// A paragraph's plain text, one source line number per character.
struct ProseParagraph {
    var characters: [Character] = []
    var lines: [Int] = []

    mutating func append(_ text: String, line: Int) {
        for character in text {
            characters.append(character)
            lines.append(line)
        }
    }
}

private struct ParagraphCollector: MarkupWalker {
    var paragraphs: [ProseParagraph] = []
    private var current: ProseParagraph? = nil
    /// Line of the nearest enclosing inline node with a known range; used for nodes without one.
    private var fallbackLine = 1

    mutating func visitParagraph(_ paragraph: Paragraph) {
        current = ProseParagraph()
        fallbackLine = paragraph.range?.lowerBound.line ?? fallbackLine
        descendInto(paragraph)
        if let finished = current { paragraphs.append(finished) }
        current = nil
    }

    mutating func visitText(_ text: Text) {
        append(text.string, range: text.range)
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        append(inlineCode.code, range: inlineCode.range)
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {}
    mutating func visitLineBreak(_ lineBreak: LineBreak) {}
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {}

    // Link, Image, Emphasis, Strong, Strikethrough and InlineAttributes are handled by
    // the default implementation, which descends into their children (link text, alt text…).
    // Block nodes other than Paragraph are likewise descended into, so paragraphs inside
    // list items and block quotes are found, while headings, code blocks, tables and HTML
    // blocks contribute nothing because they contain no Paragraph.

    private mutating func append(_ text: String, range: SourceRange?) {
        guard current != nil else { return }
        if let line = range?.lowerBound.line { fallbackLine = line }
        current?.append(text, line: fallbackLine)
    }
}
