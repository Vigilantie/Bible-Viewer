enable_language(OBJCXX)

add_executable(${PROJECT_NAME} MACOSX_BUNDLE
  Bible_Viewer_WindowApp.swift
  ContentView.swift
  BibleReader.swift
  ScriptureFormatting.swift
  BibleBridge.mm
  BibleBridge.h
)

target_compile_options(${PROJECT_NAME} PRIVATE
  "$<$<COMPILE_LANGUAGE:Swift>:-import-objc-header;${CMAKE_CURRENT_SOURCE_DIR}/BibleBridge.h>"
  "$<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>"
)

target_link_libraries(${PROJECT_NAME} PRIVATE
  "-framework SwiftUI"
  bible_core
)

target_include_directories(${PROJECT_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}/include"
)

set_target_properties(${PROJECT_NAME} PROPERTIES
  MACOSX_BUNDLE_GUI_IDENTIFIER "org.bibleviewer.app"
  MACOSX_BUNDLE_BUNDLE_NAME "Bible Viewer"
  MACOSX_BUNDLE_ICON_FILE "Icon.icns"
  # MACOSX_BUNDLE_BUNDLE_VERSION "1.0.0"
  # MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
  MACOSX_BUNDLE_COPYRIGHT "Copyright 2026 Jacob"
)

set(RESOURCE_FILES
  "${CMAKE_SOURCE_DIR}/assets/Bible"
  "${CMAKE_SOURCE_DIR}/assets/Icon/Icon.icns"
)

set_source_files_properties(${RESOURCE_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
target_sources(${PROJECT_NAME} PRIVATE ${RESOURCE_FILES})
