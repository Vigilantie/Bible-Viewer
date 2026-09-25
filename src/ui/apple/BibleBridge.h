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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BibleTextPiece : NSObject
@property(nonatomic, copy, readonly) NSString *text;
@property(nonatomic, readonly) BOOL red;
@property(nonatomic, readonly) BOOL italic;
@end

@interface BibleVerse : NSObject
@property(nonatomic, copy, readonly) NSArray<BibleTextPiece *> *pieces;
@property(nonatomic, readonly) NSInteger number;
@property(nonatomic, readonly) NSInteger chapter;
@property(nonatomic, copy, readonly) NSString *book;
@property(nonatomic, copy, readonly) NSString *text;
@end

/// Copies bible_core results into values owned by Swift/Foundation.
@interface BibleBridge : NSObject
+ (nullable NSDictionary<NSString *, NSNumber *> *)booksAtPath:(NSString *)path error:(NSError **)error;
+ (NSArray<NSString *> *)bookNames;
+ (NSString *)canonicalBook:(NSString *)book;
+ (nullable NSArray<BibleVerse *> *)searchAtPath:(NSString *)path text:(NSString *)text error:(NSError **)error;
+ (nullable NSArray<BibleVerse *> *)versesAtPath:(NSString *)path
                                          book:(NSString *)book
                                       chapter:(NSInteger)chapter
                                    firstVerse:(NSInteger)firstVerse
                                         limit:(NSInteger)limit
                                         error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
