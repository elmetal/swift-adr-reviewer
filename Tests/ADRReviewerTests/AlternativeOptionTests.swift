import Testing
@testable import ADRReviewer

@Suite struct AlternativeOptionTests {
    private func options(_ body: String) -> [AlternativeOption] {
        let document = Document(path: "adr.md", content: "## 検討した選択肢\n\(body)\n## 結果\n本文\n")
        return document.alternativeOptions(in: document.sections[0])
    }

    @Test func listItemsWithNestedDetailsAndContinuationLines() {
        let body = """
        以下を比較した。

        - 案A: Swift
          - 利点: 速い
          - 欠点: 学習コスト
        - 案B: Kotlin
          続きの行。

        - 案C
        """
        let result = options(body)
        #expect(result.map(\.title) == ["案A: Swift", "案B: Kotlin", "案C"])
        #expect(result.map(\.line) == [4, 7, 10])
        #expect(result.map(\.lineRange) == [4...6, 7...8, 10...10])
    }

    @Test func orderedListItems() {
        #expect(options("1. 案A\n2. 案B").map(\.title) == ["案A", "案B"])
        #expect(options("1) 案A\n2) 案B").map(\.title) == ["案A", "案B"])
    }

    @Test func subheadingsWithBodies() {
        let body = """
        ### 案A
        説明A
        #### 詳細
        深い
        ### 案B
        説明B
        """
        let result = options(body)
        #expect(result.map(\.title) == ["案A", "案B"])
        #expect(result.map(\.lineRange) == [2...5, 6...7])
    }

    @Test func mixedListAndSubheadings() {
        #expect(options("- 案A\n### 案B\n説明").map(\.title) == ["案A", "案B"])
    }

    @Test func aParagraphAfterTheListEndsTheLastItem() {
        let result = options("- 案A\n- 案B\n\n以上を比較した。")
        #expect(result.map(\.lineRange) == [2...2, 3...3])
    }

    @Test func codeBlocksAreIgnored() {
        #expect(options("```\n- not\n```\n- 案A").map(\.title) == ["案A"])
    }

    @Test func containsTable() {
        let document = Document(path: "adr.md", content: "## 検討した選択肢\n| a | b |\n|---|---|\n| 1 | 2 |\n")
        #expect(document.sections[0].containsTable)
        #expect(!Document(path: "adr.md", content: "## 検討した選択肢\n- 案A\n").sections[0].containsTable)
    }
}

@Suite struct ParentSectionTests {
    private let document = Document(path: "adr.md", content: """
        ## Basis of the Decision
        ### 選択肢
        1. 案A
        2. 案B
        ### 評価テーブル
        | 観点 | 案A | 案B |
        |---|---|---|
        | 速度 | ◎ | △ |
        ## 結果
        本文
        """)

    @Test func parentSectionIsTheEnclosingHeading() {
        let options = document.sections(matching: .alternatives)[0]
        #expect(document.parentSection(of: options)?.heading.title == "Basis of the Decision")
        #expect(document.parentSection(of: document.sections[0]) == nil)
    }

    @Test func tableInSiblingSubsectionCountsAsComparison() {
        let options = document.sections(matching: .alternatives)[0]
        #expect(!options.containsTable)
        #expect(document.comparesOptionsInTable(options))
    }

    @Test func alternativeRulesSkipWhenParentHasTable() {
        #expect(AlternativeRejectionRule().check(document).isEmpty)
        #expect(AlternativesRule(minimumOptions: 5).check(document).isEmpty)
        #expect(DecisionInAlternativesRule().check(document).isEmpty)
    }
}
