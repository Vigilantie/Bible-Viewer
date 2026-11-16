#pragma once

#include <string>

struct Notes
{
  std::string book;
  int chapter;
  std::string note;
};

class NoteDB
{
public:
  NoteDB(const std::string &db_path);
  ~NoteDB();
  void load(const std::string &book);
  void save(const std::string &note);

private:
  sqlite3 *db = nullptr;
  sqlite3_stmt *stmt = nullptr;
};