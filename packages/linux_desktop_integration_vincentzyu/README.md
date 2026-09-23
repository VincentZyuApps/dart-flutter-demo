# linux_desktop_integration_vincentzyu

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
KDE Plasma and GNOME Shell can surface those properties in their media controls, but MPRIS does not prescribe
where controls appear and does not guarantee taskbar-hover integration.

The D-Bus activation and MPRIS bridges degrade to `DesktopActivationRole.unavailable` when no session bus
is reachable, for example on Windows or in a sandbox without D-Bus access.
