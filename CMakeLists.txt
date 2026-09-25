cmake_minimum_required(VERSION 4.0.1)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(Bible_Viewer C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}>")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}>")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}>")

option(GUI "Build the graphical application" ON)

add_subdirectory("src/core")

if (GUI)
  if (APPLE)
    enable_language(Swift)
    add_subdirectory("src/ui/apple")
  endif()
endif() # GUI
