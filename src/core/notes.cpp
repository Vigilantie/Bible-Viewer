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

#include <notes.hpp>
#include <util.hpp>

NotesDB::NotesDB(const std::string &db_path)
{
  if (sqlite3_open_v2(db_path.c_str(), &db, SQLITE_OPEN_READONLY, nullptr) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }
}

NotesDB::~NotesDB()
{
  sqlite3_finalize(stmt);
  sqlite3_close(db);
}

bool NotesDB::save(const Notes &note)
{
  sqlite3_finalize(stmt);
  stmt = nullptr;

  const char *sql =
    "INSERT INTO Highlights "
    "(book, chapter, note) "
    "VALUES (?, ?, ?);"
  ;

  int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);

  if (rc != SQLITE_OK)
  {
    fprintf(stderr, "Prepare failed: %s\n", sqlite3_errmsg(db));
    return false;
  }

  sqlite3_bind_text(stmt, 1, note.book.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int(stmt, 2, note.chapter);
  sqlite3_bind_text(stmt, 3, note.note.c_str(), -1, SQLITE_TRANSIENT);

  rc = sqlite3_step(stmt);

  if (rc != SQLITE_DONE)
  {
    fprintf(stderr, "Insert failed: %s\n", sqlite3_errmsg(db));
    return false;
  }

  sqlite3_finalize(stmt);
  stmt = nullptr;

  return true;
}

bool NotesDB::load(const Notes &note)
{
  count = 0;
  sqlite3_finalize(stmt);
  stmt = nullptr;

  const char *sql =
    "SELECT * FROM Notes"
    "WHERE book = ? "
    "AND chapter = ?;"
  ;

  if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }

  int count_local = 0;
  sqlite3_bind_text(stmt, 1, highlight.book.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int(stmt, 2, highlight.chapter);

  // Read all matching rows
  int result;
  while ((result = sqlite3_step(stmt)) == SQLITE_ROW)
  {
    const char *book = (const char *)sqlite3_column_text(stmt, 0);
    int chapter = (int)sqlite3_column_int(stmt, 1);
    int verse = (int)sqlite3_column_int(stmt, 2);
    int start_index = (int)sqlite3_column_int(stmt, 3);
    int end_index = (int)sqlite3_column_int(stmt, 4);
    int color = (int)sqlite3_column_int(stmt, 5);

    count_local++;
  }
  count = count_local;

  if (result != SQLITE_DONE)
  {
    error = sqlite3_errmsg(db);
    count = 0;
  }
  sqlite3_finalize(stmt);
  stmt = nullptr;

  return true;
}

std::vector<std::pair<std::string, int>> NotesDB::notes()
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

void NotesDB::searchNotesText(const std::string &search)
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
