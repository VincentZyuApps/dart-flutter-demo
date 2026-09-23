cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "windows_desktop_integration_vincentzyu")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "windows_desktop_integration_vincentzyu_plugin")

add_library(${PLUGIN_NAME} SHARED
  "windows_desktop_integration_vincentzyu_plugin.cpp"
  "windows_desktop_integration_vincentzyu_plugin_c_api.cpp"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  ole32
  shell32
  uuid)

set(windows_desktop_integration_vincentzyu_bundled_libraries
  ""
  PARENT_SCOPE
)
