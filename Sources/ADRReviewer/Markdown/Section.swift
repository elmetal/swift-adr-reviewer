import Markdown

/// A heading together with everything below it, up to the next heading of the
/// same or a higher level. Subsections are therefore part of their parent's body.
public struct Section: Sendable, Equatable {
    public var heading: Heading
    /// Lines between the heading and the end of the section, verbatim.
    public var bodyLines: [String]
    /// 1-based line numbers, within the body, that belong to a fenced or indented code block.
    public var codeBlockLines: Set<Int>

    public init(heading: Heading, bodyLines: [String], codeBlockLines: Set<Int> = []) {
        self.heading = heading
        self.bodyLines = bodyLines
        self.codeBlockLines = codeBlockLines
    }

    /// `true` when the body has no line containing anything other than whitespace.
    public var isEmpty: Bool {
        bodyLines.allSatisfy { $0.allSatisfy(\.isWhitespace) }
    }

    /// Body lines outside code blocks, verbatim, with their 1-based line number in the document.
    public var bodyLinesOutsideCodeBlocks: [(line: Int, text: String)] {
        bodyLines.enumerated().compactMap { offset, text in
            let line = heading.line + 1 + offset
            return codeBlockLines.contains(line) ? nil : (line, text)
        }
    }
}

extension Document {
    /// Sections of the document, one per heading, in order of appearance.
    public var sections: [Section] {
        let lines = lines
        let headings = headings
        let codeBlockLines = codeBlockLines

        return headings.enumerated().map { index, heading in
            let next = headings[(index + 1)...].first { $0.level <= heading.level }
            let endLine = next.map { $0.line - 1 } ?? lines.count
            // `heading.line` is 1-based, so the body starts at 0-based index `heading.line`.
            let bodyRange = heading.line..<max(heading.line, endLine)
            let body = lines[bodyRange].map(String.init)
            return Section(
                heading: heading,
                bodyLines: body,
                codeBlockLines: codeBlockLines.filter { bodyRange.contains($0 - 1) }
            )
        }
    }

    /// 1-based line numbers occupied by fenced or indented code blocks, fences included.
    var codeBlockLines: Set<Int> {
        var collector = CodeBlockCollector()
        collector.visit(Markdown.Document(parsing: content))
        return collector.lines
    }
}

private struct CodeBlockCollector: MarkupWalker {
    var lines: Set<Int> = []

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        guard let range = codeBlock.range else { return }
        lines.formUnion(range.lowerBound.line...range.upperBound.line)
    }
}
