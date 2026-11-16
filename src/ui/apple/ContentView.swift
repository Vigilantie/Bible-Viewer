/*
  Bible Viewer - Studing made easy.

  Copyright (C) 2026  Jacob T. Ward

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
*/

import SwiftUI
#if os(macOS)
import AppKit
import CoreServices
#else
import UIKit
#endif

private enum ReaderStyle {
  static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
    #if os(macOS)
      Color(nsColor: NSColor(name: nil) { appearance in
        let rgb = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        return NSColor(srgbRed: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
      })
    #else
      Color(uiColor: UIColor { traits in
        let rgb = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
      })
    #endif
  }
  static let canvas = adaptive(light: (0.92, 0.92, 0.92), dark: (0.11, 0.11, 0.11))
  static let paper = adaptive(light: (0.98, 0.98, 0.98), dark: (0.17, 0.17, 0.17))
  static let panel = adaptive(light: (0.96, 0.96, 0.96), dark: (0.15, 0.15, 0.15))
  static let accent = adaptive(light: (0.36, 0.36, 0.36), dark: (0.73, 0.73, 0.73))
  static let border = Color.primary.opacity(0.09)
  static let gap: CGFloat = 12
  static let radius: CGFloat = 14
}

struct ContentView: View {
    @StateObject private var highlightStore = HighlightStore()

    @AppStorage("lastReadBook") private var lastReadBook = "John"
    @AppStorage("lastReadChapter") private var lastReadChapter = 1
    @AppStorage("showNotes") private var showNotes = true
    @AppStorage("readingFontSize") private var fontSize = 21.0
    @AppStorage("showRedLetters") private var showRedLetters = true
    @AppStorage("showItalics") private var showItalics = true

    @State private var book = "John"
    @State private var chapter = 1
    @State private var catalog: [String: Int] = [:]
    @State private var orderedBooks: [String] = []
    @State private var verses: [ReaderVerse] = []
    @State private var matches: [ReaderVerse] = []
    @State private var targetVerse: Int?
    @State private var formattingRevision = 0
    @State private var loadingError: String?
    @State private var searchError: String?
    @State private var searching = false
    @State private var search = ""
    @State private var showDictionary = false
    @State private var lookupWord = ""

    @FocusState private var searchFocused: Bool

