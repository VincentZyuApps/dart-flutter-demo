#ifndef FLUTTER_PLUGIN_WINDOWS_DESKTOP_INTEGRATION_VINCENTZYU_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOWS_DESKTOP_INTEGRATION_VINCENTZYU_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <shobjidl.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace windows_desktop_integration_vincentzyu {

// Owns the event sink of the event channel.
//
// The plugin and the stream handler share this slot through a `shared_ptr` and
// a `weak_ptr`, so the handler cannot touch freed plugin memory when the two are
// destroyed in an unexpected order.
class EventSinkSlot;

// Windows taskbar integration: jump list, thumbnail toolbar, single instance.
class WindowsDesktopIntegrationVincentzyuPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit WindowsDesktopIntegrationVincentzyuPlugin(
      flutter::PluginRegistrarWindows* registrar);
  ~WindowsDesktopIntegrationVincentzyuPlugin() override;

  WindowsDesktopIntegrationVincentzyuPlugin(
      const WindowsDesktopIntegrationVincentzyuPlugin&) = delete;
  WindowsDesktopIntegrationVincentzyuPlugin& operator=(
      const WindowsDesktopIntegrationVincentzyuPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Claims the single instance mutex. Returns false when another instance owns
  // it and received this command line, so the caller should exit.
  bool TryClaimSingleInstance();

  bool ApplyJumpList(const flutter::EncodableList& entries);
  bool ApplyThumbnailToolbar(const flutter::EncodableList& buttons,
                             const std::string& active_id);

  // Raises the Flutter window for a request that came from the desktop shell.
  void ActivateWindow();

  // Shows the shell notification that reports an applied desktop request.
  bool ShowNotification(const std::wstring& title, const std::wstring& body);
  void RemoveTrayIcon();
  HICON TrayIcon();

  HWND FlutterWindowHandle();
  void EnsureSinkWindow();
  void SendCommandLineToPrimary(HWND sink);
  void HandleSinkCopyData(const COPYDATASTRUCT& data);
  void EmitEvent(flutter::EncodableMap event);

  std::optional<LRESULT> HandleWindowProc(HWND window,
                                          UINT message,
                                          WPARAM wparam,
                                          LPARAM lparam);
  static LRESULT CALLBACK SinkWindowProc(HWND window,
                                         UINT message,
                                         WPARAM wparam,
                                         LPARAM lparam);

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::shared_ptr<EventSinkSlot> sink_slot_;
  std::vector<std::string> thumbnail_button_ids_;
  std::vector<HICON> thumbnail_icons_;
  ITaskbarList3* taskbar_ = nullptr;
  HANDLE instance_mutex_ = nullptr;
  HWND sink_window_ = nullptr;
  HWND flutter_window_ = nullptr;
  int window_proc_delegate_id_ = 0;
  bool thumbnail_buttons_created_ = false;
  HICON tray_icon_ = nullptr;
  bool tray_icon_added_ = false;
  // True while the tray icon is a shared system icon that must not be freed.
  bool tray_icon_shared_ = false;
};

}  // namespace windows_desktop_integration_vincentzyu

#endif  // FLUTTER_PLUGIN_WINDOWS_DESKTOP_INTEGRATION_VINCENTZYU_PLUGIN_H_
