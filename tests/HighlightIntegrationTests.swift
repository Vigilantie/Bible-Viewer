import SwiftUI
import AppKit

private struct Reader: View {
    @ObservedObject var store: HighlightStore
    let verses: [ReaderVerse]
    var body: some View {
        ScriptureText(verses: verses, fontSize: 21, redLetters: true, italics: true,
                      targetRange: NSRange(location: 0, length: 0), highlights: store.highlights,
                      onHighlight: { store.update(selection: $0, verses: verses, color: $1) }, onLookup: { _ in })
    }
}
@main
struct HighlightIntegrationTests {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let verses = try BibleBridge.verses(atPath: CommandLine.arguments[1], book: "John", chapter: 1, firstVerse: 1, limit: -1).map(ReaderVerse.init)
        let path = CommandLine.arguments[2]
        let store = HighlightStore(path: path)
        precondition(store.error == nil)
        let host = NSHostingView(rootView: Reader(store: store, verses: verses))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        func settle() { host.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3)) }
        func find(_ view: NSView) -> NSTextView? {
            if let text = view as? NSTextView { return text }
            return view.subviews.lazy.compactMap { find($0) }.first
        }
        settle()
        let view = find(host)!
        let text = view.string as NSString
        // Includes an emoji surrogate pair, accented Latin and Hebrew text.
        let selection = text.range(of: "😀 café שלום")
        precondition(selection.location != NSNotFound)
        view.setSelectedRange(selection)
        let event = NSEvent.mouseEvent(with: .rightMouseDown, location: window.convertPoint(fromScreen: view.firstRect(forCharacterRange: selection, actualRange: nil).origin), modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
        let menu = view.menu(for: event)!
        let yellow = menu.items.first { $0.title == "Highlight" }!.submenu!.items.first { $0.title == "Yellow" }!
        view.setSelectedRange(selection)
        precondition(NSApp.sendAction(yellow.action!, to: yellow.target, from: yellow))
        settle()
        precondition(store.error == nil && store.highlights.count == 1)
        precondition(view.textStorage!.attribute(.backgroundColor, at: selection.location, effectiveRange: nil) != nil, "Highlight did not appear live.")
        let reopened = HighlightStore(path: path)
        precondition(reopened.highlights == store.highlights, "Highlight did not persist.")
        let middle = text.range(of: "café")
        store.update(selection: middle, verses: verses, color: 4)
        precondition(store.highlights.count == 3)
        store.update(selection: middle, verses: verses, color: nil)
        settle()
        precondition(store.highlights.count == 2)
        precondition(view.textStorage!.attribute(.backgroundColor, at: middle.location, effectiveRange: nil) == nil)
        precondition(view.textStorage!.attribute(.backgroundColor, at: selection.location, effectiveRange: nil) != nil)
        store.update(selection: NSRange(location: 0, length: text.length), verses: verses, color: 3)
        precondition(store.highlights.count == 2, "Cross-verse selection not split correctly.")
        for h in store.highlights { precondition(h.start == 0 && h.end == (verses[h.verse - 1].text as NSString).length) }
        store.update(selection: NSRange(location: 0, length: text.length), verses: verses, color: nil)
        precondition(store.highlights.isEmpty && HighlightStore(path: path).highlights.isEmpty)
        print("Live rendering, persistence, Unicode, recoloring, partial removal, and cross-verse highlights passed.")
    }
}
