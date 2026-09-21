import 'dart:typed_data';

import 'package:dart_flutter_demo/services/ico_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads a byte range of an encoded file.
Uint8List slice(Uint8List bytes, int start, int end) {
  return Uint8List.sublistView(bytes, start, end);
}

/// RGBA pixels of a square frame filled with one colour.
Uint8List pixels(int size, [List<int> rgba = const <int>[0, 0, 0, 0]]) {
  final Uint8List bytes = Uint8List(size * size * 4);
  for (int offset = 0; offset < bytes.length; offset += 4) {
    bytes.setRange(offset, offset + 4, rgba);
  }
  return bytes;
}

void main() {
  group('encodeIco', () {
    test('writes one directory entry per frame', () {
      final Uint8List bytes = encodeIco(<IcoFrame>[
        IcoFrame(size: 32, rgba: pixels(32)),
        IcoFrame(size: 16, rgba: pixels(16)),
      ]);
      final ByteData view = ByteData.sublistView(bytes);

      expect(view.getUint16(0, Endian.little), 0); // Reserved.
      expect(view.getUint16(2, Endian.little), 1); // Icon.
      expect(view.getUint16(4, Endian.little), 2);

      // A frame is a 40 byte BMP header, 32bpp pixels, and a 1bpp mask whose
      // rows are padded to whole DWORDs.
      const int frame16 = 40 + 16 * 16 * 4 + 4 * 16;
      const int frame32 = 40 + 32 * 32 * 4 + 4 * 32;
      expect(bytes.length, 6 + 2 * 16 + frame16 + frame32);

      expect(view.getUint8(6), 32);
      expect(view.getUint8(7), 32);
      expect(view.getUint8(8), 0); // Palette size.
      expect(view.getUint8(9), 0);
      expect(view.getUint16(10, Endian.little), 1);
      expect(view.getUint16(12, Endian.little), 32);
      expect(view.getUint32(14, Endian.little), frame32);
      expect(view.getUint32(18, Endian.little), 6 + 2 * 16);

      expect(view.getUint8(22), 16);
      expect(view.getUint8(23), 16);
      expect(view.getUint32(30, Endian.little), frame16);
      expect(view.getUint32(34, Endian.little), 6 + 2 * 16 + frame32);
    });

    test('spells a 256 pixel dimension as zero', () {
      final Uint8List bytes = encodeIco(<IcoFrame>[
        IcoFrame(size: 256, rgba: pixels(256)),
      ]);
      final ByteData view = ByteData.sublistView(bytes);

      expect(view.getUint8(6), 0);
      expect(view.getUint8(7), 0);
      // A 1bpp row of 256 pixels is padded to 32 bytes.
      expect(view.getUint32(14, Endian.little), 40 + 256 * 256 * 4 + 32 * 256);
    });

    test('writes bottom up BGRA pixels with straight alpha', () {
      final Uint8List rgba = Uint8List.fromList(<int>[
        128, 0, 0, 128, // Top left, premultiplied red.
        0, 0, 0, 0, // Top right, transparent.
        10, 20, 30, 255, // Bottom left.
        64, 64, 64, 128, // Bottom right, premultiplied grey.
      ]);
      final Uint8List bytes =
          encodeIco(<IcoFrame>[IcoFrame(size: 2, rgba: rgba)]);
      final ByteData view = ByteData.sublistView(bytes);

      const int frame = 22;
      expect(view.getUint32(frame, Endian.little), 40);
      expect(view.getInt32(frame + 4, Endian.little), 2);
      // A doubled height is what tells the shell the frame carries alpha.
      expect(view.getInt32(frame + 8, Endian.little), 4);
      expect(view.getUint16(frame + 12, Endian.little), 1);
      expect(view.getUint16(frame + 14, Endian.little), 32);
      expect(view.getUint32(frame + 16, Endian.little), 0); // BI_RGB.
      expect(view.getUint32(frame + 20, Endian.little), 16);

      // The bottom row of the image is stored first, and the premultiplied
      // red becomes a straight alpha red.
      expect(
        slice(bytes, frame + 40, frame + 48),
        <int>[30, 20, 10, 255, 128, 128, 128, 128],
      );
      expect(
        slice(bytes, frame + 48, frame + 56),
        <int>[0, 0, 255, 128, 0, 0, 0, 0],
      );

      // The mask marks the transparent pixels and pads its rows.
      expect(slice(bytes, frame + 56, frame + 60), <int>[0, 0, 0, 0]);
      expect(slice(bytes, frame + 60, frame + 64), <int>[0x40, 0, 0, 0]);
      expect(bytes.length, frame + 64);
    });

    test('packs mask bits left to right and pads the row', () {
      final Uint8List bytes =
          encodeIco(<IcoFrame>[IcoFrame(size: 16, rgba: pixels(16))]);
      const int mask = 22 + 40 + 16 * 16 * 4;

      // Sixteen transparent pixels fill two bytes, then two bytes of padding.
      expect(slice(bytes, mask, mask + 2), <int>[0xFF, 0xFF]);
      expect(slice(bytes, mask + 2, mask + 4), <int>[0, 0]);
    });

    test('rejects a frame list that cannot be encoded', () {
      expect(() => encodeIco(<IcoFrame>[]), throwsArgumentError);
      expect(
        () => encodeIco(<IcoFrame>[IcoFrame(size: 0, rgba: Uint8List(0))]),
        throwsArgumentError,
      );
      expect(
        () => encodeIco(<IcoFrame>[IcoFrame(size: 257, rgba: Uint8List(0))]),
        throwsArgumentError,
      );
      expect(
        () => encodeIco(<IcoFrame>[IcoFrame(size: 2, rgba: Uint8List(8))]),
        throwsArgumentError,
      );
    });
  });
}
