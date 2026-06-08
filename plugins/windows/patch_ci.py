# Windows: patch runner CMakeLists.txt so the system info source is compiled
# into the runner and its FFI entry points are exported for dart:ffi lookup.

cmake_path = "windows/runner/CMakeLists.txt"
with open(cmake_path, "r", encoding="utf-8") as f:
    cmake = f.read()

plugin_src = '  "runner/plugins/system_info/system_info_plugin.cpp"'
include_dir = '  "${CMAKE_CURRENT_SOURCE_DIR}/plugins/system_info"'
export_block = """if(MSVC)
  target_link_options(${BINARY_NAME} PRIVATE
    "/EXPORT:GetSystemInfoJson"
    "/EXPORT:FreeSystemInfoJson"
  )
endif()
"""

if plugin_src not in cmake:
    cmake = cmake.replace(
        '"runner/win32_window.cpp"', '"runner/win32_window.cpp"\n' + plugin_src
    )

if include_dir not in cmake:
    cmake = cmake.replace(
        "target_include_directories(${BINARY_NAME} PRIVATE",
        "target_include_directories(${BINARY_NAME} PRIVATE\n" + include_dir,
    )

if '"/EXPORT:GetSystemInfoJson"' not in cmake:
    marker = "target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)"
    replacement = marker + "\n\n" + export_block.rstrip()
    if marker not in cmake:
        raise RuntimeError(
            "Could not find target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app) "
            "in windows/runner/CMakeLists.txt to inject FFI exports."
        )
    cmake = cmake.replace(marker, replacement, 1)

with open(cmake_path, "w", encoding="utf-8") as f:
    f.write(cmake)
