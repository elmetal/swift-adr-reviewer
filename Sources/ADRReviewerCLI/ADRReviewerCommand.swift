import ADRReviewer
import ArgumentParser
import Foundation

@main
struct ADRReviewerCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "adr-reviewer",
        abstract: "Reviews the quality of Architecture Decision Records written in Japanese."
    )

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
