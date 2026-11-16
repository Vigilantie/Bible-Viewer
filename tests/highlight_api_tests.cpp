#include "highlight.hpp"
#include <cassert>
#include <cstdio>
int main(int argc, char **argv) {
  assert(argc == 2);
  const std::string path = argv[1];
  Highlight h{"John", 3, 16, 0, 12, HighlightColors::YELLOW};
  {
    HighlightDB db(path);
    assert(db.lastError().empty());
    db.save(h); db.save(h);
    assert(db.lastError().empty() && db.listAll().size() == 1);
    assert(db.sortByColor(HighlightColors::YELLOW).size() == 1);
    assert(db.sortByColor(HighlightColors::BLUE).empty());
  }
  {
    HighlightDB db(path);
    assert(db.listAll().size() == 1);
    db.load(h); assert(db.lastError().empty());
    db.remove(h);
    assert(db.lastError().empty() && db.listAll().empty());
    h.end_index = -1; db.save(h); assert(!db.lastError().empty());
  }
  HighlightDB missing(path + "/invalid/file.db");
  assert(!missing.lastError().empty());
  std::remove(path.c_str());
}
