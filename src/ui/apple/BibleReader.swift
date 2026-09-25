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

import Foundation

struct ReaderPiece: Sendable {
    let text: String
    let red: Bool
    let italic: Bool
}

struct ReaderVerse: Identifiable, Sendable {
    let book: String
    let chapter: Int
    let number: Int
    let text: String
    let pieces: [ReaderPiece]
    var id: String { "\(book) \(chapter):\(number)" }
    init(_ verse: BibleVerse) {
        pieces = verse.pieces.map { ReaderPiece(text: $0.text, red: $0.red, italic: $0.italic) }
        book = verse.book; chapter = verse.chapter; number = verse.number; text = verse.text
    }
}

struct BibleReference {
    let book: String
    let chapter: Int
    let verse: Int

    static func parse(_ input: String) -> BibleReference? {
        let pattern = #"^\s*(.+?)\s+(\d+)\s*(?::\s*(\d+))?\s*$"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let bookRange = Range(match.range(at: 1), in: input),
              let chapterRange = Range(match.range(at: 2), in: input),
              let chapter = Int(input[chapterRange]) else { return nil }
        let name = input[bookRange].split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        let book = BibleBridge.canonicalBook(name)
        guard !book.isEmpty else { return nil }
        var verse = 1
        if let range = Range(match.range(at: 3), in: input) {
            guard let value = Int(input[range]) else { return nil }
            verse = value
        }
        return BibleReference(book: book, chapter: chapter, verse: verse)
    }
}

enum BibleReader {
    static func path() throws -> String {
        guard let url = Bundle.main.url(forResource: "kjv", withExtension: "db", subdirectory: "Bible/Translations") else {
            throw NSError(domain: "BibleViewer", code: 1, userInfo: [NSLocalizedDescriptionKey: "The bundled KJV Bible database could not be found."])
        }
        return url.path
    }
    static func chapter(book: String, chapter: Int) throws -> [ReaderVerse] {
        try BibleBridge.verses(atPath: path(), book: book, chapter: chapter, firstVerse: 1, limit: -1).map(ReaderVerse.init)
    }
    static func search(_ text: String) throws -> [ReaderVerse] {
        try BibleBridge.search(atPath: path(), text: text).map(ReaderVerse.init)
    }
}
