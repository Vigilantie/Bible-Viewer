import SwiftUI
import AppKit

@main
struct ReadingSettingsTests {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let suite = "BibleViewer.SettingsTest.\(UUID().uuidString)"
        let preferences = UserDefaults(suiteName: suite)!
        defer { preferences.removePersistentDomain(forName: suite) }
        preferences.set("Matthew", forKey: "lastReadBook")
        preferences.set(5, forKey: "lastReadChapter")
        preferences.set(false, forKey: "showRedLetters")
        preferences.set(false, forKey: "showItalics")
        preferences.set(21.0, forKey: "readingFontSize")
        let host = NSHostingView(rootView: ContentView().defaultAppStorage(preferences))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 700), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        func settle() {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        }
        func reader(_ view: NSView) -> NSTextView? {
            if let text = view as? NSTextView, !text.isEditable { return text }
            return view.subviews.lazy.compactMap { reader($0) }.first
        }
        settle()
        let verses = try BibleReader.chapter(book: "Matthew", chapter: 5)
        let deadline = Date(timeIntervalSinceNow: 10)
        while reader(host) == nil && Date() < deadline { settle() }
        guard let initial = reader(host) else { fatalError("Reader did not finish loading the bundled chapter.") }
        precondition(initial.selectedRange().length == 0, "Opening a chapter highlighted its first verse.")
        let text = initial.string
        precondition(text == ScriptureFormatting.chapter(verses, fontSize: 21, redLetters: false, italics: false).string, "Saved chapter not restored.")
        for (red, italic) in [(true, false), (true, true), (false, true), (false, false)] {
            preferences.set(red, forKey: "showRedLetters")
            preferences.set(italic, forKey: "showItalics")
            settle()
            let current = reader(host)!
            precondition(current.selectedRange().length == 0, "Refreshing a chapter introduced a verse highlight.")
            precondition(current.string == text, "Changed chapter while refreshing.")
            let expected = ScriptureFormatting.chapter(verses, fontSize: 21, redLetters: red, italics: italic)
            precondition(current.textStorage!.isEqual(to: expected), "ContentView did not refresh after persisted settings changed.")
        }
        for size in [23.0, 25.0, 23.0, 21.0] {
            preferences.set(size, forKey: "readingFontSize")
            settle()
            let current = reader(host)!
            precondition(current.selectedRange().length == 0, "Refreshing a chapter introduced a verse highlight.")
            precondition(current.string == text, "Changed chapter while resizing text.")
            let expected = ScriptureFormatting.chapter(verses, fontSize: size, redLetters: false, italics: false)
            precondition(current.textStorage!.isEqual(to: expected), "ContentView did not refresh after font size changed.")
        }
        print("Full ContentView formatting and larger/smaller text refresh passed without chapter navigation; saved chapter restored.")
    }
}
