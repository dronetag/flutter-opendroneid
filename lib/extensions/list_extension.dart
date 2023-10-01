import 'dart:typed_data';

extension HexStringExtension on Uint8List {
  String toHexString() => map((byte) =>
          byte.toUnsigned(8).toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();
}
