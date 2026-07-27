#ifndef FLUTTER_PLUGIN_SYSTEM_INFO_VINCENTZYU_PLUGIN_H_
#define FLUTTER_PLUGIN_SYSTEM_INFO_VINCENTZYU_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace system_info_vincentzyu {

class SystemInfoVincentzyuPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  SystemInfoVincentzyuPlugin();
  ~SystemInfoVincentzyuPlugin() override;

  SystemInfoVincentzyuPlugin(const SystemInfoVincentzyuPlugin&) = delete;
  SystemInfoVincentzyuPlugin& operator=(
      const SystemInfoVincentzyuPlugin&) = delete;
};

}  // namespace system_info_vincentzyu

#endif  // FLUTTER_PLUGIN_SYSTEM_INFO_VINCENTZYU_PLUGIN_H_
