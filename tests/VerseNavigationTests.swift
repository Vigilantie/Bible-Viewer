import SwiftUI
import AppKit

@main
struct VerseNavigationTests {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let verses = try BibleBridge.verses(atPath: CommandLine.arguments[1], book: "John", chapter: 3, firstVerse: 1, limit: -1).map(ReaderVerse.init)
        let text = ScriptureFormatting.chapter(verses, fontSize: 21, redLetters: true, italics: true).string as NSString
        func textView(_ view: NSView) -> NSTextView? {
            if let text = view as? NSTextView { return text }
            return view.subviews.lazy.compactMap { textView($0) }.first
        }
        for size in [NSSize(width: 800, height: 600), NSSize(width: 360, height: 250)] {
            for number in [1, 16, 36] {
                let prefix = number == 1 ? "1  " : "\n\n\(number)  "
                let location = text.range(of: prefix).location + (number == 1 ? 0 : 2)
                let range = NSRange(location: location, length: ("\(number)  \(verses[number - 1].text)" as NSString).length)
                let host = NSHostingView(rootView: ScriptureText(verses: verses, fontSize: 21, redLetters: true, italics: true, targetRange: range, onLookup: { _ in }))
                let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
                window.contentView = host
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
                let reader = textView(host)!
                let manager = reader.layoutManager!
                let glyphs = manager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                let rect = manager.boundingRect(forGlyphRange: glyphs, in: reader.textContainer!).offsetBy(dx: reader.textContainerOrigin.x, dy: reader.textContainerOrigin.y)
                precondition(reader.selectedRange() == range, "Wrong verse selected")
                precondition(reader.visibleRect.insetBy(dx: -1, dy: -1).contains(rect), "John 3:\(number) hidden at \(size): verse \(rect), viewport \(reader.visibleRect)")
                if number == 16 {
                    let line = manager.lineFragmentRect(forGlyphAt: glyphs.location, effectiveRange: nil).offsetBy(dx: reader.textContainerOrigin.x, dy: reader.textContainerOrigin.y)
                    precondition(abs(line.minY - reader.visibleRect.minY - reader.textContainerInset.height) < 1,
                                 "John 3:16 should be the first verse at the top")
                }
            }
        }
        print("Verse navigation passed: John 3:1, 3:16, and 3:36 at wide and narrow sizes.")
    }
}
