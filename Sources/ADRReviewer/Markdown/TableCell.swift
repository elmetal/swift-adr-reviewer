import Markdown

/// The plain text of one table cell.
public struct TableCell: Sendable, Equatable {
    public var text: String
    /// 1-based line of the cell.
    public var line: Int

    public init(text: String, line: Int) {
        self.text = text
        self.line = line
    }
}

extension TableCell {
    static func all(in markup: Markdown.Document) -> [TableCell] {
        var collector = TableCellCollector()
        collector.visit(markup)
        return collector.cells
    }
}

extension Document {
    /// Table cells whose line lies within the body of `section`.
    public func tableCells(in section: Section) -> [TableCell] {
        tableCells.filter { section.bodyLineRange.contains($0.line) }
    }
}

private struct TableCellCollector: MarkupWalker {
    var cells: [TableCell] = []

    mutating func visitTableCell(_ cell: Markdown.Table.Cell) {
        guard let line = cell.range?.lowerBound.line else { return }
        let text = cell.proseText
        if !text.isEmpty { cells.append(TableCell(text: text, line: line)) }
    }
}
