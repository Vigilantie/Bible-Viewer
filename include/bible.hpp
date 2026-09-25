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

enum PieceType
{
  TEXT,
  ITALIC,
  BOLD,
  RED,
  HEB,
  LAT
};

struct FormattedPiece
{
  std::string value;
  PieceType type;
  bool isRed = false;
  bool isItalic = false;
};

struct Bible
{
  std::string book;
  int chapter;
  int verse;
  std::vector<FormattedPiece> formated_pieces;
};

class BibleBackend
{
public:
  BibleBackend(std::string db_path);
  ~BibleBackend();
  BibleBackend(const BibleBackend&) = delete;
  BibleBackend& operator=(const BibleBackend&) = delete;
  const std::vector<Bible>& verses() const { return bible; }
  const std::string& lastError() const { return error; }
  std::vector<std::pair<std::string, int>> books();
  void searchBibleText(std::string search);
  void getChapter(std::string book, int chapter, int verse, int limit = -1);
  void printBibleToConsole();

private:
  std::vector<Bible> bible;
  sqlite3 *db = nullptr;
  sqlite3_stmt *stmt = nullptr;
  void compileVerse(int book, int chapter, int verse, std::string scripture);
  std::vector<FormattedPiece> formatScripture(std::string scripture);
  void flushText(std::vector<FormattedPiece> &pieces, std::vector<std::string> &tags, std::string &text);
  int count = 0;
  std::string error;
};
