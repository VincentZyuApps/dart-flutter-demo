// windows.h defines min and max as macros unless NOMINMAX is set first, and
// rpcndr.h defines legacy MIDL aliases such as `small` for `char`.
#define NOMINMAX

#include "include/windows_desktop_integration_vincentzyu/windows_desktop_integration_vincentzyu_plugin.h"

#include <flutter/standard_method_codec.h>

#include <appmodel.h>
#include <propkey.h>
#include <propsys.h>
#include <shellapi.h>
#include <shobjidl.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <cwchar>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace windows_desktop_integration_vincentzyu {

namespace {

// Window class of the hidden window that receives forwarded command lines.
constexpr wchar_t kSinkWindowClass[] =
    L"VincentZyuApps.DartFlutterDemo.TaskbarSink";

// Session local mutex that decides which process owns the taskbar identity.
constexpr wchar_t kSingleInstanceMutex[] =
    L"VincentZyuApps.DartFlutterDemo.SingleInstance";

// Taskbar identity of unpackaged launches of this application.
constexpr wchar_t kAppUserModelId[] = L"VincentZyuApps.DartFlutterDemo";

// Tooltip and sender name of the shell notification.
constexpr wchar_t kAppDisplayName[] = L"Dart + Flutter Demo";

// Jump list category that holds the seven destinations.
constexpr wchar_t kJumpListCategory[] = L"Pages";

// Marks a WM_COPYDATA payload as a forwarded command line.
constexpr DWORD kCopyDataCommandLine = 0x5A565A56;  // 'ZVZV'

// Windows drops thumbnail toolbar buttons beyond this limit, from the right.
constexpr size_t kThumbnailButtonLimit = 7;

// Button identifiers are one based and map onto the order of the request.
constexpr UINT kThumbnailButtonIdBase = 1;

// Identifier of the temporary tray icon that owns the notification balloon.
constexpr UINT kTrayIconId = 1;

// Message the shell posts to the sink window for tray icon events.
constexpr UINT kTrayCallbackMessage = WM_APP + 41;

// Timer that retires the tray icon once the balloon has been shown.
constexpr UINT_PTR kTrayTimerId = 1;
constexpr UINT kTrayLifetimeMs = 15000;

// Keeps a COM interface alive for the duration of a function.
template <typename T>
class ComRef {
 public:
  ComRef() = default;
  ~ComRef() { Reset(); }
  ComRef(const ComRef&) = delete;
  ComRef& operator=(const ComRef&) = delete;

  T* Get() const { return pointer_; }
  T* operator->() const { return pointer_; }

  void** PutVoid() {
    Reset();
    return reinterpret_cast<void**>(&pointer_);
  }

  void Reset() {
    if (pointer_ != nullptr) {
      pointer_->Release();
      pointer_ = nullptr;
    }
  }

 private:
  T* pointer_ = nullptr;
};

std::string Utf8FromWide(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }
  const int size =
      WideCharToMultiByte(CP_UTF8, 0, value.data(),
                          static_cast<int>(value.size()), nullptr, 0, nullptr,
                          nullptr);
  if (size <= 0) {
    return std::string();
  }
  std::string result(static_cast<size_t>(size), '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      result.data(), size, nullptr, nullptr);
  return result;
}

std::wstring WideFromUtf8(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }
  const int size =
      MultiByteToWideChar(CP_UTF8, 0, value.data(),
                          static_cast<int>(value.size()), nullptr, 0);
  if (size <= 0) {
    return std::wstring();
  }
  std::wstring result(static_cast<size_t>(size), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      result.data(), size);
  return result;
}

const flutter::EncodableValue* MapValue(const flutter::EncodableMap& map,
                                       const char* key) {
  const auto entry = map.find(flutter::EncodableValue(key));
  if (entry == map.end()) {
    return nullptr;
  }
  return &entry->second;
}

std::string StringValue(const flutter::EncodableValue* value) {
  if (value == nullptr) {
    return std::string();
  }
  const std::string* text = std::get_if<std::string>(value);
  return text == nullptr ? std::string() : *text;
}

bool BoolValue(const flutter::EncodableValue* value, bool fallback) {
  if (value == nullptr) {
    return fallback;
  }
  const bool* flag = std::get_if<bool>(value);
  return flag == nullptr ? fallback : *flag;
}

