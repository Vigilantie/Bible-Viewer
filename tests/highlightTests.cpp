#include "../include/highlight.hpp"

int main()
{
  HighlightDB highlightdb("highlightTest.db");
  Highlight highlight{"Genisis", 1, 1, 1, 8, HighlightColors::BLUE};
  highlightdb.save(highlight);
  highlight = {"Exidous", 1, 3, 4, 9, HighlightColors::GREEN};
  highlightdb.save(highlight);
  highlight = {"Leviticus", 12, 9, 3, 10, HighlightColors::RED};
  highlightdb.save(highlight);
  highlight = {"Leviticus", 12, 9, 3, 10, HighlightColors::RED};
  highlightdb.save(highlight);

  return 0;
}
