/// A Markdown ATX heading (`# Title` … `###### Title`).
public struct Heading: Sendable, Equatable {
    /// Heading level, 1 through 6.
    public var level: Int
    /// Heading text with the leading `#`s, optional closing `#`s and surrounding whitespace removed.
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

    /// ATX headings in the document, in order of appearance.
    ///
    /// Lines inside fenced code blocks (``` or ~~~) are ignored. Setext headings
    /// (underlined with `===` or `---`) are not recognised.
    public var headings: [Heading] {
        var headings: [Heading] = []
        var openFence: Substring? = nil

        for (index, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if let fence = openFence {
                if line.hasPrefix(fence) { openFence = nil }
                continue
            }
            if let fence = Self.codeFence(opening: line) {
                openFence = fence
                continue
            }

            guard let heading = Self.parseHeading(line, lineNumber: index + 1) else { continue }
            headings.append(heading)
        }
        return headings
    }

    private static func codeFence(opening line: String) -> Substring? {
        for fenceCharacter in ["`", "~"] {
            let run = line.prefix { String($0) == fenceCharacter }
            if run.count >= 3 { return run }
        }
        return nil
    }

    private static func parseHeading(_ line: String, lineNumber: Int) -> Heading? {
        let hashes = line.prefix { $0 == "#" }
        guard (1...6).contains(hashes.count) else { return nil }

        var rest = line.dropFirst(hashes.count)
        // `#Title` without a space is not a heading; an empty heading (`#`) is.
        guard rest.isEmpty || rest.first == " " || rest.first == "\t" else { return nil }

        rest = rest.trimmingCharacters(in: .whitespaces)[...]
        // Optional closing sequence: `## Title ##`
        let closing = rest.reversed().prefix { $0 == "#" }
        if !closing.isEmpty {
            let beforeClosing = rest.dropLast(closing.count)
            if beforeClosing.isEmpty || beforeClosing.last == " " || beforeClosing.last == "\t" {
                rest = beforeClosing.trimmingCharacters(in: .whitespaces)[...]
            }
        }
        return Heading(level: hashes.count, title: String(rest), line: lineNumber)
    }
}

private extension StringProtocol {
    func trimmingCharacters(in set: Set<Character>) -> String {
        var result = Substring(self)
        while let first = result.first, set.contains(first) { result = result.dropFirst() }
        while let last = result.last, set.contains(last) { result = result.dropLast() }
        return String(result)
    }
}

private extension Set<Character> {
    static let whitespaces: Set<Character> = [" ", "\t", "\r"]
}