int64_t IntValue(const flutter::EncodableValue* value, int64_t fallback) {
  if (value == nullptr) {
    return fallback;
  }
  if (const int32_t* narrow = std::get_if<int32_t>(value)) {
    return *narrow;
  }
  if (const int64_t* large = std::get_if<int64_t>(value)) {
    return *large;
  }
  return fallback;
}

const std::vector<uint8_t>* ByteListValue(const flutter::EncodableValue* value) {
  if (value == nullptr) {
    return nullptr;
  }
  return std::get_if<std::vector<uint8_t>>(value);
}

// Gives unpackaged launches a stable taskbar identity so the shell can group the
// window and accept its custom jump list. Packaged (MSIX) launches already own
// their identity, so they keep it.
void TrySetAppUserModelId() {
  UINT32 package_name_length = 0;
  if (GetCurrentPackageFullName(&package_name_length, nullptr) !=
      APPMODEL_ERROR_NO_PACKAGE) {
    return;
  }
  SetCurrentProcessExplicitAppUserModelID(kAppUserModelId);
}

std::wstring ExecutablePath() {
  std::vector<wchar_t> buffer(MAX_PATH);
  while (true) {
    const DWORD length = GetModuleFileNameW(
        nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (length == 0) {
      return std::wstring();
    }
    if (static_cast<size_t>(length) < buffer.size()) {
      return std::wstring(buffer.data(), static_cast<size_t>(length));
    }
    buffer.resize(buffer.size() * 2);
  }
}

// Command line arguments of this process, without the executable path.
std::wstring CommandLineArguments() {
  int argument_count = 0;
  LPWSTR* arguments = CommandLineToArgvW(GetCommandLineW(), &argument_count);
  if (arguments == nullptr) {
    return std::wstring();
  }
  std::wstring result;
  for (int index = 1; index < argument_count; ++index) {
    if (!result.empty()) {
      result.push_back(L' ');
    }
    result.append(arguments[index]);
  }
  LocalFree(arguments);
  return result;
}

void DestroyIcons(std::vector<HICON>& icons) {
  for (HICON icon : icons) {
    if (icon != nullptr) {
      DestroyIcon(icon);
    }
  }
  icons.clear();
}

// Lets a lower integrity process reach a window of this instance.
//
// The taskbar sends a hover button click, and Explorer starts the copy that
// forwards a jump list command. Both senders run at the medium integrity level
// of the logged on user, while an administrator instance sits above them, and
// User Interface Privilege Isolation silently drops the messages of a lower
// integrity sender. Without this call the seven hover buttons and the seven
// jump list entries stay visible but every click is lost.
void AllowMessageFromLowerIntegrity(HWND window, UINT message) {
  if (window == nullptr) {
    return;
  }
  ChangeWindowMessageFilterEx(window, message, MSGFLT_ALLOW, nullptr);
}

// Turns premultiplied RGBA pixels into a 32bpp icon.
HICON CreateIconFromRgba(int32_t width,
                         int32_t height,
                         const std::vector<uint8_t>& pixels) {
  if (width <= 0 || height <= 0) {
    return nullptr;
  }
  const size_t expected =
      static_cast<size_t>(width) * static_cast<size_t>(height) * 4u;
  if (pixels.size() < expected) {
    return nullptr;
  }

  BITMAPINFO info = {};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = width;
  info.bmiHeader.biHeight = -height;  // Top down rows.
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  info.bmiHeader.biCompression = BI_RGB;

  HDC screen = GetDC(nullptr);
  void* bits = nullptr;
  HBITMAP colour =
      CreateDIBSection(screen, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (screen != nullptr) {
    ReleaseDC(nullptr, screen);
  }
  if (colour == nullptr || bits == nullptr) {
    if (colour != nullptr) {
      DeleteObject(colour);
    }
    return nullptr;
  }

  // A 32bpp BI_RGB bitmap is BGRA in memory, and the taskbar expects the same
  // premultiplied alpha the Flutter side already sends.
  uint8_t* target = static_cast<uint8_t*>(bits);
  for (size_t offset = 0; offset + 3u < expected; offset += 4u) {
    target[offset] = pixels[offset + 2u];
    target[offset + 1u] = pixels[offset + 1u];
    target[offset + 2u] = pixels[offset];
    target[offset + 3u] = pixels[offset + 3u];
  }

  const int mask_stride = ((width + 31) / 32) * 4;
  std::vector<uint8_t> mask_bits(
      static_cast<size_t>(mask_stride) * static_cast<size_t>(height), 0);
  HBITMAP mask = CreateBitmap(width, height, 1, 1, mask_bits.data());

  ICONINFO icon_info = {};
  icon_info.fIcon = TRUE;
  icon_info.hbmColor = colour;
  icon_info.hbmMask = mask;
  HICON icon = CreateIconIndirect(&icon_info);

  DeleteObject(colour);
  if (mask != nullptr) {
    DeleteObject(mask);
  }
  return icon;
}

// Adds one entry to the destination collection.
//
// Separator entries are deliberately avoided: Windows 11 rejects a category
// that contains one with E_INVALIDARG and then drops the whole category, which
// silently removes the jump list.
bool AppendJumpListEntry(IObjectCollection* collection,
                         const std::wstring& executable,
                         const std::wstring& title,
                         const std::wstring& arguments,
                         const std::wstring& icon_path) {
  ComRef<IShellLinkW> link;
  if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                              IID_IShellLinkW, link.PutVoid()))) {
    return false;
  }
  if (FAILED(link->SetPath(executable.c_str()))) {
    return false;
  }
  if (FAILED(link->SetArguments(arguments.c_str()))) {
    return false;
  }
  // The icon has to be a file the shell can open. A packaged build lives in a
  // directory Explorer cannot reach and the assets of the bundle are not files
  // at all, so the Dart side renders one icon per entry into the user profile
  // and hands the path over here.
  if (icon_path.empty()) {
    link->SetIconLocation(executable.c_str(), 0);
  } else {
    link->SetIconLocation(icon_path.c_str(), 0);
  }

  ComRef<IPropertyStore> properties;
  if (FAILED(link->QueryInterface(IID_IPropertyStore, properties.PutVoid()))) {
    return false;
  }
  PROPVARIANT property = {};
  property.vt = VT_LPWSTR;
  property.pwszVal = const_cast<wchar_t*>(title.c_str());
  if (FAILED(properties->SetValue(PKEY_Title, property))) {
    return false;
  }
  if (FAILED(properties->Commit())) {
    return false;
  }
  return SUCCEEDED(collection->AddObject(link.Get()));
}

}  // namespace

