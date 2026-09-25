import AppKit
import Foundation

@main
struct ScriptureFormattingTests {
    static func main() throws {
        precondition(CommandLine.arguments.count == 2, "Pass the KJV database path.")
        let verses = try BibleBridge.verses(atPath: CommandLine.arguments[1], book: "Matthew", chapter: 5, firstVerse: 3, limit: 1).map(ReaderVerse.init)
        let verse = verses[0]
        precondition(verse.pieces.contains { $0.red })
        precondition(verse.pieces.contains { $0.italic })
        let expected = "3  \(verse.text)"
        for red in [false, true] {
            for italic in [false, true] {
                let text = ScriptureFormatting.chapter(verses, fontSize: 21, redLetters: red, italics: italic)
                precondition(text.string == expected && !text.string.contains("<"))
                var offset = 3
                for piece in verse.pieces {
                    let color = text.attribute(.foregroundColor, at: offset, effectiveRange: nil) as! NSColor
                    let font = text.attribute(.font, at: offset, effectiveRange: nil) as! NSFont
                    precondition(color == (red && piece.red ? NSColor.systemRed : NSColor.labelColor))
                    precondition(NSFontManager.shared.traits(of: font).contains(.italicFontMask) == (italic && piece.italic))
                    offset += (piece.text as NSString).length
                }
            }
        }
        print("All four red-letter/italic combinations passed; verse text and offsets are unchanged.")
    }
}
