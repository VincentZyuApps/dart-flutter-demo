/// Windows taskbar integration for Flutter applications.
///
/// The package exposes a jump list, a thumbnail toolbar, and single instance
/// forwarding. Every entry point degrades to a no-op when no taskbar
/// implementation is registered, so it is safe to call on any platform.
library;

export 'src/models.dart';
export 'src/taskbar_integration.dart';
export 'src/taskbar_integration_platform.dart';