// Owns the event sink of the event channel.
class EventSinkSlot {
 public:
  void Set(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink) {
    sink_ = std::move(sink);
  }

  flutter::EventSink<flutter::EncodableValue>* sink() const {
    return sink_.get();
  }

 private:
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};

namespace {

// Bridges the event channel to the plugin through the shared sink slot.
class TaskbarStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  explicit TaskbarStreamHandler(std::shared_ptr<EventSinkSlot> slot)
      : slot_(std::move(slot)) {}

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
      override {
    if (std::shared_ptr<EventSinkSlot> slot = slot_.lock()) {
      slot->Set(std::move(events));
    }
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* arguments) override {
    if (std::shared_ptr<EventSinkSlot> slot = slot_.lock()) {
      slot->Set(nullptr);
    }
    return nullptr;
  }

 private:
  std::weak_ptr<EventSinkSlot> slot_;
};

}  // namespace

WindowsDesktopIntegrationVincentzyuPlugin::WindowsDesktopIntegrationVincentzyuPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar), sink_slot_(std::make_shared<EventSinkSlot>()) {
  TrySetAppUserModelId();
  auto method_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "windows_desktop_integration_vincentzyu/methods",
          &flutter::StandardMethodCodec::GetInstance());
  method_channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) { HandleMethodCall(call, std::move(result)); });
  method_channel_ = std::move(method_channel);

  auto event_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "windows_desktop_integration_vincentzyu/events",
          &flutter::StandardMethodCodec::GetInstance());
  event_channel->SetStreamHandler(
      std::make_unique<TaskbarStreamHandler>(sink_slot_));
  event_channel_ = std::move(event_channel);

  window_proc_delegate_id_ = registrar->RegisterTopLevelWindowProcDelegate(
      [this](HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(window, message, wparam, lparam);
      });
}

