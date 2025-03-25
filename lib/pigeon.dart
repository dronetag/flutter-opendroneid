// Autogenerated from Pigeon (v10.1.6), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

/// Higher priority drains battery but receives more data
enum ScanPriority {
  High,
  Low,
}

/// ODID Message Source
enum MessageSource {
  BluetoothLegacy,
  BluetoothLongRange,
  WifiNan,
  WifiBeacon,
  Unknown,
}

/// State of the Bluetooth adapter
enum BluetoothState {
  Unknown,
  Resetting,
  Unsupported,
  Unauthorized,
  PoweredOff,
  PoweredOn,
}

/// State of the Wifi adapter
enum WifiState {
  Disabling,
  Disabled,
  Enabling,
  Enabled,
}

enum BluetoothPhy {
  None,
  Phy1M,
  Phy2M,
  PhyLECoded,
  Unknown,
}

class ODIDMetadata {
  ODIDMetadata({
    required this.macAddress,
    required this.source,
    this.rssi,
    this.btName,
    this.frequency,
    this.centerFreq0,
    this.centerFreq1,
    this.channelWidthMhz,
    this.primaryPhy,
    this.secondaryPhy,
  });

  String macAddress;

  MessageSource source;

  int? rssi;

  String? btName;

  int? frequency;

  int? centerFreq0;

  int? centerFreq1;

  int? channelWidthMhz;

  BluetoothPhy? primaryPhy;

  BluetoothPhy? secondaryPhy;

  Object encode() {
    return <Object?>[
      macAddress,
      source.index,
      rssi,
      btName,
      frequency,
      centerFreq0,
      centerFreq1,
      channelWidthMhz,
      primaryPhy?.index,
      secondaryPhy?.index,
    ];
  }

  static ODIDMetadata decode(Object result) {
    result as List<Object?>;
    return ODIDMetadata(
      macAddress: result[0]! as String,
      source: MessageSource.values[result[1]! as int],
      rssi: result[2] as int?,
      btName: result[3] as String?,
      frequency: result[4] as int?,
      centerFreq0: result[5] as int?,
      centerFreq1: result[6] as int?,
      channelWidthMhz: result[7] as int?,
      primaryPhy: result[8] != null
          ? BluetoothPhy.values[result[8]! as int]
          : null,
      secondaryPhy: result[9] != null
          ? BluetoothPhy.values[result[9]! as int]
          : null,
    );
  }
}

/// Payload send from native to dart contains raw data and metadata
class ODIDPayload {
  ODIDPayload({
    required this.rawData,
    required this.receivedTimestamp,
    required this.metadata,
  });

  Uint8List rawData;

  int receivedTimestamp;

  ODIDMetadata metadata;

  Object encode() {
    return <Object?>[
      rawData,
      receivedTimestamp,
      metadata.encode(),
    ];
  }

  static ODIDPayload decode(Object result) {
    result as List<Object?>;
    return ODIDPayload(
      rawData: result[0]! as Uint8List,
      receivedTimestamp: result[1]! as int,
      metadata: ODIDMetadata.decode(result[2]! as List<Object?>),
    );
  }
}

class Api {
  /// Constructor for [Api].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  Api({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = StandardMessageCodec();

  Future<void> startScanBluetooth() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.startScanBluetooth', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> startScanWifi() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.startScanWifi', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> stopScanBluetooth() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.stopScanBluetooth', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> stopScanWifi() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.stopScanWifi', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setBtScanPriority(ScanPriority arg_priority) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.setBtScanPriority', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_priority.index]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<bool> isScanningBluetooth() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.isScanningBluetooth', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  Future<bool> isScanningWifi() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.isScanningWifi', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  Future<int> bluetoothState() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.bluetoothState', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as int?)!;
    }
  }

  Future<int> wifiState() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.wifiState', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as int?)!;
    }
  }

  Future<bool> btExtendedSupported() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.btExtendedSupported', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  Future<int> btMaxAdvDataLen() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.btMaxAdvDataLen', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as int?)!;
    }
  }

  Future<bool> wifiNaNSupported() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.Api.wifiNaNSupported', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }
}

class _PayloadApiCodec extends StandardMessageCodec {
  const _PayloadApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is ODIDMetadata) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is ODIDPayload) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return ODIDMetadata.decode(readValue(buffer)!);
      case 129: 
        return ODIDPayload.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class PayloadApi {
  /// Constructor for [PayloadApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  PayloadApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _PayloadApiCodec();

  Future<ODIDPayload> buildPayload(Uint8List arg_rawData, int arg_receivedTimestamp, ODIDMetadata arg_metadata) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_opendroneid.PayloadApi.buildPayload', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_rawData, arg_receivedTimestamp, arg_metadata]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as ODIDPayload?)!;
    }
  }
}
