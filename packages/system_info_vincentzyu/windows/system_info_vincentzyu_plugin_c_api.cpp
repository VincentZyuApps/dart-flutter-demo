#include "include/system_info_vincentzyu/system_info_vincentzyu_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "include/system_info_vincentzyu/system_info_vincentzyu_plugin.h"

void SystemInfoVincentzyuPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  system_info_vincentzyu::SystemInfoVincentzyuPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