WindowsDesktopIntegrationVincentzyuPlugin::~WindowsDesktopIntegrationVincentzyuPlugin() {
  if (registrar_ != nullptr && window_proc_delegate_id_ != 0) {
    registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_delegate_id_);
    window_proc_delegate_id_ = 0;
  }
  DestroyIcons(thumbnail_icons_);
  RemoveTrayIcon();
  if (taskbar_ != nullptr) {
    taskbar_->Release();
    taskbar_ = nullptr;
  }
  if (sink_window_ != nullptr) {
    DestroyWindow(sink_window_);
    sink_window_ = nullptr;
  }
  if (instance_mutex_ != nullptr) {
    CloseHandle(instance_mutex_);
    instance_mutex_ = nullptr;
  }
}

void WindowsDesktopIntegrationVincentzyuPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(
      std::make_unique<WindowsDesktopIntegrationVincentzyuPlugin>(registrar));
}

void WindowsDesktopIntegrationVincentzyuPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method == "acquireSingleInstance") {
    result->Success(flutter::EncodableValue(TryClaimSingleInstance()));
    return;
  }

  const flutter::EncodableValue* call_arguments = call.arguments();
  const flutter::EncodableMap* arguments =
      call_arguments == nullptr
          ? nullptr
          : std::get_if<flutter::EncodableMap>(call_arguments);
  if (arguments == nullptr) {
    result->Error("invalid-arguments", "Expected a map of arguments.");
    return;
  }

  if (method == "setJumpList") {
    const flutter::EncodableValue* value = MapValue(*arguments, "entries");
    const flutter::EncodableList* entries =
        value == nullptr ? nullptr : std::get_if<flutter::EncodableList>(value);
    if (entries == nullptr) {
      result->Error("invalid-arguments", "Expected a list of entries.");
      return;
    }
    result->Success(flutter::EncodableValue(ApplyJumpList(*entries)));
    return;
  }

  if (method == "setThumbnailToolbar") {
    const flutter::EncodableValue* value = MapValue(*arguments, "buttons");
    const flutter::EncodableList* buttons =
        value == nullptr ? nullptr : std::get_if<flutter::EncodableList>(value);
    if (buttons == nullptr) {
      result->Error("invalid-arguments", "Expected a list of buttons.");
      return;
    }
    result->Success(flutter::EncodableValue(ApplyThumbnailToolbar(
        *buttons, StringValue(MapValue(*arguments, "activeId")))));
    return;
  }

  if (method == "showNotification") {
    const std::wstring title =
        WideFromUtf8(StringValue(MapValue(*arguments, "title")));
    const std::wstring body =
        WideFromUtf8(StringValue(MapValue(*arguments, "body")));
    if (title.empty() && body.empty()) {
      result->Error("invalid-arguments", "Expected notification text.");
      return;
    }
    result->Success(flutter::EncodableValue(ShowNotification(title, body)));
    return;
  }

  result->NotImplemented();
}

bool WindowsDesktopIntegrationVincentzyuPlugin::TryClaimSingleInstance() {
  if (instance_mutex_ != nullptr) {
    return true;
  }
  HANDLE mutex = CreateMutexW(nullptr, FALSE, kSingleInstanceMutex);
  if (mutex == nullptr) {
    // Never block the application because the guard itself failed.
    return true;
  }
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    CloseHandle(mutex);
    HWND primary = FindWindowW(kSinkWindowClass, nullptr);
    if (primary == nullptr) {
      // The other instance is already shutting down; start normally.
      return true;
    }
    SendCommandLineToPrimary(primary);
    return false;
  }
  instance_mutex_ = mutex;
  EnsureSinkWindow();
  return true;
}

