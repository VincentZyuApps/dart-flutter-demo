#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <windows.h>
#include <winternl.h>

#include "include/system_info_vincentzyu/system_info_vincentzyu_plugin.h"
#include "include/system_info_vincentzyu/system_info_vincentzyu_plugin_c_api.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <iomanip>
#include <memory>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

namespace {

struct Values {
  std::string operating_system;
  std::string host;
  std::string kernel;
  int64_t uptime_seconds = 0;
  std::string cpu_model;
  int64_t logical_processors = 0;
  int64_t memory_used_bytes = 0;
  int64_t memory_total_bytes = 0;
  int64_t disk_used_bytes = 0;
  int64_t disk_total_bytes = 0;
  std::string local_ip;
  std::string locale;
};

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) return {};
  const int size = WideCharToMultiByte(CP_UTF8, 0, value.data(),
                                      static_cast<int>(value.size()), nullptr, 0,
                                      nullptr, nullptr);
  std::string result(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.data(),
                      static_cast<int>(value.size()), result.data(), size,
                      nullptr, nullptr);
  return result;
}

std::string ReadRegistryString(HKEY root, const wchar_t* path,
                               const wchar_t* name) {
  HKEY key = nullptr;
  if (RegOpenKeyExW(root, path, 0, KEY_READ, &key) != ERROR_SUCCESS) return {};
  DWORD type = 0;
  DWORD size = 0;
  if (RegQueryValueExW(key, name, nullptr, &type, nullptr, &size) != ERROR_SUCCESS ||
      (type != REG_SZ && type != REG_EXPAND_SZ) || size < sizeof(wchar_t)) {
    RegCloseKey(key);
    return {};
  }
  std::vector<wchar_t> buffer(size / sizeof(wchar_t) + 1, L'\0');
  const LONG status = RegQueryValueExW(
      key, name, nullptr, nullptr, reinterpret_cast<LPBYTE>(buffer.data()), &size);
  RegCloseKey(key);
  return status == ERROR_SUCCESS ? WideToUtf8(buffer.data()) : std::string();
}

RTL_OSVERSIONINFOW OsVersion() {
  RTL_OSVERSIONINFOW version = {};
  version.dwOSVersionInfoSize = sizeof(version);
  using RtlGetVersionFn = LONG(WINAPI*)(PRTL_OSVERSIONINFOW);
  const auto function = reinterpret_cast<RtlGetVersionFn>(
      GetProcAddress(GetModuleHandleW(L"ntdll.dll"), "RtlGetVersion"));
  if (function != nullptr) function(&version);
  return version;
}

std::string OperatingSystem(const RTL_OSVERSIONINFOW& version) {
  std::string product = ReadRegistryString(
      HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
      L"ProductName");
  if (product.empty()) product = "Windows";
  if (version.dwBuildNumber >= 22000 && product.find("Windows 10") != std::string::npos) {
    product.replace(product.find("Windows 10"), std::strlen("Windows 10"), "Windows 11");
  }
  const std::string display = ReadRegistryString(
      HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
      L"DisplayVersion");
  std::ostringstream output;
  output << product;
  if (!display.empty()) output << " " << display;
  output << " (build " << version.dwBuildNumber << ")";
  return output.str();
}

std::string Host() {
  const std::string manufacturer = ReadRegistryString(
      HKEY_LOCAL_MACHINE, L"HARDWARE\\DESCRIPTION\\System\\BIOS",
      L"SystemManufacturer");
  const std::string product = ReadRegistryString(
      HKEY_LOCAL_MACHINE, L"HARDWARE\\DESCRIPTION\\System\\BIOS",
      L"SystemProductName");
  if (!product.empty() && product != "System Product Name" &&
      product != "To be filled by O.E.M.") {
    return manufacturer.empty() ? product : manufacturer + " " + product;
  }
  wchar_t buffer[MAX_COMPUTERNAME_LENGTH + 1] = {};
  DWORD size = MAX_COMPUTERNAME_LENGTH + 1;
  return GetComputerNameW(buffer, &size)
             ? WideToUtf8(std::wstring(buffer, size))
             : std::string();
}

