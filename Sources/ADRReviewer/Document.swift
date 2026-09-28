/// An ADR document to be reviewed.
public struct Document: Sendable, Equatable {
    /// The path used to identify the document in diagnostics.
    public var path: String
    /// The full text of the document.
    public var content: String

    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}