void WindowsDesktopIntegrationVincentzyuPlugin::SendCommandLineToPrimary(HWND sink) {
  // Hand the foreground right to the primary instance. Without it Windows
  // silently drops the raise that the forwarded request triggers, because this
  // process, not the shell, is the one asking.
  DWORD primary_process = 0;
  GetWindowThreadProcessId(sink, &primary_process);
  if (primary_process != 0) {
    AllowSetForegroundWindow(primary_process);
  }
  const std::wstring arguments = CommandLineArguments();
  COPYDATASTRUCT data = {};
  data.dwData = kCopyDataCommandLine;
  data.cbData = static_cast<DWORD>((arguments.size() + 1u) * sizeof(wchar_t));
  data.lpData = const_cast<wchar_t*>(arguments.c_str());
  SendMessageTimeoutW(sink, WM_COPYDATA,
                      static_cast<WPARAM>(GetCurrentProcessId()),
                      reinterpret_cast<LPARAM>(&data), SMTO_ABORTIFHUNG, 2000,
                      nullptr);
}

void WindowsDesktopIntegrationVincentzyuPlugin::EnsureSinkWindow() {
  if (sink_window_ != nullptr) {
    return;
  }
  WNDCLASSEXW window_class = {};
  window_class.cbSize = sizeof(WNDCLASSEXW);
  window_class.lpfnWndProc = &WindowsDesktopIntegrationVincentzyuPlugin::SinkWindowProc;
  window_class.hInstance = GetModuleHandleW(nullptr);
  window_class.lpszClassName = kSinkWindowClass;
  if (RegisterClassExW(&window_class) == 0 &&
      GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
    return;
  }
  sink_window_ = CreateWindowExW(0, kSinkWindowClass, kSinkWindowClass, WS_POPUP,
                                 0, 0, 0, 0, nullptr, nullptr,
                                 window_class.hInstance, this);
  // The copy that forwards a jump list command is a plain process of the
  // interactive user, so it never runs with the rights of this instance.
  AllowMessageFromLowerIntegrity(sink_window_, WM_COPYDATA);
}

LRESULT CALLBACK WindowsDesktopIntegrationVincentzyuPlugin::SinkWindowProc(
    HWND window,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  if (message == WM_NCCREATE) {
    // The window procedure is reached before the constructor stores the window
    // handle, so the owner has to be picked up from the creation parameters.
    const auto* create = reinterpret_cast<const CREATESTRUCTW*>(lparam);
    SetWindowLongPtrW(window, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(create == nullptr
                                                     ? nullptr
                                                     : create->lpCreateParams));
    return DefWindowProcW(window, message, wparam, lparam);
  }
  if (message == WM_COPYDATA) {
    auto* plugin = reinterpret_cast<WindowsDesktopIntegrationVincentzyuPlugin*>(
        GetWindowLongPtrW(window, GWLP_USERDATA));
    const auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
    if (plugin != nullptr && data != nullptr) {
      plugin->HandleSinkCopyData(*data);
    }
    return TRUE;
  }
  if (message == kTrayCallbackMessage) {
    auto* plugin = reinterpret_cast<WindowsDesktopIntegrationVincentzyuPlugin*>(
        GetWindowLongPtrW(window, GWLP_USERDATA));
    if (plugin != nullptr) {
      switch (LOWORD(lparam)) {
        case NIN_BALLOONUSERCLICK:
          // Clicking the balloon repeats the request that raised it.
          plugin->ActivateWindow();
          plugin->RemoveTrayIcon();
          break;
        case NIN_BALLOONHIDE:
        case NIN_BALLOONTIMEOUT:
          plugin->RemoveTrayIcon();
          break;
        default:
          break;
      }
    }
    return 0;
  }
  if (message == WM_TIMER && wparam == kTrayTimerId) {
    auto* plugin = reinterpret_cast<WindowsDesktopIntegrationVincentzyuPlugin*>(
        GetWindowLongPtrW(window, GWLP_USERDATA));
    if (plugin != nullptr) {
      plugin->RemoveTrayIcon();
    }
    return 0;
  }
  return DefWindowProcW(window, message, wparam, lparam);
}

void WindowsDesktopIntegrationVincentzyuPlugin::HandleSinkCopyData(
    const COPYDATASTRUCT& data) {
  if (data.dwData != kCopyDataCommandLine || data.lpData == nullptr ||
      data.cbData < sizeof(wchar_t)) {
    return;
  }
  const size_t character_count =
      static_cast<size_t>(data.cbData) / sizeof(wchar_t);
  std::vector<wchar_t> buffer(character_count);
  std::memcpy(buffer.data(), data.lpData, character_count * sizeof(wchar_t));
  const std::wstring payload(buffer.data(), character_count);
  const std::wstring command_line(payload.c_str());

  // A forwarded launch means the user picked a destination in the shell, so the
  // window has to come back to the front before the request is applied.
  ActivateWindow();

  flutter::EncodableList arguments;
  arguments.emplace_back(flutter::EncodableValue(Utf8FromWide(command_line)));
  flutter::EncodableMap event;
  event[flutter::EncodableValue("type")] = flutter::EncodableValue("launch");
  event[flutter::EncodableValue("arguments")] =
      flutter::EncodableValue(std::move(arguments));
  EmitEvent(std::move(event));
}

