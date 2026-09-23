# windows_desktop_integration_vincentzyu

Windows desktop integration for Flutter applications.

```dart
if (!await WindowsDesktopIntegration.acquireSingleInstance()) {
  exit(0);
}

await WindowsDesktopIntegration.setJumpList(entries);
await WindowsDesktopIntegration.setThumbnailToolbar(buttons, activeId: 'grid');
WindowsDesktopIntegration.events.listen(handleTaskbarEvent);
```

Three Windows taskbar capabilities are exposed, all of them optional and safe to call on other platforms
(they resolve to a no-op):

* **Jump list** - `setJumpList` writes an application defined category with `IShellLink` entries. Clicking an
  entry starts the executable with the entry arguments, and the single instance guard forwards those arguments
  to the running window.
* **Thumbnail toolbar** - `setThumbnailToolbar` shows up to seven buttons inside the taskbar hover preview.
  Buttons carry a Flutter rendered icon, because the repository treats `assets/icons/` as generated output and
  the SDK only accepts real icon bitmaps. Clicks arrive on `events` as `TaskbarEventType.command`.
* **Single instance** - `acquireSingleInstance` claims a named mutex and a message-only window. Later launches
  send their command line over `WM_COPYDATA` and the running instance receives it as `TaskbarEventType.launch`.

Notes:

* Windows truncates thumbnail toolbar buttons from the right when the taskbar is crowded, so keep the list short.
* The plugin skips `SetCurrentProcessExplicitAppUserModelID` inside packaged (MSIX) builds so the packaged
  identity stays intact.
