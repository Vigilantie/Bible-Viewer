import AppKit
import SwiftUI

private final class BodyCounter {
    var count = 0
}

private struct ResizeHarness: View {
    let counter: BodyCounter
    let verses: [ReaderVerse]
    var fontSize = 21.0
    var red = true
    var italic = true
    var highlights: [StoredHighlight] = []
    var showNotes = true
    var body: some View {
        counter.count += 1
        return ReadingSplitView(
            reading: ScriptureText(verses: verses, fontSize: fontSize, redLetters: red, italics: italic,
                                   targetRange: NSRange(location: 0, length: 0), highlights: highlights, onLookup: { _ in }),
            notes: TextEditor(text: .constant("Resize regression notes")), showNotes: showNotes)
    }
}

@main
struct ResizePerformanceTests {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let verses = try BibleBridge.verses(atPath: CommandLine.arguments[1], book: "Psalms", chapter: 119, firstVerse: 1, limit: -1).map(ReaderVerse.init)
        precondition(verses.count == 176)

        let cache = ScriptureRenderCache()
        func render(fontSize: Double = 21, red: Bool = true, italic: Bool = true, highlights: [StoredHighlight] = []) -> NSAttributedString? {
            cache.updatedChapter(verses, fontSize: fontSize, redLetters: red, italics: italic, highlights: highlights)
        }
        precondition(render() != nil)
        let start = Date()
        for _ in 0..<1_000 {
            precondition(render() == nil, "An unchanged chapter was formatted again during layout.")
        }
        print("1,000 unchanged rendering updates: \(Date().timeIntervalSince(start)) seconds")
        precondition(render(fontSize: 23) != nil, "Font changes must invalidate formatting.")
        precondition(render(red: false) != nil, "Red-letter changes must invalidate formatting.")
        precondition(render(italic: false) != nil, "Italic changes must invalidate formatting.")
        let highlight = StoredHighlight(book: "Psalms", chapter: 119, verse: 1, start: 0, end: 5, color: 2)
        let marked = render(highlights: [highlight])!
        precondition(marked.attribute(.backgroundColor, at: 3, effectiveRange: nil) != nil)
        precondition(render(highlights: [highlight]) == nil)
        precondition(render() != nil, "Removing highlights must invalidate formatting.")
        precondition(cache.updatedChapter(Array(verses.prefix(2)), fontSize: 21, redLetters: true, italics: true) != nil,
                     "Chapter changes must invalidate formatting.")

        let counter = BodyCounter()
        let host = NSHostingView(rootView: ResizeHarness(counter: counter, verses: verses))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.contentView = host
        func settle() {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
        }
        func find<T: NSView>(_ type: T.Type, in view: NSView) -> T? {
            if let match = view as? T { return match }
            return view.subviews.lazy.compactMap { find(type, in: $0) }.first
        }
        settle()
        let split = find(NSSplitView.self, in: host)!
        let reader = find(NSTextView.self, in: split.subviews[0])!
        let originalText = reader.string
        let selection = (originalText as NSString).range(of: verses[10].text)
        reader.setSelectedRange(selection)
        let initialBodyCount = counter.count
        let initialStorage = reader.textStorage!
        let resizeStart = Date()
        for index in 0..<100 {
            let notesWidth = CGFloat(220 + (index * 37) % 221)
            split.setPosition(split.bounds.width - split.dividerThickness - notesWidth, ofDividerAt: 0)
            settle()
            precondition(find(NSTextView.self, in: split.subviews[0]) === reader, "Resize recreated the reader.")
            precondition(reader.textStorage === initialStorage)
            precondition(reader.string == originalText && reader.selectedRange() == selection,
                         "Resize replaced text or reset the selection.")
            precondition(abs(split.subviews[1].frame.width - notesWidth) < 1)
            precondition(abs(split.subviews[1].frame.minX - split.subviews[0].frame.maxX - 12) < 1)
        }
        precondition(counter.count == initialBodyCount, "Divider resizing reevaluated the parent SwiftUI view.")
        print("100 long-chapter pane resizes: \(Date().timeIntervalSince(resizeStart)) seconds; parent body unchanged.")
        var notesWidth = split.subviews[1].frame.width
        for width in [850.0, 1200.0, 700.0, 1100.0] {
            window.setContentSize(NSSize(width: width, height: 700))
            settle()
            notesWidth = min(notesWidth, width - 360 - split.dividerThickness)
            precondition(abs(split.subviews[1].frame.width - notesWidth) < 1,
                         "Window resizing must preserve notes width or clamp to the available space.")
        }
        host.rootView = ResizeHarness(counter: counter, verses: verses, fontSize: 25, red: false, italic: false, highlights: [highlight])
        settle()
        precondition(find(NSTextView.self, in: split.subviews[0]) === reader)
        precondition((reader.textStorage!.attribute(.font, at: 3, effectiveRange: nil) as! NSFont).pointSize == 25)
        precondition(reader.textStorage!.attribute(.backgroundColor, at: 3, effectiveRange: nil) != nil,
                     "Highlights must still update through the native split view.")
        host.rootView = ResizeHarness(counter: counter, verses: verses)
        settle()
        precondition(reader.textStorage!.attribute(.backgroundColor, at: 3, effectiveRange: nil) == nil)
        let notesEditor = find(NSTextView.self, in: split.subviews[1])!
        let notesText = notesEditor.string
        let savedWidth = split.subviews[1].frame.width
        reader.setSelectedRange(selection)
        for _ in 0..<10 {
            host.rootView = ResizeHarness(counter: counter, verses: verses, showNotes: false)
            settle()
            precondition(find(NSSplitView.self, in: host) === split, "Hiding notes recreated the split view.")
            precondition(split.subviews[1].isHidden && split.dividerThickness == 0, "Notes and the divider must hide together.")
            precondition(split.subviews[0].frame == split.bounds, "The Bible must fill the space when notes are hidden.")
            precondition(find(NSTextView.self, in: split.subviews[0]) === reader && reader.selectedRange() == selection)
            host.rootView = ResizeHarness(counter: counter, verses: verses)
            settle()
            precondition(!split.subviews[1].isHidden && split.dividerThickness == 12)
            precondition(abs(split.subviews[1].frame.width - savedWidth) < 1, "Showing notes must restore the resized width.")
            precondition(find(NSTextView.self, in: split.subviews[1]) === notesEditor && notesEditor.string == notesText)
        }
        host.rootView = ResizeHarness(counter: counter, verses: verses, showNotes: false)
        settle()
        window.setContentSize(NSSize(width: 900, height: 700))
        settle()
        precondition(split.subviews[0].frame == split.bounds)
        host.rootView = ResizeHarness(counter: counter, verses: verses)
        settle()
        precondition(abs(split.subviews[1].frame.width - savedWidth) < 1)
        split.setPosition(split.bounds.width - 12 - 260, ofDividerAt: 0)
        settle()
        precondition(abs(split.subviews[1].frame.width - 260) < 1, "Pane resizing must still work after showing notes.")
        print("Resize regression passed, including 10 hide/show cycles, width restoration, notes preservation, and resizing after toggling.")
    }
}
