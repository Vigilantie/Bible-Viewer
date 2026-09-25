/*
 Bible Viewer - Scripture, At Your Fingertips.
 Copyright (C) 2026  Jacob T. Ward

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#include "../src/parse.hpp"
#include <iostream>

int main()
{
  const Book acts = parse_bible_file("acts.json");
  const Chapter *chapter = find_chapter(acts, 1);
  if (acts.name != "Acts" || acts.chapterCount != 28 || chapter == nullptr)
    return 1;

  const Verse *verse = find_verse(*chapter, 1);
  if (verse == nullptr || verse->text.empty())
    return 2;

  std::cout << acts.name << ' ' << acts.chapterCount << ' ' << verse->text << '\n';
}
