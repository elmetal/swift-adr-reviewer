import Markdown

/// A sentence of prose, with the line it starts on.
public struct Sentence: Sendable, Equatable {
    /// The sentence text including its terminator, with whitespace removed.
    public var text: String
    /// 1-based line number where the sentence starts.
    public var line: Int
    /// `true` when any part of the sentence is link text or image alt text.
    public var containsLink: Bool
    /// Number of characters of ``text`` that came from inline code spans.
    public var inlineCodeLength: Int

    public init(text: String, line: Int, containsLink: Bool = false, inlineCodeLength: Int = 0) {
        self.text = text
        self.line = line
        self.containsLink = containsLink
        self.inlineCodeLength = inlineCodeLength
    }

    /// Number of characters in the sentence, inline code included.
    public var length: Int { text.count }

    /// Number of characters a reader has to read as prose: ``length`` without the
    /// characters of inline code spans, which are read as single tokens (identifiers,
    /// paths, API names) rather than character by character.
    public var proseLength: Int { length - inlineCodeLength }

    /// Whether the sentence contains `expression`, ignoring ASCII case and any
    /// whitespace in `expression` (sentence text never contains whitespace).
    public func contains(_ expression: String) -> Bool {
        let needle = expression.filter { !$0.isWhitespace }.lowercased()
        return !needle.isEmpty && text.lowercased().contains(needle)
    }

    /// `true` when the sentence carries something that can back a claim: a link,
    /// an evidential number, or a reference to a measurement or source.
    public var hasBacking: Bool {
        containsLink || hasEvidentialNumber || Self.backingMarkers.contains(where: contains)
    }

    /// `true` when the sentence contains a decimal number that is not merely counting
    /// or ordering things in the text (2つ, 3案, 第2 …).
    public var hasEvidentialNumber: Bool {
        let characters = Array(text)
        var index = 0
        while index < characters.count {
            guard Self.isDecimalDigit(characters[index]) else { index += 1; continue }
            let start = index
            while index < characters.count, Self.isDecimalDigit(characters[index]) { index += 1 }

            let precededByOrdinal = start > 0 && characters[start - 1] == "第"
            let rest = String(characters[index...])
            let followedByCounter = Self.countingSuffixes.contains(where: rest.hasPrefix)
            if !precededByOrdinal, !followedByCounter { return true }
        }
        return false
    }

    private static func isDecimalDigit(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { $0.properties.numericType == .decimal }
    }

    /// Counters and ordinals that make a number a count of items in the text rather
    /// than a measurement: 2つの選択肢, 3案, 4項目, 5番目.
    static let countingSuffixes: [String] = [
        "つ", "個", "案", "項目", "観点", "点", "章", "節", "番目", "番", "段階", "種類", "通り", "パターン", "択",
        "つめ", "つ目", "個目", "案目",
    ]

    static let backingMarkers: [String] = [
        "http", "adr-", "出典", "参照", "参考", "計測", "測定", "ベンチマーク", "調査", "検証結果", "実測",
        "source", "measured", "benchmark", "survey",
    ]
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
        var currentHasLink = false
        var currentCodeLength = 0
        var terminated = false

        func flush() {
            if let line = currentLine, !current.isEmpty {
                result.append(Sentence(
                    text: String(current), line: line, containsLink: currentHasLink, inlineCodeLength: currentCodeLength
                ))
            }
            current = []
            currentLine = nil
            currentHasLink = false
            currentCodeLength = 0
            terminated = false
        }

        for index in paragraph.characters.indices {
            let character = paragraph.characters[index]
            if character.isWhitespace { continue }
            if terminated, !terminators.contains(character), !closers.contains(character) {
                flush()
            }
            if currentLine == nil { currentLine = paragraph.lines[index] }
            current.append(character)
            if paragraph.inLink[index] { currentHasLink = true }
            if paragraph.inCode[index] { currentCodeLength += 1 }
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
    var inLink: [Bool] = []
    var inCode: [Bool] = []

    mutating func append(_ text: String, line: Int, inLink: Bool, inCode: Bool = false) {
        for character in text {
            characters.append(character)
            lines.append(line)
            self.inLink.append(inLink)
            self.inCode.append(inCode)
        }
    }
}

private struct ParagraphCollector: MarkupWalker {
    var paragraphs: [ProseParagraph] = []
    private var current: ProseParagraph? = nil
    /// Line of the nearest enclosing inline node with a known range; used for nodes without one.
    private var fallbackLine = 1
    /// Greater than zero while inside a Link or Image.
    private var linkDepth = 0

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
        append(inlineCode.code, range: inlineCode.range, inCode: true)
    }

    mutating func visitLink(_ link: Link) {
        linkDepth += 1
        descendInto(link)
        linkDepth -= 1
    }

    mutating func visitImage(_ image: Image) {
        linkDepth += 1
        descendInto(image)
        linkDepth -= 1
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {}
    mutating func visitLineBreak(_ lineBreak: LineBreak) {}
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {}

    // Emphasis, Strong, Strikethrough and InlineAttributes are handled by the default
    // implementation, which descends into their children.
    // Block nodes other than Paragraph are likewise descended into, so paragraphs inside
    // list items and block quotes are found, while headings, code blocks, tables and HTML
    // blocks contribute nothing because they contain no Paragraph.

    private mutating func append(_ text: String, range: SourceRange?, inCode: Bool = false) {
        guard current != nil else { return }
        if let line = range?.lowerBound.line { fallbackLine = line }
        current?.append(text, line: fallbackLine, inLink: linkDepth > 0, inCode: inCode)
    }
}
