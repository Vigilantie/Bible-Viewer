import SwiftUI
import AppKit

private final class Settings: ObservableObject {
    @Published var red = false
    @Published var italic = false
}

private struct LiveReader: View {
    @ObservedObject var settings: Settings
    let verses: [ReaderVerse]
    var body: some View {
        ScriptureText(verses: verses, fontSize: 21, redLetters: settings.red, italics: settings.italic,
                      targetRange: NSRange(location: 0, length: 0), onLookup: { _ in })
    }
}

@main
struct LiveFormattingTests {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let verses = try BibleBridge.verses(atPath: CommandLine.arguments[1], book: "Matthew", chapter: 5, firstVerse: 3, limit: 1).map(ReaderVerse.init)
        let settings = Settings()
        let host = NSHostingView(rootView: LiveReader(settings: settings, verses: verses))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        func settle() {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
        }
        func textView(_ view: NSView) -> NSTextView? {
            if let text = view as? NSTextView { return text }
            return view.subviews.lazy.compactMap { textView($0) }.first
        }
        settle()
        let reader = textView(host)!
        let originalText = reader.string
        for (red, italic) in [(true, false), (true, true), (false, true), (false, false)] {
            settings.red = red
            settings.italic = italic
            settle()
            precondition(textView(host) === reader, "Formatting recreated the reader.")
            precondition(reader.string == originalText)
            var offset = 3
            for piece in verses[0].pieces {
                let attributes = reader.textStorage!.attributes(at: offset, effectiveRange: nil)
                precondition(attributes[.foregroundColor] as! NSColor == (red && piece.red ? NSColor.systemRed : NSColor.labelColor), "Red letters did not update live.")
                let font = attributes[.font] as! NSFont
                precondition(NSFontManager.shared.traits(of: font).contains(.italicFontMask) == (italic && piece.italic), "Italics did not update live.")
                offset += (piece.text as NSString).length
            }
        }
        print("Live SwiftUI formatting updates passed without recreating the native reader.")
    }
}
