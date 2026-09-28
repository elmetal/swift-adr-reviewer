import Markdown

extension Markup {
    /// The plain text of this node's inline content: Markdown formatting removed,
    /// inline code kept without backticks, link and image URLs dropped, line breaks
    /// turned into a single space, inline HTML dropped. Trimmed of surrounding whitespace.
    var proseText: String {
        var collector = ProseTextCollector()
        collector.visit(self)
        return collector.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ProseTextCollector: MarkupWalker {
    var text = ""

    mutating func visitText(_ text: Text) { self.text += text.string }
    mutating func visitInlineCode(_ inlineCode: InlineCode) { text += inlineCode.code }
    mutating func visitSoftBreak(_ softBreak: SoftBreak) { text += " " }
    mutating func visitLineBreak(_ lineBreak: LineBreak) { text += " " }
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {}
    // Everything else (Link, Image, Emphasis, Strong, …) descends into its children.
}
