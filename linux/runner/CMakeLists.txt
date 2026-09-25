cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Keep the native early CLI path on the same version as the Dart application.
set(PUBSPEC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../pubspec.yaml")
file(STRINGS "${PUBSPEC_PATH}" APPLICATION_VERSION_LINE
  REGEX "^version:[ \t]*")
string(REGEX REPLACE "^version:[ \t]*([^ \t\r\n]+).*$" "\\1"
  APPLICATION_VERSION "${APPLICATION_VERSION_LINE}")
if(NOT APPLICATION_VERSION)
  message(FATAL_ERROR "Could not read version from ${PUBSPEC_PATH}")
endif()
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${PUBSPEC_PATH}")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/generated")
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/application_version.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/generated/application_version.h"
  @ONLY
)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
  "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
