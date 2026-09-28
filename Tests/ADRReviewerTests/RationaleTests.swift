import Testing
@testable import ADRReviewer

@Suite struct RationaleTests {
    @Test func reasonSentencesComeFromRationaleSectionAndMarkedDecisionSentences() {
        let content = """
        # 1. Swift を採用する
        ## 背景
        ビルドが遅い。
        ## 決定
        Swift を採用する。ビルドが速いためである。
        ## 決定理由
        経験者が多い。
        ## 結果
        リスクは無い。
        """
        let document = Document(path: "adr.md", content: content)
        #expect(document.reasonSentences.map(\.text) == ["ビルドが速いためである。", "経験者が多い。"])
        #expect(document.decisionSentences.map(\.text) == ["Swiftを採用する。", "ビルドが速いためである。"])
        #expect(document.contextSentences.map(\.text) == ["ビルドが遅い。"])
        #expect(document.title?.title == "1. Swift を採用する")
    }
}
