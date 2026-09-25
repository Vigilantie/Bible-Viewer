#import "BibleBridge.h"
#include "bible.hpp"
#include <iostream>
#include <stdexcept>

static void require(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}

int main(int argc, char **argv) {
    @autoreleasepool {
        try {
            require(argc == 2, "Pass the built application bundle path.");
            NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithUTF8String:argv[1]]];
            NSString *path = [bundle pathForResource:@"kjv" ofType:@"db" inDirectory:@"Bible/Translations"];
            require(path != nil, "Bundled database missing.");
            NSError *error = nil;
            NSArray<BibleVerse *> *john = [BibleBridge versesAtPath:path book:@"John" chapter:1 firstVerse:1 limit:5 error:&error];
            require(john.count == 5 && error == nil, "John passage failed.");
            require([john[0].text hasPrefix:@"In the beginning was the Word"], "Unexpected John text.");
            NSArray<BibleVerse *> *genesis = [BibleBridge versesAtPath:path book:@"Genesis" chapter:1 firstVerse:1 limit:5 error:&error];
            require(genesis.count == 5 && genesis.lastObject.number == 5, "Genesis passage failed.");
            NSArray<BibleVerse *> *psalm = [BibleBridge versesAtPath:path book:@"Psalms" chapter:23 firstVerse:1 limit:-1 error:&error];
            require(psalm.count == 6, "Psalm passage failed.");
            require([psalm[0].text containsString:@"The LORD is my shepherd"], "Formatting text missing.");
            require(![psalm[0].text containsString:@"<"], "Markup leaked into plain text.");
            NSDictionary<NSString *, NSNumber *> *books = [BibleBridge booksAtPath:path error:&error];
            require(books.count == 66 && [books[@"Psalms"] intValue] == 150, "Book/chapter catalog incomplete.");
            require([BibleBridge.bookNames.firstObject isEqualToString:@"Genesis"] && [BibleBridge.bookNames.lastObject isEqualToString:@"Revelation"], "Book order incorrect.");
            require([[BibleBridge canonicalBook:@"1 jn"] isEqualToString:@"1 John"], "Numbered book alias failed.");
            int totalVerses = 0;
            int totalChapters = 0;
            for (NSString *book in BibleBridge.bookNames) {
                for (int chapter = 1; chapter <= [books[book] intValue]; ++chapter) {
                    NSArray<BibleVerse *> *verses = [BibleBridge versesAtPath:path book:book chapter:chapter firstVerse:1 limit:-1 error:&error];
                    require(verses.count > 0 && error == nil, "A chapter could not be read.");
                    require([verses[0].book isEqualToString:book] && verses[0].chapter == chapter, "Verse location missing.");
                    totalVerses += verses.count;
                    ++totalChapters;
                }
            }
            require(totalVerses == 31102 && totalChapters == 1189, "Not all Bible verses are reachable.");
            NSArray<BibleVerse *> *search = [BibleBridge searchAtPath:path text:@"For God so loved the world" error:&error];
            require(search.count == 1 && [search[0].book isEqualToString:@"John"] && search[0].chapter == 3 && search[0].number == 16, "Database search missed John 3:16.");
            search = [BibleBridge searchAtPath:path text:@"zzzz-no-matching-scripture-zzzz" error:&error];
            require(search.count == 0 && error == nil, "Empty search should succeed.");
            NSString *fixture = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@".db"]];
            sqlite3 *fixtureDB = nullptr;
            require(sqlite3_open(fixture.fileSystemRepresentation, &fixtureDB) == SQLITE_OK, "Cannot create formatting fixture.");
            require(sqlite3_exec(fixtureDB, "CREATE TABLE Bible (Book INT, Chapter INT, Verse INT, Scripture TEXT); INSERT INTO Bible VALUES (43, 1, 1, '<red>red <i>both</i> red</red> plain <i>italic</i>');", nullptr, nullptr, nullptr) == SQLITE_OK, "Cannot populate formatting fixture.");
            sqlite3_close(fixtureDB);
            NSArray<BibleVerse *> *formatted = [BibleBridge versesAtPath:fixture book:@"John" chapter:1 firstVerse:1 limit:1 error:&error];
            require([formatted[0].text isEqualToString:@"red both red plain italic"], "Nested markup leaked into text.");
            require(formatted[0].pieces[1].red && formatted[0].pieces[1].italic, "Overlapping styles lost.");
            require(!formatted[0].pieces.lastObject.red && formatted[0].pieces.lastObject.italic, "Styles leaked past closing tag.");
            [[NSFileManager defaultManager] removeItemAtPath:fixture error:nil];
            BibleBackend backend(path.fileSystemRepresentation);
            for (int i = 0; i < 100; ++i) {
                backend.getChapter("John", 1, 3, 2);
                require(backend.lastError().empty() && backend.verses().size() == 2, "Repeated query failed.");
                require(backend.verses()[0].verse == 3 && backend.verses()[1].verse == 4, "Verse range ignored.");
                backend.searchBibleText("shepherd");
                require(backend.lastError().empty() && !backend.verses().empty(), "Search failed.");
            }
            backend.getChapter("Unknown", 1, 1);
            require(backend.verses().empty(), "Empty query retained stale results.");
            require([john[0].text hasPrefix:@"In the beginning"], "Bridge results did not survive backend destruction.");
            require([BibleBridge versesAtPath:path book:@"John" chapter:999 firstVerse:1 limit:5 error:&error] == nil && error != nil, "Missing passage error absent.");
            error = nil;
            require([BibleBridge versesAtPath:[path stringByAppendingString:@".missing"] book:@"John" chapter:1 firstVerse:1 limit:5 error:&error] == nil && error != nil, "Missing database error absent.");
            std::cout << "Bible core and Swift bridge integration checks passed.\n";
            return 0;
        } catch (const std::exception &error) {
            std::cerr << error.what() << '\n';
            return 1;
        }
    }
}
