set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(bible_core STATIC
  "bible.cpp"
  "highlight.cpp"
  "util.cpp"
  "${CMAKE_SOURCE_DIR}/external/sqlite/sqlite3.c"
)

target_include_directories(bible_core PUBLIC
  "${CMAKE_SOURCE_DIR}/include"
  "${CMAKE_SOURCE_DIR}/external/sqlite"
)
