# Highlights

In the macOS reader, select scripture text, right-click, and choose **Highlight**
followed by a color. Select highlighted text and choose **Remove Highlight** to
erase it. Selections can cross verse boundaries. Recoloring or removing part of
a highlight preserves the portions outside the selection.

Highlights save through `bible_core`'s `HighlightDB` in
`~/Library/Application Support/org.bibleviewer.app/highlights.db`. They are
restored when returning to a chapter or reopening the app, independently of
red-letter, italic, and font-size settings. The bundled Bible stays read-only.

`HighlightColors` is a scoped enum so it can coexist with scripture's `RED`
piece type. Use `HighlightColors::YELLOW`, for example. `listAll()` returns saved
records in creation order; `sortByColor()` filters them by color. `lastError()`
reports failures for construction and operations. Identical saves are idempotent.

Offsets are zero-based, half-open UTF-16 ranges in a verse's plain text, excluding
markup, verse numbers, and chapter separators. The UI splits chapter selections
into these ranges before calling the library. Invalid saved ranges are ignored
when rendering. Highlights are specific to the current KJV text.

Regression coverage:

- `tests/highlight_api_tests.cpp`: persistence, duplicate saves, listing, color
  filtering, removal, invalid input, and database-open failure.
- `tests/HighlightIntegrationTests.swift`: context-menu action, immediate native
  text rendering, reopening storage, Unicode ranges, partial recoloring/removal,
  and selections spanning multiple verses.
