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

#pragma once

#include <string>
#include <vector>

#include <sqlite3.h>

enum HighlightColors
{
  RED,
  ORANGE,
  YELLOW,
  GREEN,
  BLUE,
  VIOLET,
  INDIGO,
  GRAY,
  BLACK,
};

struct Highlight
{
  std::string book;
  int chapter;
  int verse;
  int start_index;
  int end_index;
  HighlightColors color;
};

class HighlightDB
{
public:
  HighlightDB(std::string db_path);
  ~HighlightDB();

  // Use when loading the chapter
  void load(const Highlight &highlight);
  void save(const Highlight &highlight);
  void remove(const Highlight &highlight);

  // Searching
  std::vector<Highlight> listAll();
  std::vector<Highlight> sortByColor(HighlightColors color);

private:
  Highlight highlight;
  sqlite3_stmt *stmt = nullptr;
  sqlite3 *db = nullptr;
  int count = 0;
  std::string error;
};
