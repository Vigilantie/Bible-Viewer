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

#include <string>
#include <vector>

#include <sqlite3.h>

#include <bible.hpp>
#include <util.hpp>

BibleBackend::BibleBackend(std::string db_path)
{
  if (sqlite3_open_v2(db_path.c_str(), &db, SQLITE_OPEN_READONLY, nullptr) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }
}

BibleBackend::~BibleBackend()
{
  sqlite3_finalize(stmt);
  sqlite3_close(db);
}

std::vector<std::pair<std::string, int>> BibleBackend::books()
{
  error.clear();
  sqlite3_stmt *catalog = nullptr;
  std::vector<std::pair<std::string, int>> result;

  if (sqlite3_prepare_v2(db, "SELECT Book, MAX(Chapter) FROM Bible GROUP BY Book ORDER BY Book", -1, &catalog, nullptr) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return result;
  }

  int status;
  while ((status = sqlite3_step(catalog)) == SQLITE_ROW)
  {
    result.emplace_back(indexToBook(sqlite3_column_int(catalog, 0)), sqlite3_column_int(catalog, 1));
  }

  if (status != SQLITE_DONE)
  {
    error = sqlite3_errmsg(db); result.clear();
  }

  sqlite3_finalize(catalog);
  return result;
}

void BibleBackend::searchBibleText(std::string search)
{
  bible.clear();
  count = 0;
  error.clear();
  sqlite3_finalize(stmt);
  stmt = nullptr;

  const char *search_bible_sql =
    "SELECT Book, Chapter, Verse, Scripture "
    "FROM Bible "
    "WHERE Scripture LIKE '%' || ? || '%' ORDER BY Book, Chapter, Verse;"
  ;

  if (sqlite3_prepare_v2(db, search_bible_sql, -1, &stmt, NULL) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }

  int count_local = 0;
  sqlite3_bind_text(stmt, 1, search.c_str(), -1, SQLITE_TRANSIENT);

  // Read all matching rows
  int result;
  while ((result = sqlite3_step(stmt)) == SQLITE_ROW)
  {
    int book = sqlite3_column_int(stmt, 0);
    int chapter = sqlite3_column_int(stmt, 1);
    int verse = sqlite3_column_int(stmt, 2);
    const char *scripture = (const char *)sqlite3_column_text(stmt, 3);

    compileVerse(book, chapter, verse, scripture ? scripture : "");

    count_local++;
  }
  count = count_local;

  if (result != SQLITE_DONE)
  {
    error = sqlite3_errmsg(db);
    bible.clear();
    count = 0;
  }
  sqlite3_finalize(stmt);
  stmt = nullptr;
}

void BibleBackend::getChapter(std::string book, int chapter, int verse, int limit)
{
  bible.clear();
  count = 0;
  error.clear();
  sqlite3_finalize(stmt);
  stmt = nullptr;

  const char *get_chapter_sql =
    "SELECT Book, Chapter, Verse, Scripture FROM Bible "
    "WHERE Book = ? "
    "AND Chapter = ? AND Verse >= ? "
    "ORDER BY Verse "
    "LIMIT ?;"
  ;

  if (sqlite3_prepare_v2(db, get_chapter_sql, -1, &stmt, NULL) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }

  int count_local = 0;
  int book_index = bookToIndex(book);
  sqlite3_bind_int(stmt, 1, book_index);
  sqlite3_bind_int(stmt, 2, chapter);
  sqlite3_bind_int(stmt, 3, verse);
  sqlite3_bind_int(stmt, 4, limit);

  // Read all matching rows
  int result;
  while ((result = sqlite3_step(stmt)) == SQLITE_ROW)
  {
    int book = sqlite3_column_int(stmt, 0);
    int chapter = sqlite3_column_int(stmt, 1);
    int verse = sqlite3_column_int(stmt, 2);
    const char *scripture = (const char *)sqlite3_column_text(stmt, 3);

    compileVerse(book, chapter, verse, scripture ? scripture : "");

    count_local++;
  }
  count = count_local;

  if (result != SQLITE_DONE)
  {
    error = sqlite3_errmsg(db);
    bible.clear();
    count = 0;
  }

  sqlite3_finalize(stmt);
  stmt = nullptr;
}

void BibleBackend::compileVerse(int book, int chapter, int verse, std::string scripture)
{
  std::vector<FormattedPiece> scripture_pieces = formatScripture(scripture);
  std::string book_name = indexToBook(book);
  bible.push_back({.book = book_name, .chapter = chapter, .verse = verse, .formated_pieces = scripture_pieces});
}

void BibleBackend::flushText(std::vector<FormattedPiece> &pieces, std::vector<std::string> &tags, std::string &text)
{
  if (text.empty())
  {
    return;
  }

  bool red = false, italic = false;
  PieceType type = TEXT;

  for (const auto &tag : tags)
  {
    if (tag == "red")
    {
      red = true;
      type = RED;
    }
    else if (tag == "i")
    {
      italic = true;
      type = ITALIC;
    }
    else if (tag == "b")
    {
      type = BOLD;
    }
    else if (tag == "heb")
    {
      type = HEB;
    }
    else if (tag == "lat")
    {
      type = LAT;
    }
  }
  pieces.push_back({text, type, red, italic});
  text.clear();
}

std::vector<FormattedPiece> BibleBackend::formatScripture(std::string scripture)
{
  std::vector<FormattedPiece> pieces;
  std::vector<std::string> tags;
  std::string text;

  for (size_t i = 0; i < scripture.size();)
  {
    if (scripture[i] == '<')
    {
      auto end = scripture.find('>', i);
      if (end != std::string::npos)
      {
        std::string tag = scripture.substr(i + 1, end - i - 1);
        bool closing = !tag.empty() && tag[0] == '/';
        if (closing)
        {
          tag.erase(0, 1);
        }

        if (tag == "red" || tag == "i" || tag == "b" || tag == "p" || tag == "heb" || tag == "lat")
        {
          flushText(pieces, tags, text);
          if (closing)
          {
            for (auto it = tags.end(); it != tags.begin();)
            {
              --it;
              if (*it == tag)
              {
                tags.erase(it); break;
              }
            }
          }
          else
          {
            tags.push_back(tag);
          }

          i = end + 1;
          continue;
        }
      }
    }
    text += scripture[i++];
  }
  flushText(pieces, tags, text);
  return pieces;
}

void BibleBackend::printBibleToConsole()
{
  printf("%s %d\n", bible[0].book.c_str(), bible[0].chapter);
  for (int i = 0; i < bible.size(); i++)
  {
    printf("%d ", bible[i].verse);
    for (int j = 0; j < bible[i].formated_pieces.size(); j++)
    {
      printf("%s", bible[i].formated_pieces[j].value.c_str());
    }
    printf("\n");
  }
}
