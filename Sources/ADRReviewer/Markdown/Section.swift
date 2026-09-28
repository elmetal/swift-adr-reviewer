/// A heading together with everything below it, up to the next heading of the
/// same or a higher level. Subsections are therefore part of their parent's body.
public struct Section: Sendable, Equatable {
    public var heading: Heading
    /// Lines between the heading and the end of the section, verbatim.
    public var bodyLines: [String]

    public init(heading: Heading, bodyLines: [String]) {
        self.heading = heading
        self.bodyLines = bodyLines
    }

    /// `true` when the body has no line containing anything other than whitespace.
    public var isEmpty: Bool {
        bodyLines.allSatisfy { $0.allSatisfy(\.isWhitespace) }
    }
}

extension Document {
    /// Sections of the document, one per heading, in order of appearance.
    public var sections: [Section] {
        let lines = lines
        let headings = headings

        return headings.enumerated().map { index, heading in
            let next = headings[(index + 1)...].first { $0.level <= heading.level }
            let endLine = next.map { $0.line - 1 } ?? lines.count
            // `heading.line` is 1-based, so the body starts at 0-based index `heading.line`.
            let body = lines[heading.line..<max(heading.line, endLine)].map(String.init)
            return Section(heading: heading, bodyLines: body)
        }
    }
}
