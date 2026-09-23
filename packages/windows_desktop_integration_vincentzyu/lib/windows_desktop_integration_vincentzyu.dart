/// Windows desktop integration for Flutter applications.
///
/// The package exposes a jump list, a thumbnail toolbar, and single instance
/// forwarding. Every entry point degrades to a no-op when no Windows desktop
/// implementation is registered, so it is safe to call on any platform.
library;

export 'src/models.dart';
export 'src/windows_desktop_integration.dart';
export 'src/windows_desktop_integration_platform.dart';
