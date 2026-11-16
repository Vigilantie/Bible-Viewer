import SwiftUI

struct StoredHighlight: Equatable {
    let book: String
    let chapter: Int
    let verse: Int
    let start: Int
    let end: Int
    let color: Int
    var range: NSRange { NSRange(location: start, length: end - start) }
}

final class HighlightStore: ObservableObject {
    static let colorNames = ["Red", "Orange", "Yellow", "Green", "Blue", "Violet", "Indigo", "Gray", "Black"]
    @Published var highlights: [StoredHighlight] = []
    @Published var error: String?
    private var path: String?

    init(path: String? = nil) {
        do {
            if let path { self.path = path }
            else {
                let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("org.bibleviewer.app", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                self.path = directory.appendingPathComponent("highlights.db").path
            }
            try reload()
        } catch { self.error = error.localizedDescription }
    }
    private func reload() throws {
        guard let path else { return }
        highlights = try BibleBridge.highlights(atPath: path).compactMap { row in
            guard let book = row["book"] as? String,
                  let chapter = row["chapter"] as? Int, let verse = row["verse"] as? Int,
                  let start = row["start"] as? Int, let end = row["end"] as? Int,
                  let color = row["color"] as? Int, start >= 0, end > start,
                  (0..<Self.colorNames.count).contains(color) else { return nil }
            return StoredHighlight(book: book, chapter: chapter, verse: verse, start: start, end: end, color: color)
        }
    }
    private func write(_ h: StoredHighlight, remove: Bool) throws {
        guard let path else { throw NSError(domain: "BibleHighlights", code: 1, userInfo: [NSLocalizedDescriptionKey: "The highlights database is unavailable."]) }
        try BibleBridge.writeHighlight(atPath: path, book: h.book, chapter: h.chapter, verse: h.verse, start: h.start, end: h.end, color: h.color, remove: remove)
    }
    // Native selections use UTF-16 offsets; stored ranges exclude verse numbers and separators.
    static func selections(_ selection: NSRange, verses: [ReaderVerse], color: Int) -> [StoredHighlight] {
        var offset = 0
        var result: [StoredHighlight] = []
        for verse in verses {
            offset += ("\(verse.number)  " as NSString).length
            let length = (verse.text as NSString).length
            let intersection = NSIntersectionRange(selection, NSRange(location: offset, length: length))
            if intersection.length > 0 {
                let start = intersection.location - offset
                result.append(StoredHighlight(book: verse.book, chapter: verse.chapter, verse: verse.number, start: start, end: start + intersection.length, color: color))
            }
            offset += length + 2
        }
        return result
    }
    func update(selection: NSRange, verses: [ReaderVerse], color: Int?) {
        do {
            for selected in Self.selections(selection, verses: verses, color: color ?? 2) {
                let overlaps = highlights.filter { $0.book == selected.book && $0.chapter == selected.chapter && $0.verse == selected.verse && NSIntersectionRange($0.range, selected.range).length > 0 }
                for old in overlaps {
                    try write(old, remove: true)
                    // Preserve portions outside the selection when recoloring or erasing.
                    if old.start < selected.start { try write(StoredHighlight(book: old.book, chapter: old.chapter, verse: old.verse, start: old.start, end: selected.start, color: old.color), remove: false) }
                    if old.end > selected.end { try write(StoredHighlight(book: old.book, chapter: old.chapter, verse: old.verse, start: selected.end, end: old.end, color: old.color), remove: false) }
                }
                if color != nil { try write(selected, remove: false) }
            }
            try reload()
        } catch {
            self.error = error.localizedDescription
            try? reload()
        }
    }
}
