import Testing
@testable import ADRReviewer

@Suite struct BigramsTests {
    @Test func ignoresPunctuationWhitespaceAndCase() {
        #expect(Bigrams.of("Swift を、採用する。") == Bigrams.of("swiftを採用する"))
        #expect(Bigrams.of("あ") == [])
        #expect(Bigrams.of("あい") == ["あい"])
    }

    @Test func cosineAndContainment() {
        let a = Bigrams.of("ビルドが遅い")
        let b = Bigrams.of("ビルドは遅い")
        #expect(Bigrams.cosine(a, a) == 1)
        #expect(Bigrams.cosine(a, []) == 0)
        #expect(Bigrams.containment(of: a, in: a) == 1)
        #expect(Bigrams.containment(of: [], in: a) == 0)
        // ビル, ルド, 遅い shared out of ビル, ルド, ドが, が遅, 遅い
        #expect(Bigrams.containment(of: a, in: b) == 0.6)
    }
}
