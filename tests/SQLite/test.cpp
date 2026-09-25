#include <sqlite3.h>

#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>

#include "../../src/search.hpp"

int main()
{
  sqlite3 *db = NULL;
  if (sqlite3_open("../../assets/Bible/Translations/kjv.db", &db) != SQLITE_OK)
  {
    fprintf(stderr, "Can't open DB: %s\n", sqlite3_errmsg(db));
    return 1;
  }

  const char *sql =
    "SELECT Book, Chapter, Verse, Scripture "
    "FROM Bible "
    "WHERE Scripture LIKE '%' || ? || '%';"
  ;

  sqlite3_stmt *stmt = NULL;

  if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK) {
    printf("Prepare failed: %s\n", sqlite3_errmsg(db));
  }

  std::string search;
  bool running = true;
  while (running)
  {
    std::cout << "Search: ";
    std::cin >> search;

    // Bind the new search string
    sqlite3_bind_text(stmt, 1, search.c_str(), -1, SQLITE_TRANSIENT);

    // Read all matching rows
    while (sqlite3_step(stmt) == SQLITE_ROW) {
      int book = sqlite3_column_int(stmt, 0);
      int chapter = sqlite3_column_int(stmt, 1);
      int verse = sqlite3_column_int(stmt, 2);

      const char *scripture = (const char *)sqlite3_column_text(stmt, 3);

      printf("%d:%d:%d %s\n", book, chapter, verse, scripture);
    }

    // Get ready to execute the statement again
    sqlite3_reset(stmt);

    // Remove the previous bindings
    sqlite3_clear_bindings(stmt);
  }

  sqlite3_finalize(stmt);

  sqlite3_close(db);
  return 0;
}
