#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// The Windows runner is a GUI-subsystem executable. GitHub Actions and other
// non-interactive hosts do not provide a parent console, so Dart's stdout is
// otherwise invalid for these commands even though the Dart entrypoint runs.
bool IsConsoleCommand(const std::vector<std::string>& arguments) {
  for (const std::string& argument : arguments) {
    if (argument == "--help" || argument == "-h" ||
        argument == "--version" || argument == "-V" ||
        argument == "--system-info" || argument == "--system-info=json" ||
        argument == "--log-dir" || argument == "--list-logs" ||
        argument == "--export-logs" || argument == "--clear-logs") {
      return true;
    }
  }
  return false;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console for a debugger or a CLI command. The latter makes commands
  // usable from non-interactive runners, where no parent console exists.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) &&
      (::IsDebuggerPresent() || IsConsoleCommand(command_line_arguments))) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"DartFlutterDemo", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
