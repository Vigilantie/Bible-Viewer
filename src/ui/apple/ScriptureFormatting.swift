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
    static func chapter(_ verses: [ReaderVerse], fontSize: Double, redLetters: Bool, italics: Bool) -> NSAttributedString {
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
            for piece in verse.pieces {
                var attributes = base
                if redLetters && piece.red { attributes[.foregroundColor] = red }
                if italics && piece.italic { attributes[.font] = italicFont }
                result.append(NSAttributedString(string: piece.text, attributes: attributes))
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
