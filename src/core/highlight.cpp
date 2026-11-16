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

#include "highlight.hpp"
#include <algorithm>

HighlightDB::HighlightDB(std::string path)
{
  if (sqlite3_open(path.c_str(), &db) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }
  const char *sql = "CREATE TABLE IF NOT EXISTS Highlights (id INTEGER PRIMARY KEY, book TEXT NOT NULL, chapter INTEGER NOT NULL, verse INTEGER NOT NULL, start_index INTEGER NOT NULL, end_index INTEGER NOT NULL, color INTEGER NOT NULL);";
  if (sqlite3_exec(db, sql, nullptr, nullptr, nullptr) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
  }
}

HighlightDB::~HighlightDB()
{
  sqlite3_finalize(stmt); sqlite3_close(db);
}

static void bindHighlight(sqlite3_stmt *stmt, const Highlight &h)
{
  sqlite3_bind_text(stmt, 1, h.book.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int(stmt, 2, h.chapter);
  sqlite3_bind_int(stmt, 3, h.verse);
  sqlite3_bind_int(stmt, 4, h.start_index);
  sqlite3_bind_int(stmt, 5, h.end_index);
  sqlite3_bind_int(stmt, 6, static_cast<int>(h.color));
}

void HighlightDB::save(const Highlight &h)
{
  error.clear();
  if (h.book.empty() || h.chapter < 1 || h.verse < 1 || h.start_index < 0 || h.end_index <= h.start_index || static_cast<int>(h.color) < 0 || static_cast<int>(h.color) > 8)
  {
    error = "Invalid highlight range or color."; return;
  }
  const char *sql = "INSERT INTO Highlights (book, chapter, verse, start_index, end_index, color) SELECT ?, ?, ?, ?, ?, ? WHERE NOT EXISTS (SELECT 1 FROM Highlights WHERE book=?1 AND chapter=?2 AND verse=?3 AND start_index=?4 AND end_index=?5 AND color=?6);";
  if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
  {
    bindHighlight(stmt, h);
    if (sqlite3_step(stmt) != SQLITE_DONE)
    {
      error = sqlite3_errmsg(db);
    }
  }
  else 
  {
    error = sqlite3_errmsg(db);
  }
  sqlite3_finalize(stmt); stmt = nullptr;
}

void HighlightDB::remove(const Highlight &h)
{
  error.clear();
  const char *sql = "DELETE FROM Highlights WHERE book=? AND chapter=? AND verse=? AND start_index=? AND end_index=? AND color=?;";
  if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
  {
    bindHighlight(stmt, h);
    if (sqlite3_step(stmt) != SQLITE_DONE) error = sqlite3_errmsg(db);
  }
  else
  {
    error = sqlite3_errmsg(db);
  }
  sqlite3_finalize(stmt); stmt = nullptr;
}

std::vector<Highlight> HighlightDB::listAll()
{
  error.clear();
  std::vector<Highlight> result;
  const char *sql = "SELECT book, chapter, verse, start_index, end_index, color FROM Highlights ORDER BY id;";
  if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
  {
    int status;
    while ((status = sqlite3_step(stmt)) == SQLITE_ROW)
    {
      result.push_back({reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0)), sqlite3_column_int(stmt, 1), sqlite3_column_int(stmt, 2), sqlite3_column_int(stmt, 3), sqlite3_column_int(stmt, 4), static_cast<HighlightColors>(sqlite3_column_int(stmt, 5))});
    }
    if (status != SQLITE_DONE)
    {
      error = sqlite3_errmsg(db); result.clear();
    }
  }
  else
  {
    error = sqlite3_errmsg(db);
  }
  sqlite3_finalize(stmt); stmt = nullptr;
  return result;
}

std::vector<Highlight> HighlightDB::sortByColor(HighlightColors color)
{
  auto result = listAll();
  result.erase(std::remove_if(result.begin(), result.end(), [color](const Highlight &h) { return h.color != color; }), result.end());
  return result;
}

void HighlightDB::load(const Highlight &h)
{
  auto all = listAll();
  count = 0;
  for (const auto &value : all)
  {
    if (value.book == h.book && value.chapter == h.chapter && value.verse == h.verse && value.start_index == h.start_index && value.end_index == h.end_index && value.color == h.color)
    {
      highlight = value; ++count;
    }
  }
}
