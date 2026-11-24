import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

/// Writes the raw Remote ID frames of a scanning session as a RIDF file.
///
/// RIDF is a small binary record format (one record per received frame:
/// transport, receive time, RSSI, transmitter address and the raw message
/// or message pack) that Remote ID analysis tools can read directly, so a
/// capture can be shared without losing the information the decoded
/// messages drop. The byte layout is documented at
/// https://github.com/Mattbusel/remoteid/blob/main/docs/ridf.md
///
/// Feed it the payloads from [FlutterOpenDroneId.rawMessages]:
///
/// ```
/// final writer = await RidfWriter.open(File('capture.ridf'));
/// final subscription =
///     FlutterOpenDroneId.rawMessages.listen(writer.log);
/// // ... scan ...
/// await subscription.cancel();
/// await writer.close();
/// ```
class RidfWriter {
  // Transport codes, matching the transports this plugin receives.
  static const int transportBt4 = 1;
  static const int transportBt5 = 2;
  static const int transportWifiBeacon = 3;
  static const int transportWifiNan = 4;

  static const int _flagRssi = 0x01;
  static const int _flagAddress = 0x08;

  // ODIDPayload.receivedTimestamp is epoch-based on both platforms
  // (System.currentTimeMillis() on Android, timeIntervalSince1970 on iOS),
  // so records are marked as UTC.
  static const int _flagUtc = 0x10;

  static final Uint8List _fileHeader =
      Uint8List.fromList([0x52, 0x49, 0x44, 0x46, 0, 0, 0, 0]); // "RIDF", v0
  static const int _fixedSize = 36;

  final IOSink _sink;
  final ByteData _fixed = ByteData(_fixedSize);

  RidfWriter._(this._sink);

  /// Opens [file] for writing and writes the RIDF file header.
  static Future<RidfWriter> open(File file) async {
    final sink = file.openWrite();
    sink.add(_fileHeader);
    return RidfWriter._(sink);
  }

  /// Maps the message source of a payload to a RIDF transport code.
  static int transportOf(pigeon.MessageSource source) {
    switch (source) {
      case pigeon.MessageSource.BluetoothLegacy:
        return transportBt4;
      case pigeon.MessageSource.BluetoothLongRange:
        return transportBt5;
      case pigeon.MessageSource.WifiBeacon:
        return transportWifiBeacon;
      case pigeon.MessageSource.WifiNan:
        return transportWifiNan;
      case pigeon.MessageSource.Unknown:
        return 0;
    }
  }

  /// Appends one received frame. [payload] is the payload as delivered by
  /// [FlutterOpenDroneId.rawMessages]: rawData is the Remote ID message or
  /// message pack, header byte first, at most 255 bytes; receivedTimestamp
  /// is in milliseconds since the Unix epoch. Payloads without data are
  /// skipped.
  void log(pigeon.ODIDPayload payload) {
    final data = payload.rawData;
    if (data.isEmpty || data.length > 255) return;

    final address = parseMac(payload.metadata.macAddress);
    final rssi = payload.metadata.rssi;

    var flags = _flagUtc;
    if (rssi != null) flags |= _flagRssi;
    if (address != null) flags |= _flagAddress;

    _fixed.setUint16(0, _fixedSize - 2 + data.length, Endian.little);
    _fixed.setUint8(2, 0); // RIDF version
    _fixed.setUint8(3, transportOf(payload.metadata.source));
    _fixed.setUint8(4, flags);
    _fixed.setUint8(5, 0); // message counter not recorded
    _fixed.setUint64(6, payload.receivedTimestamp * 1000000, Endian.little);
    _fixed.setInt8(14, rssi ?? 0);
    _fixed.setUint8(15, data.length);
    for (var i = 0; i < 6; i++) {
      _fixed.setUint8(16 + i, address != null ? address[i] : 0);
    }
    _fixed.setUint16(22, 0, Endian.little); // receiver id
    _fixed.setInt32(24, 0, Endian.little); // receiver latitude
    _fixed.setInt32(28, 0, Endian.little); // receiver longitude
    _fixed.setInt32(32, 0, Endian.little); // receiver altitude

    _sink.add(_fixed.buffer.asUint8List());
    _sink.add(data);
  }

  /// Flushes and closes the underlying file.
  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }

  /// Parses "AA:BB:CC:DD:EE:FF" into 6 bytes in text order; null on
  /// failure (for example the peripheral UUID iOS reports instead of a MAC).
  static Uint8List? parseMac(String? mac) {
    if (mac == null) return null;
    final parts = mac.split(':');
    if (parts.length != 6) return null;
    final out = Uint8List(6);
    for (var i = 0; i < 6; i++) {
      final byte = int.tryParse(parts[i], radix: 16);
      if (byte == null || byte < 0 || byte > 0xFF) return null;
      out[i] = byte;
    }
    return out;
  }
}
