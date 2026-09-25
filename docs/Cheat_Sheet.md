# Bible Core Cheat Sheet

C++17 · Link target: `bible_core` · Headers: `bible.hpp`, `util.hpp`

See [API setup](API.md) for linking instructions. The reference below covers the
API currently built into `bible_core`; the unfinished `StrongsBackend` is not
included in that target.

## Quick start

Run this example from the repository root, or supply your own database path.

```cpp
#include <bible.hpp>
#include <iostream>

int main()
{
  BibleBackend bible("assets/Bible/Translations/kjv.db");
  if (!bible.lastError().empty()) {
    std::cerr << bible.lastError() << '\n';
    return 1;
  }

  bible.getChapter("John", 3, 16, 1); // John 3:16 only
  if (!bible.lastError().empty()) {
    std::cerr << bible.lastError() << '\n';
    return 1;
  }

  for (const Bible& verse : bible.verses()) {
    std::cout << verse.book << ' ' << verse.chapter << ':' << verse.verse << ' ';
    for (const FormattedPiece& piece : verse.formated_pieces) {
      std::cout << piece.value;
    }
    std::cout << '\n';
  }
}
```

## BibleBackend

| Call | Result / behavior |
| --- | --- |
| `BibleBackend(std::string db_path)` | Opens a SQLite Bible database read-only. Check `lastError()` after construction. |
| `getChapter(std::string book, int chapter, int verse, int limit = -1)` | Loads verses in one chapter, starting at `verse` (inclusive), in verse order. `limit` is the maximum number of verses; `-1` means the rest of the chapter. Returns `void`. |
| `searchBibleText(std::string search)` | Searches stored scripture text across the Bible, ordered by book, chapter, and verse. Returns `void`. |
| `verses() const` | Returns `const std::vector<Bible>&` containing the latest chapter/search results. |
| `books()` | Returns `std::vector<std::pair<std::string, int>>`: book name and highest chapter number, in canonical book order. Does not replace verse results. |
| `lastError() const` | Returns `const std::string&`; empty means no database/query error. |
| `printBibleToConsole()` | Prints the loaded verses without styling. **Only call when `verses()` is nonempty.** |

The backend closes its database on destruction and cannot be copied.

## Common queries

Each chapter/search call replaces the previous verse results. Read or copy the
results before making another query.

```cpp
bible.getChapter("John", 3, 1);       // Entire chapter
bible.getChapter("John", 3, 16, 1);   // One verse
bible.getChapter("John", 3, 16, 3);   // Verses 16–18
bible.getChapter("John", 3, 16);      // Verse 16 through the chapter's end
bible.searchBibleText("God so loved"); // Text search, not reference parsing

for (const auto& [book, chapters] : bible.books()) {
    std::cout << book << ": " << chapters << " chapters\n";
}

// Own a copy if results must survive the next chapter/search call.
auto savedVerses = bible.verses();

if (!bible.verses().empty()) {
    bible.printBibleToConsole();
}
```

- Chapter and verse numbers are 1-based. Book names are case-insensitive;
  supported aliases include `"Jn"`, `"Gen"`, and `"1 Cor"`.
- Search uses SQLite `LIKE '%query%'` against the stored text, including markup.
  `%` and `_` act as wildcards; an empty search matches all verses.
- Check `lastError()` immediately after a call. Chapter/search calls and `books()`
  clear the previous error. Empty results with no error mean no matches, including
  an unknown book or a nonexistent chapter/verse.

## Verse data and formatting

| Type / member | Meaning |
| --- | --- |
| `Bible.book` | Canonical book name (`std::string`). |
| `Bible.chapter`, `Bible.verse` | Chapter and verse numbers (`int`). |
| `Bible.formated_pieces` | Ordered `std::vector<FormattedPiece>`; this is the API's exact spelling. |
| `FormattedPiece.value` | Text for this piece (`std::string`). Concatenate pieces to obtain verse text. |
| `FormattedPiece.type` | `PieceType`: `TEXT`, `ITALIC`, `BOLD`, `RED`, `HEB`, or `LAT`. |
| `FormattedPiece.isRed` | Whether red-letter styling applies (`bool`). |
| `FormattedPiece.isItalic` | Whether italic styling applies (`bool`). |

For rendering, use `isRed` and `isItalic` independently: both can be true for a
nested span. `type` alone cannot represent both styles at once. Piece values do
not include the book name, chapter number, or verse number.

## Book helpers (`util.hpp`)

| Call | Result |
| --- | --- |
| `bookToIndex("Jn")` | `43`; accepts canonical names and supported aliases, ignoring case. Unknown names return `0`. |
| `indexToBook(43)` | `"John"`; valid indices are `1`–`66`, otherwise returns `""`. |
| `lowerCase("JOHN")` | `"john"`; returns a lowercase copy of a string. |

Book helpers do not trim whitespace. For the complete alias list, see
[`src/core/util.cpp`](../src/core/util.cpp).
