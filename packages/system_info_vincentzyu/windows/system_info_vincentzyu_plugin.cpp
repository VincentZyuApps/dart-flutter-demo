#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <windows.h>
#include <winioctl.h>
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
#include <utility>
#include <vector>

namespace {

struct StorageVolume {
  std::string mount_point;
  std::string volume_label;
  int64_t used_bytes = 0;
  int64_t total_bytes = 0;
  std::string file_system;
  std::string device;
};

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
  std::vector<StorageVolume> storage_volumes;
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

std::vector<StorageVolume> CollectStorageVolumes() {
  std::vector<StorageVolume> volumes;
  const DWORD drives = GetLogicalDrives();
  for (wchar_t letter = L'A'; letter <= L'Z'; ++letter) {
    if ((drives & (1u << (letter - L'A'))) == 0) continue;
    const std::wstring root = std::wstring(1, letter) + L":\\";
    const UINT kind = GetDriveTypeW(root.c_str());
    if (kind != DRIVE_FIXED && kind != DRIVE_REMOVABLE && kind != DRIVE_REMOTE &&
        kind != DRIVE_RAMDISK) {
      continue;
    }

    ULARGE_INTEGER available = {}, total = {}, free = {};
    if (!GetDiskFreeSpaceExW(root.c_str(), &available, &total, &free) ||
        total.QuadPart == 0) {
      continue;
    }
    wchar_t label[MAX_PATH + 1] = {};
    wchar_t file_system[MAX_PATH + 1] = {};
    DWORD serial = 0, max_component_length = 0, flags = 0;
    GetVolumeInformationW(root.c_str(), label, MAX_PATH, &serial,
                          &max_component_length, &flags, file_system, MAX_PATH);

    StorageVolume volume;
    volume.mount_point = WideToUtf8(root);
    volume.volume_label = WideToUtf8(label);
    volume.total_bytes = static_cast<int64_t>(total.QuadPart);
    volume.used_bytes = static_cast<int64_t>(total.QuadPart - available.QuadPart);
    volume.file_system = WideToUtf8(file_system);

    const std::wstring device_path = L"\\\\.\\" + std::wstring(1, letter) + L":";
    HANDLE handle = CreateFileW(device_path.c_str(), 0,
                                FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                                OPEN_EXISTING, 0, nullptr);
    if (handle != INVALID_HANDLE_VALUE) {
      VOLUME_DISK_EXTENTS extents = {};
      DWORD returned = 0;
      if (DeviceIoControl(handle, IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS, nullptr, 0,
                          &extents, sizeof(extents), &returned, nullptr) &&
          extents.NumberOfDiskExtents > 0) {
        volume.device = "\\\\.\\PhysicalDrive" +
                        std::to_string(extents.Extents[0].DiskNumber);
      }
      CloseHandle(handle);
    }
    volumes.push_back(std::move(volume));
  }
  return volumes;
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

  values.storage_volumes = CollectStorageVolumes();
  const auto primary = std::find_if(
      values.storage_volumes.begin(), values.storage_volumes.end(),
      [](const StorageVolume& volume) { return volume.mount_point == "C:\\"; });
  if (primary != values.storage_volumes.end()) {
    values.disk_total_bytes = primary->total_bytes;
    values.disk_used_bytes = primary->used_bytes;
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

std::string StorageVolumesToJson(const std::vector<StorageVolume>& volumes) {
  std::ostringstream output;
  output << "[";
  for (size_t index = 0; index < volumes.size(); ++index) {
    const auto& volume = volumes[index];
    if (index > 0) output << ",";
    output << "{\"mountPoint\":\"" << EscapeJson(volume.mount_point) << "\",";
    if (!volume.volume_label.empty()) {
      output << "\"volumeLabel\":\"" << EscapeJson(volume.volume_label) << "\",";
    }
    output << "\"usedBytes\":" << volume.used_bytes << ","
           << "\"totalBytes\":" << volume.total_bytes;
    if (!volume.file_system.empty()) {
      output << ",\"fileSystem\":\"" << EscapeJson(volume.file_system) << "\"";
    }
    if (!volume.device.empty()) {
      output << ",\"device\":\"" << EscapeJson(volume.device) << "\"";
    }
    output << "}";
  }
  output << "]";
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
         << "\"storageVolumes\":" << StorageVolumesToJson(value.storage_volumes) << ","
         << "\"localIp\":\"" << EscapeJson(value.local_ip) << "\","
         << "\"locale\":\"" << EscapeJson(value.locale) << "\"}"
         ;
  return output.str();
}

flutter::EncodableMap ValuesToMap(const Values& value) {
  flutter::EncodableList volumes;
  for (const auto& volume : value.storage_volumes) {
    flutter::EncodableMap entry = {
        {flutter::EncodableValue("mountPoint"), flutter::EncodableValue(volume.mount_point)},
        {flutter::EncodableValue("usedBytes"), flutter::EncodableValue(volume.used_bytes)},
        {flutter::EncodableValue("totalBytes"), flutter::EncodableValue(volume.total_bytes)},
    };
    if (!volume.volume_label.empty()) entry[flutter::EncodableValue("volumeLabel")] = flutter::EncodableValue(volume.volume_label);
    if (!volume.file_system.empty()) entry[flutter::EncodableValue("fileSystem")] = flutter::EncodableValue(volume.file_system);
    if (!volume.device.empty()) entry[flutter::EncodableValue("device")] = flutter::EncodableValue(volume.device);
    volumes.emplace_back(std::move(entry));
  }
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
      {flutter::EncodableValue("storageVolumes"), flutter::EncodableValue(volumes)},
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
