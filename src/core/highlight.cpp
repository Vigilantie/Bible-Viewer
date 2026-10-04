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

#include <highlight.hpp>
#include <util.hpp>

HighlightDB::HighlightDB(std::string db_path)
{
  int rc = sqlite3_open(db_path.c_str(), &db);
  if (rc != SQLITE_OK)
  {
    fprintf(stderr, "Failed to open database: %s\n", sqlite3_errmsg(db));

    sqlite3_close(db);
    return;
  }

  const char *sql =
    "CREATE TABLE IF NOT EXISTS Highlights ("
    "id INTEGER PRIMARY KEY,"
    "book TEXT NOT NULL,"
    "chapter INTEGER NOT NULL,"
    "verse INTEGER NOT NULL,"
    "start_index INTEGER NOT NULL,"
    "end_index INTEGER NOT NULL,"
    "color INTEGER NOT NULL"
    ");"
  ;

  char *error = NULL;
  rc = sqlite3_exec(db, sql, NULL, NULL, &error);
  if (rc != SQLITE_OK)
  {
    fprintf(stderr, "SQL error: %s\n", error);
    sqlite3_free(error);
  }
}

HighlightDB::~HighlightDB()
{
  sqlite3_finalize(stmt);
  sqlite3_close(db);
}

void HighlightDB::save(const Highlight &highlight)
{
  sqlite3_finalize(stmt);
  stmt = nullptr;

  const char *sql =
    "INSERT INTO Highlights "
    "(book, chapter, verse, start_index, end_index, color) "
    "VALUES (?, ?, ?, ?, ?, ?);"
  ;

  int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);

  if (rc != SQLITE_OK)
  {
    fprintf(stderr, "Prepare failed: %s\n", sqlite3_errmsg(db));
  }

  sqlite3_bind_text(stmt, 1, highlight.book.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int(stmt, 2, highlight.chapter);
  sqlite3_bind_int(stmt, 3, highlight.verse);
  sqlite3_bind_int(stmt, 4, highlight.start_index);
  sqlite3_bind_int(stmt, 5, highlight.end_index);
  sqlite3_bind_int(stmt, 6, highlight.color);

  rc = sqlite3_step(stmt);

  if (rc != SQLITE_DONE)
  {
    fprintf(stderr, "Insert failed: %s\n", sqlite3_errmsg(db));
  }

  sqlite3_finalize(stmt);
  stmt = nullptr;
}

void HighlightDB::remove(const Highlight &highlight)
{
  sqlite3_finalize(stmt);
  stmt = nullptr;

  const char *sql =
    "DELETE FROM Highlights"
    "WHERE book = ? "
    "AND chapter = ? "
    "AND verse = ? "
    "AND start_index = ? "
    "AND end_index = ? "
    "AND color = ?;"
  ;

  int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);

  if (rc != SQLITE_OK)
  {
    fprintf(stderr, "Prepare failed: %s\n", sqlite3_errmsg(db));
  }

  sqlite3_bind_text(stmt, 1, highlight.book.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int(stmt, 2, highlight.chapter);
  sqlite3_bind_int(stmt, 3, highlight.verse);
  sqlite3_bind_int(stmt, 4, highlight.start_index);
  sqlite3_bind_int(stmt, 5, highlight.end_index);
  sqlite3_bind_int(stmt, 6, highlight.color);

  rc = sqlite3_step(stmt);

  if (rc != SQLITE_DONE)
  {
    fprintf(stderr, "Insert failed: %s\n", sqlite3_errmsg(db));
  }

  sqlite3_finalize(stmt);
  stmt = nullptr;
}

void HighlightDB::load(const Highlight &highlight)
{
  count = 0;
  sqlite3_finalize(stmt);
  stmt = nullptr;

  const char *sql =
    "SELECT * FROM Highlights"
    "WHERE book = ? "
    "AND chapter = ? "
    "AND verse = ? "
    "AND start_index = ? "
    "AND end_index = ? "
    "AND color = ?;"
  ;

  if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }

  int count_local = 0;
  sqlite3_bind_text(stmt, 1, highlight.book.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int(stmt, 2, highlight.chapter);
  sqlite3_bind_int(stmt, 3, highlight.verse);
  sqlite3_bind_int(stmt, 4, highlight.start_index);
  sqlite3_bind_int(stmt, 5, highlight.end_index);
  sqlite3_bind_int(stmt, 6, highlight.color);

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
}
