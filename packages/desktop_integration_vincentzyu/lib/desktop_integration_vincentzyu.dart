/// Linux desktop integration helpers for Flutter applications.
///
/// The package keeps two best-effort capabilities:
///
/// * [DesktopActivationClient] owns a session bus name so later launches can
///   hand their arguments to the running instance instead of opening a second
///   window.
/// * [MprisBridge] publishes MPRIS metadata and transport callbacks so desktop
///   environments can render them in taskbar hover tooltips and media controls.
library;

export 'src/activation_client.dart';
export 'src/mpris/mpris_bridge.dart';
export 'src/mpris/mpris_media_player_object.dart';
export 'src/mpris/now_playing_state.dart';
