import ADRReviewer
import ArgumentParser
import Foundation

@main
struct ADRReviewerCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "adr-reviewer",
        abstract: "Reviews the quality of Architecture Decision Records written in Japanese.",
        discussion: helpDiscussion
    )

    private static var helpDiscussion: String {
        let rules = Reviewer.default.rules
            .map { "  \($0.id)\n      \($0.summary)" }
            .joined(separator: "\n")

        return """
        指定した ADR ファイルを組み込みのルールで検査し、指摘を1行ずつ標準出力に表示します。

        RULES:
        \(rules)

        OUTPUT FORMAT:
          <path>[:<line>]: <warning|error>: <message> [<rule-id>]

        EXIT STATUS:
          0  指摘なし、または warning のみ
          1  error が1件以上ある(読み込めないファイルも error として扱う)

        EXAMPLES:
          adr-reviewer docs/adr/0001-use-swift.md
          adr-reviewer docs/adr/*.md
        """
    }

    @Argument(help: "ADR files to review.", completion: .file(extensions: ["md"]))
    var files: [String]

    func run() throws {
        var diagnostics: [Diagnostic] = []
        let reviewer = Reviewer.default

        for path in files {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                diagnostics += reviewer.review(Document(path: path, content: content))
            } catch {
                diagnostics.append(
                    Diagnostic(
                        path: path,
                        severity: .error,
                        ruleID: "io",
                        message: "ファイルを読み込めません: \(error.localizedDescription)"
                    )
                )
            }
        }

        for diagnostic in diagnostics {
            print(diagnostic.formatted)
        }

        if diagnostics.contains(where: { $0.severity == .error }) {
            throw ExitCode.failure
        }
    }
}
