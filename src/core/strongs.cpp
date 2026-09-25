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

#include <strongs.hpp>

#include <sqlite3.h>

StrongsBackend::StrongsBackend(std::string db_path)
{
  if (sqlite3_open_v2(db_path.c_str(), &db, SQLITE_OPEN_READONLY, nullptr) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }
}

StrongsBackend::~StrongsBackend()
{
  sqlite3_finalize(stmt);
  sqlite3_close(db);
}

StrongsBackend::compileStrongs(int strong, std::string strong_text, bool isHeb, bool isGreek)
{
  std::vector<StrongsFormattedPiece> formated_piece = formatStrongs(std::string strong_text);
  strongs.strong = strong;
  strong.isGreek = isGreek;
  strong.isHeb = isHeb;
  strong.formated_piece = formated_piece;
}

void StrongsBackend::getStrong(std::string strong, int type)
{
	strongs.clear();
  count = 0;
  sqlite3_finalize(stmt);
  stmt = nullptr;

  const char *get_chapter_sql =
    "SELECT Definition FROM Lexicon"
    "WHERE Topic = ?;"
  ;

  if (sqlite3_prepare_v2(db, get_chapter_sql, -1, &stmt, NULL) != SQLITE_OK)
  {
    error = sqlite3_errmsg(db);
    return;
  }

  int count_local = 0;
  sqlite3_bind_text(stmt, 1, strong.c_str(), -1, SQLITE_TRANSIENT);

  // Read all matching rows
  int result;
  while ((result = sqlite3_step(stmt)) == SQLITE_ROW)
  {
    const char *scripture = (const char *)sqlite3_column_text(stmt, 0);

    // compileStrongs(strong, scripture ? scripture : "");
    // compileVerse(book, chapter, verse, scripture ? scripture : "");

    count_local++;
  }
  count = count_local;

  if (result != SQLITE_DONE)
  {
    error = sqlite3_errmsg(db);
    strongs.clear();
    count = 0;
  }
  sqlite3_finalize(stmt);
  stmt = nullptr;
}
