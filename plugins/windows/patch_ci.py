# Windows: patch runner CMakeLists.txt so the system info source is compiled
# into the runner and its FFI entry points are exported for dart:ffi lookup.

import re

cmake_path = "windows/runner/CMakeLists.txt"
with open(cmake_path, "r", encoding="utf-8") as f:
    cmake = f.read()

plugin_src = '  "plugins/system_info/system_info_plugin.cpp"'
include_dir = '  "${CMAKE_CURRENT_SOURCE_DIR}/plugins/system_info"'
export_block = """if(MSVC)
  target_link_options(${BINARY_NAME} PRIVATE
    "/EXPORT:GetSystemInfoJson"
    "/EXPORT:FreeSystemInfoJson"
  )
endif()
"""


def inject_into_block(text: str, block_name: str, addition: str) -> str:
    pattern = rf"({re.escape(block_name)}\(\$\{{BINARY_NAME\}}.*?\n)(\))"
    match = re.search(pattern, text, flags=re.DOTALL)
    if not match:
        raise RuntimeError(
            f"Could not find `{block_name}(${{BINARY_NAME}} ...)` block in {cmake_path}."
        )

    block = match.group(0)
    if addition in block:
        return text

    updated = block[:-1] + addition + "\n)"
    return text.replace(block, updated, 1)


def inject_standalone_include_block(text: str, addition: str) -> str:
    standalone_block = (
        "target_include_directories(${BINARY_NAME} PRIVATE\n"
        f"{addition}\n"
        ")\n"
    )
    if addition in text:
        return text

    marker = "target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)"
    if marker not in text:
        raise RuntimeError(
            "Could not find target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app) "
            f"in {cmake_path} to inject include directories."
        )
    return text.replace(marker, standalone_block + "\n" + marker, 1)


if plugin_src not in cmake:
    cmake = inject_into_block(cmake, "add_executable", plugin_src)

if include_dir not in cmake:
    try:
        cmake = inject_into_block(cmake, "target_include_directories", include_dir)
    except RuntimeError:
        cmake = inject_standalone_include_block(cmake, include_dir)

if '"/EXPORT:GetSystemInfoJson"' not in cmake:
    marker = "target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)"
    replacement = marker + "\n\n" + export_block.rstrip()
    if marker not in cmake:
        raise RuntimeError(
            "Could not find target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app) "
            f"in {cmake_path} to inject FFI exports."
        )
    cmake = cmake.replace(marker, replacement, 1)

for required in (plugin_src, include_dir, '"/EXPORT:GetSystemInfoJson"', '"/EXPORT:FreeSystemInfoJson"'):
    if required not in cmake:
        raise RuntimeError(f"Patch verification failed: missing expected snippet `{required}` in {cmake_path}.")

with open(cmake_path, "w", encoding="utf-8") as f:
    f.write(cmake)
