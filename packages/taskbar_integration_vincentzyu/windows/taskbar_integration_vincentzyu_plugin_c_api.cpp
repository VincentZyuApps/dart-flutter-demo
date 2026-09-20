#include "include/taskbar_integration_vincentzyu/taskbar_integration_vincentzyu_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "include/taskbar_integration_vincentzyu/taskbar_integration_vincentzyu_plugin.h"

void TaskbarIntegrationVincentzyuPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  taskbar_integration_vincentzyu::TaskbarIntegrationVincentzyuPlugin::
      RegisterWithRegistrar(
          flutter::PluginRegistrarManager::GetInstance()
              ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