std::string CpuModel() {
  return ReadRegistryString(
      HKEY_LOCAL_MACHINE,
      L"HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0",
      L"ProcessorNameString");
}

std::string LocalIp() {
  ULONG size = 16 * 1024;
  std::vector<unsigned char> storage(size);
  auto* addresses = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(storage.data());
  ULONG result = GetAdaptersAddresses(
      AF_INET, GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST |
                   GAA_FLAG_SKIP_DNS_SERVER,
      nullptr, addresses, &size);
  if (result == ERROR_BUFFER_OVERFLOW) {
    storage.resize(size);
    addresses = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(storage.data());
    result = GetAdaptersAddresses(
        AF_INET, GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST |
                     GAA_FLAG_SKIP_DNS_SERVER,
        nullptr, addresses, &size);
  }
  if (result != NO_ERROR) return {};

  std::string fallback;
  for (auto* adapter = addresses; adapter != nullptr; adapter = adapter->Next) {
    if (adapter->OperStatus != IfOperStatusUp ||
        adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) continue;
    for (auto* address = adapter->FirstUnicastAddress; address != nullptr;
         address = address->Next) {
      if (address->Address.lpSockaddr->sa_family != AF_INET) continue;
      char text[INET_ADDRSTRLEN] = {};
      const auto* ipv4 = reinterpret_cast<sockaddr_in*>(address->Address.lpSockaddr);
      if (inet_ntop(AF_INET, &ipv4->sin_addr, text, sizeof(text)) == nullptr) continue;
      const std::string value(text);
      if (value.rfind("127.", 0) == 0 || value.rfind("169.254.", 0) == 0) continue;
      if (adapter->IfType == IF_TYPE_IEEE80211 ||
          adapter->IfType == IF_TYPE_ETHERNET_CSMACD) return value;
      if (fallback.empty()) fallback = value;
    }
  }
  return fallback;
}

Values CollectValues() {
  Values values;
  const RTL_OSVERSIONINFOW version = OsVersion();
  values.operating_system = OperatingSystem(version);
  values.host = Host();
  std::ostringstream kernel;
  kernel << "WIN32_NT " << version.dwMajorVersion << "."
         << version.dwMinorVersion << "." << version.dwBuildNumber;
  values.kernel = kernel.str();
  values.uptime_seconds = static_cast<int64_t>(GetTickCount64() / 1000);
  values.cpu_model = CpuModel();
  values.logical_processors = GetActiveProcessorCount(ALL_PROCESSOR_GROUPS);

  MEMORYSTATUSEX memory = {};
  memory.dwLength = sizeof(memory);
  if (GlobalMemoryStatusEx(&memory)) {
    values.memory_total_bytes = static_cast<int64_t>(memory.ullTotalPhys);
    values.memory_used_bytes = static_cast<int64_t>(
        memory.ullTotalPhys - memory.ullAvailPhys);
  }

  ULARGE_INTEGER available = {}, total = {}, free = {};
  if (GetDiskFreeSpaceExW(L"C:\\", &available, &total, &free)) {
    values.disk_total_bytes = static_cast<int64_t>(total.QuadPart);
    values.disk_used_bytes = static_cast<int64_t>(
        total.QuadPart - available.QuadPart);
  }
  values.local_ip = LocalIp();
  wchar_t locale[LOCALE_NAME_MAX_LENGTH] = {};
  if (GetUserDefaultLocaleName(locale, LOCALE_NAME_MAX_LENGTH) > 0) {
    values.locale = WideToUtf8(locale);
  }
  return values;
}

