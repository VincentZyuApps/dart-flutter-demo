//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <system_info_vincentzyu/system_info_vincentzyu_plugin_c_api.h>
#include <taskbar_integration_vincentzyu/taskbar_integration_vincentzyu_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  SystemInfoVincentzyuPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SystemInfoVincentzyuPluginCApi"));
  TaskbarIntegrationVincentzyuPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TaskbarIntegrationVincentzyuPluginCApi"));
}
