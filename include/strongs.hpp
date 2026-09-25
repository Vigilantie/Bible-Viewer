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

enum StrongsPieceType
{
  TEXT,
  ITALIC,
  BOLD,
  HEB,
  LAT,
};

struct StrongsFormatedPiece
{
  std::string value;
  StrongsPieceType type;
  bool isBold = false;
  bool isItalic = false;
};

struct Strongs
{
  int strong;
  bool isHeb = true;
  bool isGreek = false;
  std::vector<StrongsFormatedPiece> formated_piece;
};

class StrongsBackend
{
public:
  StrongsBackend(std::string db_path);
  ~StrongsBackend();
  void getStrong(std::string strong, int type);
  void compileStrongs(std::string strong, std::string strong_text);
private:
  Strongs strongs;
  std::vector<StrongsFormatedPiece> formatStrongs(std::string raw_strongs);
  sqlite3 *db = nullptr;
  sqlite3_stmt *stmt = nullptr;
  int count = 0;
  std::string error;
};
