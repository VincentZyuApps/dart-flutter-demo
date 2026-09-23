//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <file_selector_windows/file_selector_windows.h>
#include <system_info_vincentzyu/system_info_vincentzyu_plugin_c_api.h>
#include <url_launcher_windows/url_launcher_windows.h>
#include <windows_desktop_integration_vincentzyu/windows_desktop_integration_vincentzyu_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
  SystemInfoVincentzyuPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SystemInfoVincentzyuPluginCApi"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
  WindowsDesktopIntegrationVincentzyuPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowsDesktopIntegrationVincentzyuPluginCApi"));
}