    private let accent = ReaderStyle.accent
    private var passageID: String { "\(book) \(chapter)" }
    private var targetRange: NSRange {
        guard let targetVerse else { return NSRange(location: 0, length: 0) }
        var offset = 0
        for verse in verses {
            let line = "\(verse.number)  \(verse.text)"
            if verse.number == targetVerse { return NSRange(location: offset, length: (line as NSString).length) }
            offset += (line as NSString).length + 2
        }
        return NSRange(location: 0, length: 0)
    }
    private var query: String { search.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        let notesVisible = showNotes
        return VStack(spacing: ReaderStyle.gap) {
            header
            GeometryReader { geometry in
                if geometry.size.width < 640 {
                    VStack(spacing: ReaderStyle.gap) {
                        reader
                        if notesVisible {
                            NotesPane(passageID: passageID).id(passageID).frame(height: geometry.size.height * 0.36)
                        }
                    }
                } else {
                    #if os(macOS)
                    ReadingSplitView(reading: reader, notes: NotesPane(passageID: passageID).id(passageID), showNotes: notesVisible)
                    #else
                    HStack(spacing: ReaderStyle.gap) {
                        reader
                        if notesVisible {
                            NotesPane(passageID: passageID).id(passageID).frame(width: 280)
                        }
                    }
                    #endif
                }
            }
        }
        .padding(ReaderStyle.gap)
        .background(ReaderStyle.canvas)
        .task {
            do {
                catalog = try BibleBridge.books(atPath: BibleReader.path()).mapValues { $0.intValue }
                orderedBooks = BibleBridge.bookNames().filter { catalog[$0] != nil }
                book = catalog[lastReadBook] != nil ? lastReadBook : "John"
                chapter = min(max(lastReadChapter, 1), catalog[book] ?? 1)
                loadChapter()
            } catch { loadingError = error.localizedDescription }
        }
        .task(id: query) { await updateSearch() }
        .onChange(of: showRedLetters) { _ in refreshFormatting() }
        .onChange(of: showItalics) { _ in refreshFormatting() }
        .onChange(of: fontSize) { _ in refreshFormatting() }
        .tint(accent)
        #if os(macOS)
        .frame(minWidth: 580, minHeight: 420)
        #endif
        .alert("Highlight could not be saved or loaded", isPresented: Binding(get: { highlightStore.error != nil }, set: { if !$0 { highlightStore.error = nil } })) {
            Button("OK") { highlightStore.error = nil }
        } message: { Text(highlightStore.error ?? "") }
        .sheet(isPresented: $showDictionary) { DictionaryPopup(word: $lookupWord) }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 18) {
                brand
                passagePicker
                Spacer(minLength: 12)
                searchField.frame(width: 320)
                options
            }
            VStack(spacing: 12) {
                HStack { brand; Spacer(); options }
                HStack(spacing: 16) {
                    passagePicker
                    searchField.frame(maxWidth: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack { brand; Spacer(); options }
                passagePicker
                searchField.frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(ReaderStyle.panel)
        .clipShape(RoundedRectangle(cornerRadius: ReaderStyle.radius))
        .overlay(RoundedRectangle(cornerRadius: ReaderStyle.radius).strokeBorder(ReaderStyle.border))
    }
    private var brand: some View {
        Label {
            Text("Bible Viewer")
        } icon: {
            Image(systemName: "book.closed")
                .foregroundStyle(ReaderStyle.adaptive(light: (0.25, 0.40, 0.33), dark: (0.61, 0.77, 0.66)))
        }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(accent)
            .fixedSize()
    }
    private var passagePicker: some View {
        HStack(spacing: 8) {
            Menu {
                Picker("Book", selection: Binding(get: { book }, set: { value in
                    book = value; chapter = 1; search = ""; targetVerse = nil; loadChapter()
                })) {
                    ForEach(orderedBooks, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                passageMenuLabel(book, width: 148)
            }
            .accessibilityLabel("Book")
            .accessibilityValue(book)
            Menu {
                Picker("Chapter", selection: Binding(get: { chapter }, set: { value in
                    chapter = value; search = ""; targetVerse = nil; loadChapter()
                })) {
                    ForEach(1...max(catalog[book] ?? 1, 1), id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                passageMenuLabel("\(chapter)", width: 64)
            }
            .accessibilityLabel("Chapter")
            .accessibilityValue("\(chapter)")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func passageMenuLabel(_ title: String, width: CGFloat) -> some View {
        HStack(spacing: 8) {
            Text(title).lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .frame(width: width, height: 42)
        .background(ReaderStyle.paper, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(ReaderStyle.border))
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search", text: $search).textFieldStyle(.plain).focused($searchFocused)
                .onSubmit(submitSearch)
            if !search.isEmpty {
                Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain).accessibilityLabel("Clear search")
            }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 12)
        .frame(minWidth: 220, minHeight: 42)
        .background(ReaderStyle.paper, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(searchFocused ? accent.opacity(0.7) : ReaderStyle.border))
        .accessibilityLabel("Search the Bible")
    }
    private var options: some View {
        Menu {
            Button(showNotes ? "Hide Notes" : "Show Notes") { showNotes.toggle() }
            Button("Dictionary…") { showDictionary = true }
            Button("Find…") { searchFocused = true }.keyboardShortcut("f")
            Divider()
            Toggle("Red Letters", isOn: $showRedLetters)
            Toggle("Italics", isOn: $showItalics)
            Divider()
            Button("Larger Text") { fontSize = min(fontSize + 2, 32) }.disabled(fontSize >= 32)
            Button("Smaller Text") { fontSize = max(fontSize - 2, 14) }.disabled(fontSize <= 14)
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 38, height: 42)
                .background(ReaderStyle.paper, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(ReaderStyle.border))
        }
        .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("Reading options")
    }
    private var reader: some View {
        VStack(alignment: .leading, spacing: 0) {
            bookHeader
            Divider().padding(.horizontal, 28)

            if let loadingError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unable to load passages").font(.headline)
                    Text(loadingError).foregroundStyle(.secondary)
                }
                    .padding(28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if verses.isEmpty {
                ProgressView("Loading passages…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if query.isEmpty {
                ScriptureText(verses: verses, fontSize: fontSize, redLetters: showRedLetters, italics: showItalics, targetRange: targetRange, highlights: highlightStore.highlights, onHighlight: {
                     range, color in
                     highlightStore.update(selection: range, verses: verses, color: color)
                }) {
                    word in
                    lookupWord = word
                    showDictionary = true
                }
                    .id("\(passageID):\(targetVerse ?? 0):\(formattingRevision)")
            } else {
                searchResults
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ReaderStyle.paper)
        .clipShape(RoundedRectangle(cornerRadius: ReaderStyle.radius))
        .overlay(RoundedRectangle(cornerRadius: ReaderStyle.radius).strokeBorder(ReaderStyle.border))
    }
    private var bookHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(query.isEmpty ? passageID : "Search results")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                Text("KING JAMES VERSION")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.8).foregroundStyle(accent)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
    }
    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if searching { ProgressView("Searching the Bible…") }
                else if let searchError { Text(searchError).foregroundStyle(.secondary) }
                else {
                    Text("\(matches.count) results in the Bible").font(.caption).foregroundStyle(.secondary)
                    ForEach(matches) { match in
                        Button { open(book: match.book, chapter: match.chapter, verse: match.number) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(match.id).font(.caption.weight(.semibold)).foregroundStyle(accent)
                                ScriptureFormatting.searchText(match, redLetters: showRedLetters, italics: showItalics).font(.system(size: 17, design: .serif)).multilineTextAlignment(.leading)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain)
                    }
                    if matches.isEmpty { Text("No matching verses. Try another word or phrase.").foregroundStyle(.secondary) }
                }
            }.padding(.horizontal, 28).padding(.vertical, 24)
        }.id("\(query):\(formattingRevision)")
    }

    private func refreshFormatting() {
        // Explicitly rebuild the native text view when a persisted menu setting
        // changes, even though the chapter and its plain text are unchanged.
        formattingRevision += 1
    }

    private func loadChapter() {
        do {
            verses = try BibleReader.chapter(book: book, chapter: chapter)
            loadingError = nil
            saveReadingLocation()
        }
        catch { verses = []; loadingError = error.localizedDescription }
    }

    private func open(book: String, chapter: Int, verse: Int) {
        do {
            guard chapter > 0, chapter <= (catalog[book] ?? 0), verse > 0 else {
                searchError = "That reference is outside the available chapters or verses."; return
            }
            let loaded = try BibleReader.chapter(book: book, chapter: chapter)
            guard loaded.contains(where: { $0.number == verse }) else {
                searchError = "\(book) \(chapter) does not contain verse \(verse)."; return
            }
            self.book = book; self.chapter = chapter; targetVerse = verse
            verses = loaded; loadingError = nil; search = ""
            saveReadingLocation()
        } catch { searchError = error.localizedDescription }
    }

    private func saveReadingLocation() {
        lastReadBook = book
        lastReadChapter = chapter
    }

    private func submitSearch() {
        if let reference = BibleReference.parse(query) {
            open(book: reference.book, chapter: reference.chapter, verse: reference.verse)
        }
    }

    private func updateSearch() async {
        let input = query
        matches = []; searchError = nil
        guard !input.isEmpty else { searching = false; return }
        searching = true
        do {
            try await Task.sleep(nanoseconds: 250_000_000)
            let results: [ReaderVerse]
            if let reference = BibleReference.parse(input) {
                guard reference.chapter > 0, reference.chapter <= (catalog[reference.book] ?? 0), reference.verse > 0 else {
                    searching = false; searchError = "That reference is outside the available chapters or verses."; return
                }
                results = try BibleReader.chapter(book: reference.book, chapter: reference.chapter).filter { $0.number == reference.verse }
            } else {
                results = try await Task.detached(priority: .userInitiated) { try BibleReader.search(input) }.value
            }
            try Task.checkCancellation()
            matches = results; searching = false
            if BibleReference.parse(input) != nil && results.isEmpty { searchError = "That verse does not exist. Check the reference." }
        } catch is CancellationError {
            // A newer query owns the visible results.
        } catch {
            guard !Task.isCancelled else { return }
            searchError = error.localizedDescription; searching = false
        }
    }
}

private struct NotesPane: View {
    let passageID: String
    @AppStorage private var notes: String
    init(passageID: String) {
        self.passageID = passageID
        _notes = AppStorage(wrappedValue: "", "notes.\(passageID)")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Notes", systemImage: "square.and.pencil")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ReaderStyle.accent)
                Spacer()
            }
            Text(passageID).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Divider()
            ZStack(alignment: .topLeading) {
                #if os(macOS)
                NotesEditor(text: $notes)
                    .accessibilityLabel("Notes for \(passageID)")
                #else
                TextEditor(text: $notes).font(.body).scrollContentBackground(.hidden)
                    .accessibilityLabel("Notes for \(passageID)")
                #endif
                if notes.isEmpty {
                    Text("Write your thoughts.")
                        .font(.body)
                        .foregroundStyle(.secondary.opacity(0.7))
                        .padding(.top, 8)
                        .padding(.horizontal, 5)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
//            Text("Saved automatically on this device")
//                .font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ReaderStyle.panel)
        .clipShape(RoundedRectangle(cornerRadius: ReaderStyle.radius))
        .overlay(RoundedRectangle(cornerRadius: ReaderStyle.radius).strokeBorder(ReaderStyle.border))
    }
}

private struct DictionaryPopup: View {
    @Binding var word: String
    @Environment(\.dismiss) private var dismiss
    @State private var definition = "Type a word above to look it up."
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Dictionary", systemImage: "character.book.closed").font(.title2)
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            HStack {
                TextField("Type a word", text: $word).textFieldStyle(.roundedBorder).onSubmit(lookup)
                Button("Look Up", action: lookup).disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            #if os(macOS)
            ScrollView { Text(definition).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
            #else
            if !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                SystemDictionary(word: word).id(word)
            } else { Text(definition).foregroundStyle(.secondary); Spacer() }
            #endif
        }.padding(24)
        .frame(minWidth: 300, idealWidth: 460, minHeight: 340, idealHeight: 420)
        .onAppear(perform: lookup)
    }
    private func lookup() {
        let term = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { definition = "Type a word above to look it up."; return }
        #if os(macOS)
        if let result = DCSCopyTextDefinition(nil, term as CFString, CFRange(location: 0, length: (term as NSString).length)) {
            definition = result.takeRetainedValue() as String
        } else {
            definition = "No definition found for “\(term)”. Try another word, or enable a dictionary in the macOS Dictionary app."
        }
        #endif
    }
}

#if os(macOS)
// AppKit owns divider tracking and child frames. A drag must not mutate the
// main SwiftUI view's state or rebuild its menus on every mouse movement.
struct ReadingSplitView<Reading: View, Notes: View>: NSViewRepresentable {
    let reading: Reading
    let notes: Notes
    var showNotes = true

    final class Coordinator: NSObject, NSSplitViewDelegate {
        let readingHost: NSHostingView<Reading>
        let notesHost: NSHostingView<Notes>
        init(_ parent: ReadingSplitView) {
            readingHost = NSHostingView(rootView: parent.reading)
            notesHost = NSHostingView(rootView: parent.notes)
            super.init()
            // The split view provides the frames; hosted text must not feed
            // its document's intrinsic size back into the split layout.
            readingHost.sizingOptions = []
            notesHost.sizingOptions = []
        }
        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            max(360, splitView.bounds.width - 440 - splitView.dividerThickness)
        }
        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            splitView.bounds.width - 220 - splitView.dividerThickness
        }
        func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool { false }
        func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
            splitView.subviews.last?.isHidden == true
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSSplitView {
        let split = ReaderPaneSplitView()
        split.isVertical = true
        split.delegate = context.coordinator
        split.addArrangedSubview(context.coordinator.readingHost)
        split.addArrangedSubview(context.coordinator.notesHost)
        return split
    }
    func updateNSView(_ split: NSSplitView, context: Context) {
        context.coordinator.readingHost.rootView = reading
        context.coordinator.notesHost.rootView = notes
        (split as? ReaderPaneSplitView)?.setNotesVisible(showNotes)
    }
}

private final class ReaderPaneSplitView: NSSplitView {
    private var notesVisible = true
    private var savedNotesWidth: CGFloat = 300
    override var dividerThickness: CGFloat { notesVisible ? ReaderStyle.gap : 0 }

    func setNotesVisible(_ visible: Bool) {
        guard visible != notesVisible, subviews.count == 2 else { return }
        if !visible { savedNotesWidth = subviews[1].frame.width }
        notesVisible = visible
        subviews[1].isHidden = !visible
        if visible {
            var frame = subviews[1].frame
            frame.size.width = savedNotesWidth
            subviews[1].frame = frame
        }
        resizeSubviews(withOldSize: bounds.size)
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
    }
    override func drawDivider(in rect: NSRect) {
        NSColor(ReaderStyle.canvas).setFill()
        rect.fill()
    }
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        guard subviews.count == 2, bounds.width > dividerThickness else { return }
        guard notesVisible else {
            subviews[0].frame = bounds
            return
        }
        let availableWidth = bounds.width - dividerThickness
        let maximumNotesWidth = min(440, max(0, availableWidth - 360))
        let minimumNotesWidth = min(220, maximumNotesWidth)
        let previousNotesWidth = subviews[1].frame.width
        let notesWidth = min(max(previousNotesWidth > 0 ? previousNotesWidth : 300, minimumNotesWidth), maximumNotesWidth)
        let readingWidth = availableWidth - notesWidth
        subviews[0].frame = NSRect(x: 0, y: 0, width: readingWidth, height: bounds.height)
        subviews[1].frame = NSRect(x: readingWidth + dividerThickness, y: 0, width: notesWidth, height: bounds.height)
    }
}

// Overlay scrollers avoid reserving a bright gutter inside the reading cards.
private func configureReaderScrollView(_ scroll: NSScrollView) {
    scroll.hasVerticalScroller = true
    scroll.hasHorizontalScroller = false
    scroll.autohidesScrollers = true
    scroll.scrollerStyle = .overlay
    scroll.borderType = .noBorder
    scroll.drawsBackground = false
}

private struct NotesEditor: NSViewRepresentable {
    @Binding var text: String

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NotesEditor
        init(_ parent: NotesEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let editor = notification.object as? NSTextView else { return }
            parent.text = editor.string
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        let editor = NSTextView()
        editor.font = .systemFont(ofSize: 14)
        editor.textColor = .labelColor
        editor.insertionPointColor = .labelColor
        editor.isRichText = false
        editor.allowsUndo = true
        editor.drawsBackground = false
        editor.textContainerInset = NSSize(width: 0, height: 8)
        editor.isVerticallyResizable = true
        editor.isHorizontallyResizable = false
        editor.autoresizingMask = [.width]
        editor.textContainer?.widthTracksTextView = true
        editor.delegate = context.coordinator
        scroll.documentView = editor
        configureReaderScrollView(scroll)
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let editor = scroll.documentView as? NSTextView else { return }
        if editor.string != text {
            editor.string = text
            editor.setSelectedRange(NSRange(location: 0, length: 0))
            scroll.contentView.scroll(to: .zero)
        }
    }
}

struct ScriptureText: NSViewRepresentable {
    let verses: [ReaderVerse]
    let fontSize: Double
    let redLetters: Bool
    let italics: Bool
    let targetRange: NSRange
    var highlights: [StoredHighlight] = []
    var onHighlight: ((NSRange, Int?) -> Void)? = nil
    let onLookup: (String) -> Void
    final class Coordinator { let rendering = ScriptureRenderCache() }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        let view = LookupTextView()
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textContainerInset = NSSize(width: 28, height: 8)
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        scroll.documentView = view
        configureReaderScrollView(scroll)
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let view = scroll.documentView as? LookupTextView else { return }
        view.onLookup = onLookup
        view.onHighlight = onHighlight
        if let attributedText = context.coordinator.rendering.updatedChapter(verses, fontSize: fontSize, redLetters: redLetters, italics: italics, highlights: highlights) {
            let selection = view.selectedRange()
            view.textStorage?.setAttributedString(attributedText)
            if NSMaxRange(selection) <= attributedText.length { view.setSelectedRange(selection) }
        }
        if view.navigationRange != targetRange {
            view.navigationRange = targetRange
            view.setSelectedRange(targetRange)
            view.pendingNavigationRange = targetRange
            view.needsLayout = true
        }
    }
}

