# Bible Core
## Intro
Bible Core is the core library for the Bible Viewer. You can use this library to make you own applications.

To do this, simply include the include directory in the project root, and link the library to your program. If you are using CMake it will look something like this.

## Linking
```CMake
cmake_minimum_required(VERSION 4.0.1)
project(my_project)
add_subdirectory("external/Bible_Viewer")
target_include_directories(${PROJECT_NAME} PUBLIC "external/Bible_Viewer/include")
target_link_libraries(${PROJECT_NAME} PUBLIC bible_core)
```

## Usage
To use the library, you will initilize the library and give it the path to your data base.

After that, you can call either `searchBibleText()` or `getChapter()` to search the Bible for a specific chapter, or a string of text.

You can then print the data to your UI by iterating threw the verses and scripture pieces for the apropriate styling and color. Checkout `printBibleToConsole()` to see a quick demo.

`verses()` returns a read-only reference to the latest query results, valid until
the next query or backend destruction. `lastError()` reports database/query errors;
an empty result with an empty error means no verses matched. Databases are opened
read-only. `getChapter(book, chapter, firstVerse, limit = -1)` returns verses in
verse order, starting at `firstVerse`; `-1` reads the rest of the chapter.

Refer to the [Cheat Sheet](./Cheat_Sheet.md) for a quick reference of the API.
