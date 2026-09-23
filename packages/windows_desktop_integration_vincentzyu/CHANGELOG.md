# Changelog

## 0.1.0

- Add a Windows jump list with application defined entries.
- Add a taskbar thumbnail toolbar that renders Flutter drawn glyphs and reports clicks.
- Add single instance forwarding so jump list and desktop entry actions reuse the running window.
- Degrade to a no-op on platforms without a taskbar implementation.
