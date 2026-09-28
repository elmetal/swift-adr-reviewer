/// Character-bigram text similarity. Works for Japanese without a tokenizer.
enum Bigrams {
    /// Characters ignored before forming bigrams: punctuation, brackets and whitespace.
    private static let ignored: Set<Character> = [
        "。", "、", "，", "．", "！", "？", "!", "?", ",", ".", ":", "：", ";", "；",
        "「", "」", "『", "』", "（", "）", "(", ")", "[", "]", "［", "］", "・", "-", "ー", "〜", "~",
        "\"", "'", "”", "’", "“", "‘", " ", "\t", "\n",
    ]

    /// The set of character bigrams of `text`, ignoring punctuation and ASCII case.
    static func of(_ text: String) -> Set<String> {
        let characters = Array(text.lowercased().filter { !ignored.contains($0) })
        guard characters.count >= 2 else { return [] }
        return Set((0..<(characters.count - 1)).map { String(characters[$0...$0 + 1]) })
    }

    /// Cosine similarity of two bigram sets, in 0...1.
    static func cosine(_ a: Set<String>, _ b: Set<String>) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / (Double(a.count) * Double(b.count)).squareRoot()
    }

    /// The share of `a`'s bigrams that also occur in `b`, in 0...1.
    static func containment(of a: Set<String>, in b: Set<String>) -> Double {
        guard !a.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / Double(a.count)
    }
}
