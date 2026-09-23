# Changelog

## 0.1.0

- Add a D-Bus activation bus so a second launch hands its arguments to the running instance.
- Add an MPRIS media player bridge so desktop environments can render the current page in their taskbar hover tooltip and media controls.
- Keep every call best effort: a missing session bus degrades to "unavailable" instead of throwing.
