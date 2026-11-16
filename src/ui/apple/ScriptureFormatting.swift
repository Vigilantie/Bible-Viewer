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
#else
import UIKit
#endif

enum ScriptureFormatting {
    static func chapter(_ verses: [ReaderVerse], fontSize: Double, redLetters: Bool, italics: Bool, highlights: [StoredHighlight] = []) -> NSAttributedString {
        #if os(macOS)
        let font = NSFont(name: "Georgia", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let italicFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        let color = NSColor.labelColor
        let red = NSColor.systemRed
        #else
        let font = UIFont(name: "Georgia", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        let italicFont = font.fontDescriptor.withSymbolicTraits(.traitItalic).map { UIFont(descriptor: $0, size: fontSize) } ?? font
        let color = UIColor.label
        let red = UIColor.systemRed
        #endif
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 7
        let base: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
        let result = NSMutableAttributedString(string: "")
        for (index, verse) in verses.enumerated() {
            if index > 0 { result.append(NSAttributedString(string: "\n\n", attributes: base)) }
            result.append(NSAttributedString(string: "\(verse.number)  ", attributes: base))
            let verseStart = result.length
            for piece in verse.pieces {
                var attributes = base
                if redLetters && piece.red { attributes[.foregroundColor] = red }
                if italics && piece.italic { attributes[.font] = italicFont }
                result.append(NSAttributedString(string: piece.text, attributes: attributes))
            }
            #if os(macOS)
            let colors: [NSColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemBlue, .systemPurple, .systemIndigo, .systemGray, .black]
            #else
            let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemBlue, .systemPurple, .systemIndigo, .systemGray, .black]
            #endif
            for highlight in highlights where highlight.book == verse.book && highlight.chapter == verse.chapter && highlight.verse == verse.number {
                guard highlight.start >= 0, highlight.end > highlight.start, highlight.end <= (verse.text as NSString).length, colors.indices.contains(highlight.color) else { continue }
                result.addAttribute(.backgroundColor, value: colors[highlight.color].withAlphaComponent(0.30), range: NSRange(location: verseStart + highlight.start, length: highlight.end - highlight.start))
            }
        }
        return result
    }

    static func searchText(_ verse: ReaderVerse, redLetters: Bool, italics: Bool) -> Text {
        verse.pieces.reduce(Text("")) { result, piece in
            var text = Text(piece.text).foregroundColor(redLetters && piece.red ? .red : .primary)
            if italics && piece.italic { text = text.italic() }
            return result + text
        }
    }
}

// Formatting depends on content and reading settings, never viewport size.
// Return nil on layout-only updates so native text storage stays untouched.
final class ScriptureRenderCache {
    private struct Input: Equatable {
        let verses: [ReaderVerse]
        let fontSize: Double
        let redLetters: Bool
        let italics: Bool
        let highlights: [StoredHighlight]
    }
    private var previous: Input?

    func updatedChapter(_ verses: [ReaderVerse], fontSize: Double, redLetters: Bool, italics: Bool, highlights: [StoredHighlight] = []) -> NSAttributedString? {
        let input = Input(verses: verses, fontSize: fontSize, redLetters: redLetters, italics: italics, highlights: highlights)
        guard input != previous else { return nil }
        previous = input
        return ScriptureFormatting.chapter(verses, fontSize: fontSize, redLetters: redLetters, italics: italics, highlights: highlights)
    }
}
