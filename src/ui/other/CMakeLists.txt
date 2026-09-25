file(GLOB SRC
  "*.cpp"
  "*.c"
  "${CMAKE_SOURCE_DIR}/external/cJSON/cJSON.c"
  "${CMAKE_SOURCE_DIR}/external/glad/src/glad.c"
  "${CMAKE_SOURCE_DIR}/external/imgui/*.cpp"
  "${CMAKE_SOURCE_DIR}/external/imgui/backends/imgui_impl_glfw.cpp"
  "${CMAKE_SOURCE_DIR}/external/imgui/backends/imgui_impl_opengl3.cpp"
)
add_library(ui ${SRC})

target_link_libraries(ui PRIVATE glfw)

target_include_directories(ui PRIVATE
  "${CMAKE_SOURCE_DIR}/external/glfw/include"
  "${CMAKE_SOURCE_DIR}/external/glad/include"
  "${CMAKE_SOURCE_DIR}/external/imgui"
  "${CMAKE_SOURCE_DIR}/external/cJSON"
)
