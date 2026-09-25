#include "my_application.h"

#include <cstdio>
#include <cstring>

#include "application_version.h"

namespace {

constexpr char kCommandLineUsage[] = R"USAGE(DartFlutterDemo command line

Usage: dart_flutter_demo [command] [options]

Commands:
  -h, --help                         Show this help and exit.
  -V, --version                      Print the full application version.
      --system-info[=json]           Print system information as text or JSON.
      --log-dir                      Print the session-log directory without creating it.
      --list-logs                    List existing session logs without creating one.
      --export-logs <target.zip>     Export existing session logs and a manifest.
      --clear-logs                   Delete existing session logs.

Options:
      --include-sensitive            Include hostname and local IP in --system-info output.
      --yes                          Skip the export or deletion confirmation prompt.
      --kde-wayland-focus=safe|mpris|all
                                      GUI only. safe is the default. mpris permits only
                                      MPRIS Play/Raise to ask KWin to focus the window;
                                      all permits every tokenless restore request.
                                      mpris and all deliberately bypass KWin's focus-stealing
                                      protection and require explicit user opt-in.
)USAGE";

// These two queries have no Dart, plugin, or display dependency. Handle only
// the standalone forms so mixed and invalid arguments retain Dart validation.
bool handle_standalone_cli_query(int argc, char** argv) {
  if (argc != 2) {
    return false;
  }
  if (std::strcmp(argv[1], "--help") == 0 ||
      std::strcmp(argv[1], "-h") == 0) {
    std::fputs(kCommandLineUsage, stdout);
    return true;
  }
  if (std::strcmp(argv[1], "--version") == 0 ||
      std::strcmp(argv[1], "-V") == 0) {
    std::fprintf(stdout, "%s\n", APPLICATION_VERSION);
    return true;
  }
  return false;
}

}  // namespace

int main(int argc, char** argv) {
  if (handle_standalone_cli_query(argc, argv)) {
    return 0;
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
