#include "include/windows_desktop_integration_vincentzyu/windows_desktop_integration_vincentzyu_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "include/windows_desktop_integration_vincentzyu/windows_desktop_integration_vincentzyu_plugin.h"

void WindowsDesktopIntegrationVincentzyuPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  windows_desktop_integration_vincentzyu::WindowsDesktopIntegrationVincentzyuPlugin::
      RegisterWithRegistrar(
          flutter::PluginRegistrarManager::GetInstance()
              ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
