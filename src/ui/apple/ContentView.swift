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

struct ContentView: View {
    @AppStorage("lastReadBook") private var lastReadBook = "John"
    @AppStorage("lastReadChapter") private var lastReadChapter = 1
    @State private var book = "John"
    @State private var chapter = 1
    @State private var catalog: [String: Int] = [:]
    @State private var verses: [ReaderVerse] = []
    @State private var matches: [ReaderVerse] = []
    @State private var targetVerse: Int?
    @State private var formattingRevision = 0
    @State private var loadingError: String?
    @State private var searchError: String?
    @State private var searching = false
    @State private var search = ""
    @State private var showNotes = true
    @State private var showDictionary = false
    @State private var lookupWord = ""
    @AppStorage("readingFontSize") private var fontSize = 21.0
    @AppStorage("showRedLetters") private var showRedLetters = true
    @AppStorage("showItalics") private var showItalics = true
    @FocusState private var searchFocused: Bool
    private let accent = Color(red: 0.29, green: 0.43, blue: 0.37)
    private var passageID: String { "\(book) \(chapter)" }
    private var targetRange: NSRange {
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
        VStack(spacing: 0) {
            header
            Divider()
            GeometryReader { geometry in
                if geometry.size.width < 640 {
                    VStack(spacing: 0) {
                        reader
                        if showNotes {
                            Divider()
                            NotesPane(passageID: passageID).frame(height: geometry.size.height * 0.36)
                        }
                    }
                } else {
                    #if os(macOS)
                    HSplitView {
                        reader.frame(minWidth: 360)
                        if showNotes { NotesPane(passageID: passageID).frame(minWidth: 220, idealWidth: 290, maxWidth: 440) }
                    }
                    #else
                    HStack(spacing: 0) {
                        reader
                        if showNotes {
                            Divider()
                            NotesPane(passageID: passageID).frame(width: 280)
                        }
                    }
                    #endif
                }
            }
        }
        .task {
            do {
                catalog = try BibleBridge.books(atPath: BibleReader.path()).mapValues { $0.intValue }
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
        .sheet(isPresented: $showDictionary) { DictionaryPopup(word: $lookupWord) }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 18) { brand; passagePicker; Spacer(); searchField; options }
            VStack(spacing: 12) {
                HStack { brand; Spacer(); options }
                HStack { passagePicker; searchField }
            }
        }
        .padding(16)
        .background(.bar)
    }
    private var brand: some View {
        Label("Bible", systemImage: "book.closed").font(.title3.weight(.semibold)).foregroundStyle(accent)
    }
    private var passagePicker: some View {
        HStack(spacing: 8) {
            Picker("Book", selection: Binding(get: { book }, set: { value in
                book = value; chapter = 1; search = ""; targetVerse = nil; loadChapter()
            })) {
                ForEach(orderedBooks, id: \.self) { Text($0).tag($0) }
            }.labelsHidden().frame(width: 155).accessibilityLabel("Book")
            Picker("Chapter", selection: Binding(get: { chapter }, set: { value in
                chapter = value; search = ""; targetVerse = nil; loadChapter()
            })) {
                ForEach(1...max(catalog[book] ?? 1, 1), id: \.self) { Text("\($0)").tag($0) }
            }.frame(width: 105)
        }
    }
    private var orderedBooks: [String] {
        // Canonical order comes from the core's book index mapping.
        BibleBridge.bookNames().filter { catalog[$0] != nil }
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
        }.padding(8).background(.quaternary, in: RoundedRectangle(cornerRadius: 8)).frame(maxWidth: 250)
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
        } label: { Image(systemName: "line.3.horizontal") }
        .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("Reading options")
    }
    private var reader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(query.isEmpty ? passageID : "Search results").font(.system(size: 28, weight: .medium, design: .serif))
                    Text("KING JAMES VERSION").font(.caption2.weight(.semibold)).tracking(1.4).foregroundStyle(.secondary)
                }
                Spacer()
            }.padding(28)
            if let loadingError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unable to load passages").font(.headline)
                    Text(loadingError).foregroundStyle(.secondary)
                }.padding(28).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if verses.isEmpty {
                ProgressView("Loading passages…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if query.isEmpty {
                ScriptureText(verses: verses, fontSize: fontSize, redLetters: showRedLetters, italics: showItalics, targetRange: targetRange) { word in
                    lookupWord = word
                    showDictionary = true
                }.id("\(passageID):\(targetVerse ?? 0):\(formattingRevision)")
            } else {
                searchResults
            }
            Divider()
            HStack {
                Image(systemName: "text.book.closed")
                Text("Select a word to look it up, or open Dictionary from the menu.")
            }.font(.caption).foregroundStyle(.secondary).padding(12)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
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
            }.padding(.horizontal, 28).padding(.bottom, 24)
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "square.and.pencil").font(.headline)
            Text(passageID).font(.caption).foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes).font(.body).scrollContentBackground(.hidden).accessibilityLabel("Notes for \(passageID)")
                if notes.isEmpty {
                    Text("Write your thoughts, questions,\nor a verse to remember…")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        // macOS TextEditor starts at the top; UIKit adds an 8pt inset.
                        #if !os(macOS)
                        .padding(.top, 8)
                        #endif
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            Text("Saved automatically on this device").font(.caption2).foregroundStyle(.secondary)
        }.padding(20).background(.quaternary.opacity(0.3))
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
struct ScriptureText: NSViewRepresentable {
    let verses: [ReaderVerse]
    let fontSize: Double
    let redLetters: Bool
    let italics: Bool
    let targetRange: NSRange
    let onLookup: (String) -> Void
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
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let view = scroll.documentView as? LookupTextView else { return }
        view.onLookup = onLookup
        let attributedText = ScriptureFormatting.chapter(verses, fontSize: fontSize, redLetters: redLetters, italics: italics)
        if view.textStorage?.isEqual(to: attributedText) != true {
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
        if index < (string as NSString).length {
            let range = selectionRange(forProposedRange: NSRange(location: index, length: 0), granularity: .selectByWord)
            setSelectedRange(range)
        }
        let menu = super.menu(for: event) ?? NSMenu()
        if selectedRange().length > 0 {
            let item = NSMenuItem(title: "Look Up in Dictionary", action: #selector(lookupSelection), keyEquivalent: "")
            item.target = self
            menu.insertItem(item, at: 0)
        }
        return menu
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
    let onLookup: (String) -> Void
    final class Coordinator { var navigationRange: NSRange? }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UITextView {
        let view = NavigatingTextView()
        view.isEditable = false
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(top: 8, left: 24, bottom: 24, right: 24)
        return view
    }
    func updateUIView(_ view: UITextView, context: Context) {
        let attributedText = ScriptureFormatting.chapter(verses, fontSize: fontSize, redLetters: redLetters, italics: italics)
        if !view.attributedText.isEqual(to: attributedText) {
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
