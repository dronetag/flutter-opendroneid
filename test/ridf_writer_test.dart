import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_opendroneid/pigeon.dart' as pigeon;
import 'package:flutter_opendroneid/utils/ridf_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RidfWriter', () {
    test('parseMac parses colon separated addresses', () {
      expect(RidfWriter.parseMac('C0:01:02:03:04:05'),
          [0xC0, 0x01, 0x02, 0x03, 0x04, 0x05]);
      // iOS reports a peripheral UUID instead of a MAC address
      expect(RidfWriter.parseMac('3B3B4E6F-2F4C-4B0F-9F6E-3F8B2F0F4A11'),
          isNull);
      expect(RidfWriter.parseMac('C0:01:02:03:04'), isNull);
      expect(RidfWriter.parseMac('ZZ:01:02:03:04:05'), isNull);
      expect(RidfWriter.parseMac(null), isNull);
    });

    test('transportOf maps message sources to RIDF transport codes', () {
      expect(
          RidfWriter.transportOf(pigeon.MessageSource.BluetoothLegacy), 1);
      expect(RidfWriter.transportOf(pigeon.MessageSource.BluetoothLongRange),
          2);
      expect(RidfWriter.transportOf(pigeon.MessageSource.WifiBeacon), 3);
      expect(RidfWriter.transportOf(pigeon.MessageSource.WifiNan), 4);
      expect(RidfWriter.transportOf(pigeon.MessageSource.Unknown), 0);
    });

    test('writes a RIDF file with one record per payload', () async {
      final file =
          File('${Directory.systemTemp.path}/ridf_writer_test.ridf');
      if (file.existsSync()) file.deleteSync();

      final writer = await RidfWriter.open(file);
      writer.log(pigeon.ODIDPayload(
        rawData: Uint8List.fromList(List.generate(25, (i) => i)),
        receivedTimestamp: 1794916800000, // epoch milliseconds
        metadata: pigeon.ODIDMetadata(
          macAddress: 'C0:01:02:03:04:05',
          source: pigeon.MessageSource.BluetoothLegacy,
          rssi: -71,
        ),
      ));
      writer.log(pigeon.ODIDPayload(
        rawData: Uint8List.fromList(List.generate(250, (i) => i % 256)),
        receivedTimestamp: 1794916800123,
        metadata: pigeon.ODIDMetadata(
          // no RSSI, and an iOS-style UUID that is not a MAC address
          macAddress: '3B3B4E6F-2F4C-4B0F-9F6E-3F8B2F0F4A11',
          source: pigeon.MessageSource.WifiNan,
        ),
      ));
      // empty payloads are skipped
      writer.log(pigeon.ODIDPayload(
        rawData: Uint8List(0),
        receivedTimestamp: 1794916800200,
        metadata: pigeon.ODIDMetadata(
          macAddress: 'C0:01:02:03:04:05',
          source: pigeon.MessageSource.Unknown,
        ),
      ));
      await writer.close();

      final bytes = file.readAsBytesSync();
      // header, 36 + 25 record, 36 + 250 record
      expect(bytes.length, 8 + 61 + 286);
      expect(bytes.sublist(0, 8),
          [0x52, 0x49, 0x44, 0x46, 0, 0, 0, 0]); // "RIDF", version 0

      final first = ByteData.sublistView(bytes, 8, 8 + 61);
      expect(first.getUint16(0, Endian.little), 59); // record length
      expect(first.getUint8(2), 0); // RIDF version
      expect(first.getUint8(3), 1); // transport BT4
      expect(first.getUint8(4), 0x01 | 0x08 | 0x10); // RSSI + address + UTC
      expect(first.getUint64(6, Endian.little), 1794916800000 * 1000000);
      expect(first.getInt8(14), -71);
      expect(first.getUint8(15), 25);
      expect(
          List.generate(6, (i) => first.getUint8(16 + i)),
          [0xC0, 0x01, 0x02, 0x03, 0x04, 0x05]);
      expect(bytes.sublist(8 + 36, 8 + 61), List.generate(25, (i) => i));

      final second = ByteData.sublistView(bytes, 8 + 61, 8 + 61 + 36);
      expect(second.getUint16(0, Endian.little), 284);
      expect(second.getUint8(3), 4); // transport Wi-Fi NAN
      expect(second.getUint8(4), 0x10); // UTC only
      expect(second.getUint64(6, Endian.little), 1794916800123 * 1000000);
      expect(second.getInt8(14), 0);
      expect(second.getUint8(15), 250);

      file.deleteSync();
    });
  });
}