std::string EscapeJson(const std::string& value) {
  std::ostringstream output;
  for (const unsigned char character : value) {
    switch (character) {
      case '"': output << "\\\""; break;
      case '\\': output << "\\\\"; break;
      case '\b': output << "\\b"; break;
      case '\f': output << "\\f"; break;
      case '\n': output << "\\n"; break;
      case '\r': output << "\\r"; break;
      case '\t': output << "\\t"; break;
      default:
        if (character < 0x20) {
          output << "\\u" << std::hex << std::setw(4) << std::setfill('0')
                 << static_cast<int>(character) << std::dec;
        } else {
          output << character;
        }
    }
  }
  return output.str();
}

std::string ValuesToJson(const Values& value) {
  std::ostringstream output;
  output << "{"
         << "\"operatingSystem\":\"" << EscapeJson(value.operating_system) << "\","
         << "\"host\":\"" << EscapeJson(value.host) << "\","
         << "\"kernel\":\"" << EscapeJson(value.kernel) << "\","
         << "\"uptimeSeconds\":" << value.uptime_seconds << ","
         << "\"cpuModel\":\"" << EscapeJson(value.cpu_model) << "\","
         << "\"logicalProcessors\":" << value.logical_processors << ","
         << "\"memoryUsedBytes\":" << value.memory_used_bytes << ","
         << "\"memoryTotalBytes\":" << value.memory_total_bytes << ","
         << "\"diskUsedBytes\":" << value.disk_used_bytes << ","
         << "\"diskTotalBytes\":" << value.disk_total_bytes << ","
         << "\"localIp\":\"" << EscapeJson(value.local_ip) << "\","
         << "\"locale\":\"" << EscapeJson(value.locale) << "\"}"
         ;
  return output.str();
}

flutter::EncodableMap ValuesToMap(const Values& value) {
  return {
      {flutter::EncodableValue("operatingSystem"), flutter::EncodableValue(value.operating_system)},
      {flutter::EncodableValue("host"), flutter::EncodableValue(value.host)},
      {flutter::EncodableValue("kernel"), flutter::EncodableValue(value.kernel)},
      {flutter::EncodableValue("uptimeSeconds"), flutter::EncodableValue(value.uptime_seconds)},
      {flutter::EncodableValue("cpuModel"), flutter::EncodableValue(value.cpu_model)},
      {flutter::EncodableValue("logicalProcessors"), flutter::EncodableValue(value.logical_processors)},
      {flutter::EncodableValue("memoryUsedBytes"), flutter::EncodableValue(value.memory_used_bytes)},
      {flutter::EncodableValue("memoryTotalBytes"), flutter::EncodableValue(value.memory_total_bytes)},
      {flutter::EncodableValue("diskUsedBytes"), flutter::EncodableValue(value.disk_used_bytes)},
      {flutter::EncodableValue("diskTotalBytes"), flutter::EncodableValue(value.disk_total_bytes)},
      {flutter::EncodableValue("localIp"), flutter::EncodableValue(value.local_ip)},
      {flutter::EncodableValue("locale"), flutter::EncodableValue(value.locale)},
  };
}

}  // namespace

namespace system_info_vincentzyu {

SystemInfoVincentzyuPlugin::SystemInfoVincentzyuPlugin() = default;
SystemInfoVincentzyuPlugin::~SystemInfoVincentzyuPlugin() = default;

void SystemInfoVincentzyuPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "system_info_vincentzyu/methods",
      &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const auto& call, auto result) {
        if (call.method_name() == "getInfo") {
          result->Success(flutter::EncodableValue(ValuesToMap(CollectValues())));
        } else {
          result->NotImplemented();
        }
      });
  registrar->AddPlugin(std::make_unique<SystemInfoVincentzyuPlugin>());
}

}  // namespace system_info_vincentzyu

char* SystemInfoVincentzyuGetJson() {
  const std::string json = ValuesToJson(CollectValues());
  auto* result = static_cast<char*>(std::malloc(json.size() + 1));
  if (result == nullptr) return nullptr;
  std::memcpy(result, json.c_str(), json.size() + 1);
  return result;
}

void SystemInfoVincentzyuFreeJson(char* value) {
  std::free(value);
}
