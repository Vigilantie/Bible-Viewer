import Foundation

@main
struct BibleReferenceTests {
    static func main() {
        let references: [(String, String, Int, Int)] = [
            ("John 3:16", "John", 3, 16),
            ("  1 jn  2 : 3  ", "1 John", 2, 3),
            ("Psalm 119:176", "Psalms", 119, 176),
            ("Song of Solomon 8:14", "Song of Solomon", 8, 14),
            ("Revelation 22:21", "Revelation", 22, 21),
            ("GENESIS 1", "Genesis", 1, 1)
        ]
        for (input, book, chapter, verse) in references {
            guard let ref = BibleReference.parse(input) else { fatalError("Could not parse \(input)") }
            precondition(ref.book == book && ref.chapter == chapter && ref.verse == verse)
        }
        for text in ["God so loved", "Unknown 3:16", "John 3:", "John 3:16 trailing", "John 999999999999999999999999:1"] {
            precondition(BibleReference.parse(text) == nil, "Unexpected reference: \(text)")
        }
        print("Bible reference parsing checks passed.")
    }
}
