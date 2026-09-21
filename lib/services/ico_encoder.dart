import 'dart:typed_data';

/// One bitmap size of an ICO file.
class IcoFrame {
  const IcoFrame({required this.size, required this.rgba});

  /// Width and height of the frame in pixels.
  final int size;

  /// Premultiplied RGBA bytes, `size * size * 4` long.
  final Uint8List rgba;
}

/// Byte size of the `ICONDIR` structure.
const int _iconDirSize = 6;

/// Byte size of one `ICONDIRENTRY` structure.
const int _iconDirEntrySize = 16;

/// Byte size of a `BITMAPINFOHEADER`, the header of a BMP image.
const int _bmpHeaderSize = 40;

/// Encodes premultiplied RGBA frames into an `.ico` file.
///
/// Windows reads a jump list icon straight out of this file, and the shell only
/// understands the classic layout: an `ICONDIR`, one directory entry per size,
/// and a 32bpp `BITMAPINFOHEADER` frame per size. PNG frames are silently
/// ignored, which makes Explorer fall back to the icon of the executable.
///
/// Callers pass the frames largest first.
Uint8List encodeIco(List<IcoFrame> frames) {
  if (frames.isEmpty) {
    throw ArgumentError.value(frames, 'frames', 'needs at least one frame');
  }
  final List<_EncodedFrame> encoded =
      frames.map(_encodeFrame).toList(growable: false);

  int offset = _iconDirSize + encoded.length * _iconDirEntrySize;
  for (final _EncodedFrame frame in encoded) {
    frame.offset = offset;
    offset += frame.bytes.length;
  }

  final BytesBuilder builder = BytesBuilder(copy: false);
  final ByteData directory = ByteData(_iconDirSize);
  directory.setUint16(0, 0, Endian.little); // Reserved.
  directory.setUint16(2, 1, Endian.little); // Type: icon.
  directory.setUint16(4, encoded.length, Endian.little);
  builder.add(directory.buffer.asUint8List());

  for (final _EncodedFrame frame in encoded) {
    final ByteData entry = ByteData(_iconDirEntrySize);
    // Zero is how the format spells a 256 pixel dimension.
    final int dimension = frame.size >= 256 ? 0 : frame.size;
    entry.setUint8(0, dimension);
    entry.setUint8(1, dimension);
    entry.setUint8(2, 0); // Palette size, unused at 32 bits per pixel.
    entry.setUint8(3, 0); // Reserved.
    entry.setUint16(4, 1, Endian.little); // Colour planes.
    entry.setUint16(6, 32, Endian.little); // Bits per pixel.
    entry.setUint32(8, frame.bytes.length, Endian.little);
    entry.setUint32(12, frame.offset, Endian.little);
    builder.add(entry.buffer.asUint8List());
  }

  for (final _EncodedFrame frame in encoded) {
    builder.add(frame.bytes);
  }
  return builder.toBytes();
}

/// Encodes one frame as a BMP image with an alpha channel and a mask.
_EncodedFrame _encodeFrame(IcoFrame frame) {
  final int size = frame.size;
  if (size <= 0 || size > 256) {
    throw ArgumentError.value(size, 'frame.size', 'must be 1 to 256');
  }
  final int pixels = size * size * 4;
  if (frame.rgba.length < pixels) {
    throw ArgumentError.value(
      frame.rgba.length,
      'frame.rgba',
      'needs $pixels bytes for a $size pixel frame',
    );
  }

  // A 1bpp row is padded to a whole number of 4 byte DWORDs.
  final int maskStride = ((size + 31) >> 5) << 2;
  final Uint8List bytes =
      Uint8List(_bmpHeaderSize + pixels + maskStride * size);
  final ByteData header = ByteData.sublistView(bytes);
  header.setUint32(0, _bmpHeaderSize, Endian.little);
  header.setInt32(4, size, Endian.little);
  // Doubling the height is what tells the shell the frame carries alpha.
  header.setInt32(8, size * 2, Endian.little);
  header.setUint16(12, 1, Endian.little);
  header.setUint16(14, 32, Endian.little);
  header.setUint32(16, 0, Endian.little); // BI_RGB.
  header.setUint32(20, pixels, Endian.little);

  final int maskBase = _bmpHeaderSize + pixels;
  for (int row = 0; row < size; row++) {
    // BMP rows are stored bottom up.
    final int source = (size - 1 - row) * size * 4;
    final int target = _bmpHeaderSize + row * size * 4;
    final int maskRow = maskBase + row * maskStride;
    for (int column = 0; column < size; column++) {
      final int rgba = source + column * 4;
      final int alpha = frame.rgba[rgba + 3];
      // Flutter hands out premultiplied pixels, BMP frames are straight.
      bytes[target + column * 4] = _straighten(frame.rgba[rgba + 2], alpha);
      bytes[target + column * 4 + 1] =
          _straighten(frame.rgba[rgba + 1], alpha);
      bytes[target + column * 4 + 2] = _straighten(frame.rgba[rgba], alpha);
      bytes[target + column * 4 + 3] = alpha;
      if (alpha < 128) {
        bytes[maskRow + (column >> 3)] |= 0x80 >> (column & 7);
      }
    }
  }
  return _EncodedFrame(size, bytes);
}

/// Reverses the premultiplication of one colour channel.
int _straighten(int channel, int alpha) {
  if (alpha == 0) {
    return 0;
  }
  if (alpha == 255) {
    return channel;
  }
  final int value = (channel * 255 + (alpha >> 1)) ~/ alpha;
  return value > 255 ? 255 : value;
}

/// A frame together with the file offset it is written to.
class _EncodedFrame {
  _EncodedFrame(this.size, this.bytes);

  final int size;
  final Uint8List bytes;
  int offset = 0;
}