HWND WindowsDesktopIntegrationVincentzyuPlugin::FlutterWindowHandle() {
  if (flutter_window_ != nullptr) {
    return flutter_window_;
  }
  if (registrar_ == nullptr) {
    return nullptr;
  }
  HWND view_window = nullptr;
  flutter::FlutterView* view = registrar_->GetView();
  if (view != nullptr) {
    view_window = view->GetNativeWindow();
  }
  if (view_window == nullptr) {
    // The implicit view is always view zero.
    std::shared_ptr<flutter::FlutterView> fallback = registrar_->GetViewById(0);
    if (fallback != nullptr) {
      view_window = fallback->GetNativeWindow();
    }
  }
  if (view_window == nullptr) {
    return nullptr;
  }
  // A view exposes the child window it renders into, while the taskbar APIs
  // only accept the top level window that owns the taskbar button.
  flutter_window_ = GetAncestor(view_window, GA_ROOT);
  // The taskbar delivers a hover button click as a WM_COMMAND to this window.
  AllowMessageFromLowerIntegrity(flutter_window_, WM_COMMAND);
  return flutter_window_;
}

void WindowsDesktopIntegrationVincentzyuPlugin::ActivateWindow() {
  HWND window = FlutterWindowHandle();
  if (window == nullptr) {
    return;
  }
  if (IsIconic(window)) {
    ShowWindow(window, SW_RESTORE);
  } else if (!IsWindowVisible(window)) {
    ShowWindow(window, SW_SHOW);
  }
  BringWindowToTop(window);
  SetForegroundWindow(window);
  if (GetForegroundWindow() == window) {
    return;
  }

  // Windows drops the focus request when the caller does not own the input
  // queue of the current foreground window. Sharing that queue lifts the
  // restriction, so the request is retried once from the owning thread.
  const DWORD owner = GetWindowThreadProcessId(GetForegroundWindow(), nullptr);
  const DWORD current = GetCurrentThreadId();
  if (owner != 0 && owner != current &&
      AttachThreadInput(current, owner, TRUE)) {
    BringWindowToTop(window);
    SetForegroundWindow(window);
    AttachThreadInput(current, owner, FALSE);
    if (GetForegroundWindow() == window) {
      return;
    }
  }

  // Windows may still veto the request, for example while another application
  // runs in full screen mode. Flashing the taskbar button at least shows the
  // user where the desktop request landed.
  FLASHWINFO flash = {};
  flash.cbSize = sizeof(FLASHWINFO);
  flash.hwnd = window;
  flash.dwFlags = FLASHW_ALL | FLASHW_TIMERNOFG;
  FlashWindowEx(&flash);
}

HICON WindowsDesktopIntegrationVincentzyuPlugin::TrayIcon() {
  if (tray_icon_ != nullptr) {
    return tray_icon_;
  }
  const std::wstring executable = ExecutablePath();
  if (!executable.empty()) {
    HICON large = nullptr;
    if (ExtractIconExW(executable.c_str(), 0, &large, nullptr, 1) == 1 &&
        large != nullptr) {
      tray_icon_ = large;
      return tray_icon_;
    }
  }
  // The fallback is a shared system icon that the shell owns and that must
  // never be destroyed by this plugin.
  tray_icon_ = LoadIconW(nullptr, IDI_APPLICATION);
  tray_icon_shared_ = true;
  return tray_icon_;
}