private final class LookupTextView: NSTextView {
    var onLookup: ((String) -> Void)?
    var onHighlight: ((NSRange, Int?) -> Void)?
    var navigationRange: NSRange?
    var pendingNavigationRange: NSRange?
    override func layout() {
        super.layout()
        guard let range = pendingNavigationRange,
              let layoutManager, let textContainer,
              let scroll = enclosingScrollView,
              scroll.contentSize.width > 0, scroll.contentSize.height > 0 else { return }
        pendingNavigationRange = nil
        layoutManager.ensureLayout(for: textContainer)
        let glyphs = layoutManager.glyphRange(forCharacterRange: NSRange(location: range.location, length: 0), actualCharacterRange: nil)
        let rect = layoutManager.lineFragmentRect(forGlyphAt: glyphs.location, effectiveRange: nil)
        let y = max(0, min(rect.minY, frame.height - scroll.contentSize.height))
        scroll.contentView.scroll(to: NSPoint(x: 0, y: y))
        scroll.reflectScrolledClipView(scroll.contentView)
        // Keep the selected verse visible when scrolling is clamped near the chapter end.
        scrollRangeToVisible(range)
    }
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let index = characterIndexForInsertion(at: point)
        if index < (string as NSString).length && !NSLocationInRange(index, selectedRange()) {
            let range = selectionRange(forProposedRange: NSRange(location: index, length: 0), granularity: .selectByWord)
            setSelectedRange(range)
        }
        let menu = super.menu(for: event) ?? NSMenu()
        if selectedRange().length > 0 {
            if onHighlight != nil {
                let highlight = NSMenuItem(title: "Highlight", action: nil, keyEquivalent: "")
                let colors = NSMenu()
                for (index, name) in HighlightStore.colorNames.enumerated() {
                    let color = NSMenuItem(title: name, action: #selector(highlightSelection(_:)), keyEquivalent: "")
                    color.tag = index
                    color.target = self
                    colors.addItem(color)
                }
                highlight.submenu = colors
                menu.insertItem(highlight, at: 0)
                let remove = NSMenuItem(title: "Remove Highlight", action: #selector(removeHighlight), keyEquivalent: "")
                remove.target = self
                menu.insertItem(remove, at: 1)
            }
            let item = NSMenuItem(title: "Look Up in Dictionary", action: #selector(lookupSelection), keyEquivalent: "")
            item.target = self
            menu.insertItem(item, at: 0)
        }
        return menu
    }
    @objc private func highlightSelection(_ sender: NSMenuItem) {
        let range = selectedRange()
        onHighlight?(range, sender.tag)
        setSelectedRange(NSRange(location: range.location, length: 0))
    }
    @objc private func removeHighlight() {
        let range = selectedRange()
        onHighlight?(range, nil)
        setSelectedRange(NSRange(location: range.location, length: 0))
    }
    @objc private func lookupSelection() {
        let selection = (string as NSString).substring(with: selectedRange()).trimmingCharacters(in: .whitespacesAndNewlines)
        if !selection.isEmpty { onLookup?(selection) }
    }
}
#else
struct ScriptureText: UIViewRepresentable {
    let verses: [ReaderVerse]
    let fontSize: Double
    let redLetters: Bool
    let italics: Bool
    let targetRange: NSRange
    var highlights: [StoredHighlight] = []
    var onHighlight: ((NSRange, Int?) -> Void)? = nil
    let onLookup: (String) -> Void
    final class Coordinator {
        var navigationRange: NSRange?
        let rendering = ScriptureRenderCache()
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UITextView {
        let view = NavigatingTextView()
        view.isEditable = false
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(top: 8, left: 24, bottom: 24, right: 24)
        return view
    }
    func updateUIView(_ view: UITextView, context: Context) {
        if let attributedText = context.coordinator.rendering.updatedChapter(verses, fontSize: fontSize, redLetters: redLetters, italics: italics, highlights: highlights) {
            let selection = view.selectedRange
            view.attributedText = attributedText
            if NSMaxRange(selection) <= attributedText.length { view.selectedRange = selection }
        }
        if context.coordinator.navigationRange != targetRange {
            context.coordinator.navigationRange = targetRange
            view.selectedRange = targetRange
            (view as? NavigatingTextView)?.pendingNavigationRange = targetRange
            view.setNeedsLayout()
        }
    }
}
private final class NavigatingTextView: UITextView {
    var pendingNavigationRange: NSRange?
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let range = pendingNavigationRange, bounds.width > 0, bounds.height > 0 else { return }
        pendingNavigationRange = nil
        layoutManager.ensureLayout(for: textContainer)
        let glyphs = layoutManager.glyphRange(forCharacterRange: NSRange(location: range.location, length: 0), actualCharacterRange: nil)
        let rect = layoutManager.lineFragmentRect(forGlyphAt: glyphs.location, effectiveRange: nil)
        let y = max(-adjustedContentInset.top, min(rect.minY, contentSize.height - bounds.height + adjustedContentInset.bottom))
        setContentOffset(CGPoint(x: 0, y: y), animated: false)
        scrollRangeToVisible(range)
    }
}
private struct SystemDictionary: UIViewControllerRepresentable {
    let word: String
    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController { UIReferenceLibraryViewController(term: word) }
    func updateUIViewController(_ controller: UIReferenceLibraryViewController, context: Context) {}
}
#endif

#Preview { ContentView() }
