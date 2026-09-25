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

#include <string>
#include <vector>

#include <util.hpp>

std::string lowerCase(std::string str)
{
  std::string temp;
  for (int i = 0; i < str.size(); i++)
  {
    temp += std::tolower(static_cast<unsigned char>(str[i]));
  }

  return temp;
}

int bookToIndex(std::string book)
{
  book = lowerCase(book);

  if (book == "genesis" || book == "gen")
  {
    return 1;
  }
  else if (book == "exodus" || book == "exo")
  {
    return 2;
  }
  else if (book == "leviticus" || book == "lev")
  {
    return 3;
  }
  else if (book == "numbers" || book == "num")
  {
    return 4;
  }
  else if (book == "deuteronomy" || book == "deut")
  {
    return 5;
  }
  else if (book == "joshua" || book == "josh")
  {
    return 6;
  }
  else if (book == "judges" || book == "judg")
  {
    return 7;
  }
  else if (book == "ruth" || book == "rut")
  {
    return 8;
  }
  else if (book == "1 samuel" || book == "1samuel" || book == "1 sam")
  {
    return 9;
  }
  else if (book == "2 samuel" || book == "2samuel" || book == "2 sam")
  {
    return 10;
  }
  else if (book == "1 kings" || book == "1kings" || book == "1 kgs")
  {
    return 11;
  }
  else if (book == "2 kings" || book == "2kings" || book == "2 kgs")
  {
    return 12;
  }
  else if (book == "1 chronicles" || book == "1chronicles" || book == "1 chr")
  {
    return 13;
  }
  else if (book == "2 chronicles" || book == "2chronicles" || book == "2 chr")
  {
    return 14;
  }
  else if (book == "ezra" || book == "ezr")
  {
    return 15;
  }
  else if (book == "nehemiah" || book == "neh")
  {
    return 16;
  }
  else if (book == "esther" || book == "est")
  {
    return 17;
  }
  else if (book == "job" || book == "job")
  {
    return 18;
  }
  else if (book == "psalms" || book == "psalm" || book == "ps")
  {
    return 19;
  }
  else if (book == "proverbs" || book == "prov")
  {
    return 20;
  }
  else if (book == "ecclesiastes" || book == "eccl")
  {
    return 21;
  }
  else if (book == "song of solomon" || book == "song" || book == "sol" || book == "solomon")
  {
    return 22;
  }
  else if (book == "isaiah" || book == "isa")
  {
    return 23;
  }
  else if (book == "jeremiah" || book == "jer")
  {
    return 24;
  }
  else if (book == "lamentations" || book == "lam")
  {
    return 25;
  }
  else if (book == "ezekiel" || book == "ezek")
  {
    return 26;
  }
  else if (book == "daniel" || book == "dan")
  {
    return 27;
  }
  else if (book == "hosea" || book == "hos")
  {
    return 28;
  }
  else if (book == "joel" || book == "joel")
  {
    return 29;
  }
  else if (book == "amos" || book == "amos")
  {
    return 30;
  }
  else if (book == "obadiah" || book == "obad")
  {
    return 31;
  }
  else if (book == "jonah" || book == "jon")
  {
    return 32;
  }
  else if (book == "micah" || book == "mic")
  {
    return 33;
  }
  else if (book == "nahum" || book == "nah")
  {
    return 34;
  }
  else if (book == "habakkuk" || book == "hab")
  {
    return 35;
  }
  else if (book == "zephaniah" || book == "zeph")
  {
    return 36;
  }
  else if (book == "haggai" || book == "hag")
  {
    return 37;
  }
  else if (book == "zechariah" || book == "zech")
  {
    return 38;
  }
  else if (book == "malachi" || book == "mal")
  {
    return 39;
  }
  else if (book == "matthew" || book == "matt")
  {
    return 40;
  }
  else if (book == "mark" || book == "mk")
  {
    return 41;
  }
  else if (book == "luke" || book == "lk")
  {
    return 42;
  }
  else if (book == "john" || book == "jn")
  {
    return 43;
  }
  else if (book == "acts" || book == "act")
  {
    return 44;
  }
  else if (book == "romans" || book == "rom")
  {
    return 45;
  }
  else if (book == "1 corinthians" || book == "1corinthians" || book == "1 cor")
  {
    return 46;
  }
  else if (book == "2 corinthians" || book == "2corinthians" || book == "2 cor")
  {
    return 47;
  }
  else if (book == "galatians" || book == "gal")
  {
    return 48;
  }
  else if (book == "ephesians" || book == "eph")
  {
    return 49;
  }
  else if (book == "philippians" || book == "phil")
  {
    return 50;
  }
  else if (book == "colossians" || book == "col")
  {
    return 51;
  }
  else if (book == "1 thessalonians" || book == "1thessalonians" ||
           book == "1 thess")
  {
    return 52;
  }
  else if (book == "2 thessalonians" || book == "2thessalonians" || book == "2 thess")
  {
    return 53;
  }
  else if (book == "1 timothy" || book == "1timothy" || book == "1 tim")
  {
    return 54;
  }
  else if (book == "2 timothy" || book == "2timothy" || book == "2 tim")
  {
    return 55;
  }
  else if (book == "titus" || book == "tit")
  {
    return 56;
  }
  else if (book == "philemon" || book == "phlm")
  {
    return 57;
  }
  else if (book == "hebrews" || book == "heb")
  {
    return 58;
  }
  else if (book == "james" || book == "jas")
  {
    return 59;
  }
  else if (book == "1 peter" || book == "1peter" || book == "1 pet")
  {
    return 60;
  }
  else if (book == "2 peter" || book == "2peter" || book == "2 pet")
  {
    return 61;
  }
  else if (book == "1 john" || book == "1john" || book == "1 jn")
  {
    return 62;
  }
  else if (book == "2 john" || book == "2john" || book == "2 jn")
  {
    return 63;
  }
  else if (book == "3 john" || book == "3john" || book == "3 jn")
  {
    return 64;
  }
  else if (book == "jude" || book == "jud")
  {
    return 65;
  }
  else if (book == "revelation" || book == "rev")
  {
    return 66;
  }

  return 0;
}

std::string indexToBook(int index)
{
  static const char* books[] =
  {
    "",
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
    "Joshua", "Judges", "Ruth",
    "1 Samuel", "2 Samuel", "1 Kings", "2 Kings",
    "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah", "Esther",
    "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon",
    "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel",
    "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah", "Nahum",
    "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi",
    "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
    "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
    "Philippians", "Colossians",
    "1 Thessalonians", "2 Thessalonians",
    "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews",
    "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
    "Jude", "Revelation"
  };

  if (index < 1 || index > 66)
  {
    return "";
  }

  return books[index];
}
