#ifndef FLUTTER_PLUGIN_SYSTEM_INFO_VINCENTZYU_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_SYSTEM_INFO_VINCENTZYU_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void SystemInfoVincentzyuPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

FLUTTER_PLUGIN_EXPORT char* SystemInfoVincentzyuGetJson();
FLUTTER_PLUGIN_EXPORT void SystemInfoVincentzyuFreeJson(char* value);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_SYSTEM_INFO_VINCENTZYU_PLUGIN_C_API_H_