void WindowsDesktopIntegrationVincentzyuPlugin::RemoveTrayIcon() {
  if (sink_window_ != nullptr) {
    KillTimer(sink_window_, kTrayTimerId);
    if (tray_icon_added_) {
      NOTIFYICONDATAW data = {};
      data.cbSize = sizeof(NOTIFYICONDATAW);
      data.hWnd = sink_window_;
      data.uID = kTrayIconId;
      Shell_NotifyIconW(NIM_DELETE, &data);
    }
  }
  tray_icon_added_ = false;
  if (tray_icon_ != nullptr && !tray_icon_shared_) {
    DestroyIcon(tray_icon_);
  }
  tray_icon_ = nullptr;
  tray_icon_shared_ = false;
}

bool WindowsDesktopIntegrationVincentzyuPlugin::ShowNotification(
    const std::wstring& title, const std::wstring& body) {
  EnsureSinkWindow();
  if (sink_window_ == nullptr) {
    return false;
  }

  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(NOTIFYICONDATAW);
  data.hWnd = sink_window_;
  data.uID = kTrayIconId;
  if (!tray_icon_added_) {
    data.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE;
    data.uCallbackMessage = kTrayCallbackMessage;
    data.hIcon = TrayIcon();
    wcsncpy_s(data.szTip, kAppDisplayName, _TRUNCATE);
    if (data.hIcon == nullptr || !Shell_NotifyIconW(NIM_ADD, &data)) {
      RemoveTrayIcon();
      return false;
    }
    tray_icon_added_ = true;
  }

  // Windows 10 and 11 render this balloon as a notification and keep it in the
  // notification centre, so an unpackaged build reaches the user exactly like a
  // packaged one would through the WinRT toast APIs.
  data.uFlags = NIF_INFO;
  data.dwInfoFlags = NIIF_INFO;
  wcsncpy_s(data.szInfoTitle, title.c_str(), _TRUNCATE);
  wcsncpy_s(data.szInfo, body.c_str(), _TRUNCATE);
  if (!Shell_NotifyIconW(NIM_MODIFY, &data)) {
    RemoveTrayIcon();
    return false;
  }
  SetTimer(sink_window_, kTrayTimerId, kTrayLifetimeMs, nullptr);
  return true;
}

bool WindowsDesktopIntegrationVincentzyuPlugin::ApplyJumpList(
    const flutter::EncodableList& entries) {
  const std::wstring executable = ExecutablePath();
  if (executable.empty()) {
    return false;
  }
  ComRef<ICustomDestinationList> destinations;
  if (FAILED(CoCreateInstance(CLSID_DestinationList, nullptr,
                              CLSCTX_INPROC_SERVER, IID_ICustomDestinationList,
                              destinations.PutVoid()))) {
    return false;
  }
  UINT minimum_slots = 0;
  ComRef<IObjectArray> removed;
  if (FAILED(destinations->BeginList(&minimum_slots, IID_IObjectArray,
                                     removed.PutVoid()))) {
    return false;
  }
  ComRef<IObjectCollection> collection;
  if (FAILED(CoCreateInstance(CLSID_EnumerableObjectCollection, nullptr,
                              CLSCTX_INPROC_SERVER, IID_IObjectCollection,
                              collection.PutVoid()))) {
    destinations->AbortList();
    return false;
  }

  bool complete = true;
  for (const flutter::EncodableValue& value : entries) {
    const flutter::EncodableMap* entry =
        std::get_if<flutter::EncodableMap>(&value);
    if (entry == nullptr) {
      continue;
    }
    const std::wstring title =
        WideFromUtf8(StringValue(MapValue(*entry, "label")));
    const std::wstring arguments =
        WideFromUtf8(StringValue(MapValue(*entry, "arguments")));
    const std::wstring icon_path =
        WideFromUtf8(StringValue(MapValue(*entry, "iconPath")));
    if (!AppendJumpListEntry(collection.Get(), executable, title, arguments,
                             icon_path)) {
      complete = false;
    }
  }

  if (!complete ||
      FAILED(destinations->AppendCategory(kJumpListCategory,
                                          collection.Get()))) {
    destinations->AbortList();
    return false;
  }
  return SUCCEEDED(destinations->CommitList());
}

