# desktop_integration_vincentzyu

Linux desktop integration helpers for Flutter applications.

```dart
final activation = DesktopActivationClient();
final role = await activation.acquireSingleInstance(arguments: args);
if (role == DesktopActivationRole.secondary) {
  exit(0);
}
activation.activations.listen(handleArguments);
```

`DesktopActivationClient` owns a well known session bus name. The first process keeps the name and serves an
`Activate(as)` method, every later process calls that method with its own arguments and exits, so a taskbar
action or a desktop entry action reuses the running window instead of opening a second one.

`MprisBridge` publishes the `org.mpris.MediaPlayer2` and `org.mpris.MediaPlayer2.Player` interfaces.
KDE Plasma renders those properties inside the taskbar hover tooltip (cover art, title, transport buttons)
and GNOME Shell lists them in its media controls, which is the only way a non-native toolkit can put content
into a desktop environment hover preview.

The package never imports Flutter, so it also works from plain Dart. Calls degrade to
`DesktopActivationRole.unavailable` when no session bus is reachable, for example on Windows or in a
sandbox without D-Bus access.
