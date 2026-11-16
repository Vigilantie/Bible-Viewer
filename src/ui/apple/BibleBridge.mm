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

#import "BibleBridge.h"
#include "bible.hpp"
#include "highlight.hpp"
#include "util.hpp"
#include <stdexcept>

@implementation BibleTextPiece
- (instancetype)initWithPiece:(const FormattedPiece &)piece {
    self = [super init];
    if (self) {
        _text = [[NSString alloc] initWithBytes:piece.value.data() length:piece.value.size() encoding:NSUTF8StringEncoding];
        _red = piece.isRed;
        _italic = piece.isItalic;
    }
    return self;
}
@end

@implementation BibleVerse
- (instancetype)initWithVerse:(const Bible &)verse {
    self = [super init];
    if (self) {
        _number = verse.verse;
        _chapter = verse.chapter;
        _book = [NSString stringWithUTF8String:verse.book.c_str()];
        std::string text;
        NSMutableArray *pieces = [NSMutableArray array];
        for (const auto &piece : verse.formated_pieces) {
            text += piece.value;
            [pieces addObject:[[BibleTextPiece alloc] initWithPiece:piece]];
        }
        _pieces = [pieces copy];
        _text = [[NSString alloc] initWithBytes:text.data()
                                       length:text.size()
                                     encoding:NSUTF8StringEncoding];
        if (!_text) throw std::runtime_error("The Bible contains invalid UTF-8 text.");
    }
    return self;
}
@end

@implementation BibleBridge
+ (NSArray<NSDictionary *> *)highlightsAtPath:(NSString *)path error:(NSError **)error {
    HighlightDB db(path.fileSystemRepresentation);
    if (db.lastError().empty()) {
        auto highlights = db.listAll();
        if (db.lastError().empty()) {
            NSMutableArray *result = [NSMutableArray array];
            for (const auto &h : highlights) [result addObject:@{@"book": [NSString stringWithUTF8String:h.book.c_str()], @"chapter": @(h.chapter), @"verse": @(h.verse), @"start": @(h.start_index), @"end": @(h.end_index), @"color": @(static_cast<int>(h.color))}];
            return result;
        }
    }
    if (error) *error = [NSError errorWithDomain:@"BibleHighlights" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:db.lastError().c_str()]}];
    return nil;
}
+ (BOOL)writeHighlightAtPath:(NSString *)path book:(NSString *)book chapter:(NSInteger)chapter verse:(NSInteger)verse start:(NSInteger)start end:(NSInteger)end color:(NSInteger)color remove:(BOOL)remove error:(NSError **)error {
    HighlightDB db(path.fileSystemRepresentation);
    if (db.lastError().empty()) {
        Highlight h{book.UTF8String, (int)chapter, (int)verse, (int)start, (int)end, static_cast<HighlightColors>(color)};
        if (remove) db.remove(h); else db.save(h);
    }
    if (db.lastError().empty()) return YES;
    if (error) *error = [NSError errorWithDomain:@"BibleHighlights" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:db.lastError().c_str()]}];
    return NO;
}

+ (NSArray<NSString *> *)bookNames {
    NSMutableArray *names = [NSMutableArray array];
    for (int i = 1; i <= 66; ++i) [names addObject:[NSString stringWithUTF8String:indexToBook(i).c_str()]];
    return names;
}
+ (NSString *)canonicalBook:(NSString *)book {
    return [NSString stringWithUTF8String:indexToBook(bookToIndex(book.UTF8String)).c_str()];
}
+ (NSDictionary<NSString *, NSNumber *> *)booksAtPath:(NSString *)path error:(NSError **)error {
    BibleBackend backend(path.fileSystemRepresentation);
    if (backend.lastError().empty()) {
        const auto books = backend.books();
        if (backend.lastError().empty()) {
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            for (const auto &book : books) result[[NSString stringWithUTF8String:book.first.c_str()]] = @(book.second);
            return result;
        }
    }
    if (error) *error = [NSError errorWithDomain:@"BibleCore" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:backend.lastError().c_str()]}];
    return nil;
}
+ (NSArray<BibleVerse *> *)searchAtPath:(NSString *)path text:(NSString *)text error:(NSError **)error {
    BibleBackend backend(path.fileSystemRepresentation);
    if (backend.lastError().empty()) {
        backend.searchBibleText(text.UTF8String);
        if (backend.lastError().empty()) {
            NSMutableArray *result = [NSMutableArray array];
            for (const auto &verse : backend.verses()) [result addObject:[[BibleVerse alloc] initWithVerse:verse]];
            return result;
        }
    }
    if (error) *error = [NSError errorWithDomain:@"BibleCore" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:backend.lastError().c_str()]}];
    return nil;
}
+ (NSArray<BibleVerse *> *)versesAtPath:(NSString *)path
                                  book:(NSString *)book
                               chapter:(NSInteger)chapter
                            firstVerse:(NSInteger)firstVerse
                                 limit:(NSInteger)limit
                                 error:(NSError **)error {
    try {
        BibleBackend backend(path.fileSystemRepresentation);
        if (!backend.lastError().empty()) throw std::runtime_error(backend.lastError());
        backend.getChapter(book.UTF8String, (int)chapter, (int)firstVerse, (int)limit);
        if (!backend.lastError().empty()) throw std::runtime_error(backend.lastError());
        if (backend.verses().empty()) throw std::runtime_error("The requested passage is missing from the Bible database.");
        NSMutableArray<BibleVerse *> *verses = [NSMutableArray array];
        for (const auto &verse : backend.verses()) {
            [verses addObject:[[BibleVerse alloc] initWithVerse:verse]];
        }
        return verses;
    } catch (const std::exception &exception) {
        if (error) {
            *error = [NSError errorWithDomain:@"BibleCore" code:1 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithUTF8String:exception.what()]
            }];
        }
        return nil;
    }
}
@end