bool WindowsDesktopIntegrationVincentzyuPlugin::ApplyThumbnailToolbar(
    const flutter::EncodableList& buttons,
    const std::string& active_id) {
  HWND window = FlutterWindowHandle();
  if (window == nullptr) {
    return false;
  }
  if (taskbar_ == nullptr) {
    if (FAILED(CoCreateInstance(CLSID_TaskbarList, nullptr,
                                CLSCTX_INPROC_SERVER, IID_ITaskbarList3,
                                reinterpret_cast<void**>(&taskbar_)))) {
      taskbar_ = nullptr;
      return false;
    }
    if (FAILED(taskbar_->HrInit())) {
      taskbar_->Release();
      taskbar_ = nullptr;
      return false;
    }
  }

  const size_t count = std::min(buttons.size(), kThumbnailButtonLimit);
  if (count == 0) {
    return false;
  }
  std::vector<THUMBBUTTON> items(count);
  std::vector<HICON> icons(count, nullptr);
  std::vector<std::string> ids(count);
  std::vector<std::wstring> tips(count);
  for (size_t index = 0; index < count; ++index) {
    const flutter::EncodableMap* button =
        std::get_if<flutter::EncodableMap>(&buttons[index]);
    if (button == nullptr) {
      DestroyIcons(icons);
      return false;
    }
    ids[index] = StringValue(MapValue(*button, "id"));
    tips[index] = WideFromUtf8(StringValue(MapValue(*button, "label")));
    const bool enabled = BoolValue(MapValue(*button, "enabled"), true);
    const int64_t width = IntValue(MapValue(*button, "width"), 0);
    const int64_t height = IntValue(MapValue(*button, "height"), 0);
    const std::vector<uint8_t>* pixels =
        ByteListValue(MapValue(*button, "icon"));
    if (pixels != nullptr) {
      icons[index] = CreateIconFromRgba(static_cast<int32_t>(width),
                                        static_cast<int32_t>(height), *pixels);
    }

    THUMBBUTTON& item = items[index];
    item.dwMask =
        static_cast<THUMBBUTTONMASK>(THB_ICON | THB_TOOLTIP | THB_FLAGS);
    item.iId = static_cast<UINT>(index) + kThumbnailButtonIdBase;
    item.hIcon = icons[index];
    item.dwFlags =
        (enabled && ids[index] != active_id) ? THBF_ENABLED : THBF_DISABLED;
    wcsncpy_s(item.szTip, tips[index].c_str(), _TRUNCATE);
  }

  const UINT button_count = static_cast<UINT>(count);
  const HRESULT result =
      thumbnail_buttons_created_
          ? taskbar_->ThumbBarUpdateButtons(window, button_count, items.data())
          : taskbar_->ThumbBarAddButtons(window, button_count, items.data());
  if (FAILED(result)) {
    DestroyIcons(icons);
    return false;
  }

  thumbnail_buttons_created_ = true;
  thumbnail_button_ids_ = ids;
  DestroyIcons(thumbnail_icons_);
  thumbnail_icons_ = std::move(icons);
  return true;
}

std::optional<LRESULT> WindowsDesktopIntegrationVincentzyuPlugin::HandleWindowProc(
    HWND window,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  if (message != WM_COMMAND || HIWORD(wparam) != THBN_CLICKED) {
    return std::nullopt;
  }
  const UINT button_id = LOWORD(wparam);
  if (button_id < kThumbnailButtonIdBase) {
    return std::nullopt;
  }
  const size_t index = static_cast<size_t>(button_id - kThumbnailButtonIdBase);
  if (index >= thumbnail_button_ids_.size()) {
    return std::nullopt;
  }

  flutter::EncodableMap event;
  event[flutter::EncodableValue("type")] = flutter::EncodableValue("command");
  event[flutter::EncodableValue("id")] =
      flutter::EncodableValue(thumbnail_button_ids_[index]);
  // The click came from the taskbar, which does not raise the window itself.
  ActivateWindow();
  EmitEvent(std::move(event));
  // The shell keeps ownership of the message, so never swallow it.
  return std::nullopt;
}

void WindowsDesktopIntegrationVincentzyuPlugin::EmitEvent(flutter::EncodableMap event) {
  if (sink_slot_ == nullptr) {
    return;
  }
  flutter::EventSink<flutter::EncodableValue>* sink = sink_slot_->sink();
  if (sink == nullptr) {
    return;
  }
  const flutter::EncodableValue value(std::move(event));
  sink->Success(value);
}

}  // namespace windows_desktop_integration_vincentzyu
