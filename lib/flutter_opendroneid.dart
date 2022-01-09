import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_opendroneid/models/odid_message.dart';

import 'models/enums.dart';
import 'models/message_pack.dart';

class FlutterOpenDroneId {
  static const _methodChannel = const MethodChannel('flutter_odid');
  static const _messagesEventChannel =
      const EventChannel('flutter_odid_messages');
  static const _btStateEventChannel =
      const EventChannel('flutter_odid_bt_state');
  static const _scanStateEventChannel =
      const EventChannel('flutter_odid_scan_state');

  static Map<String, MessagePack> _storedPacks = {};
  static final _packController = StreamController<MessagePack>.broadcast();
  static StreamSubscription? _messagesSubscription;

  static Stream<BluetoothState> get bluetoothState async* {
    yield BluetoothState
        .values[await _methodChannel.invokeMethod('bluetooth_state')];
    yield* _btStateEventChannel
        .receiveBroadcastStream()
        .asyncMap((event) => BluetoothState.values[event]);
  }

  static Stream<MessagePack> get allMessages => _packController.stream;

  static Stream<bool> get isScanningStream => _scanStateEventChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  /// Starts scanning for nearby traffic
  ///
  /// To further receive data, listen to [basicIdMessages] or [locationMessages]
  /// streams.
  static Future<void> startScan() async {
    _messagesSubscription =
        _messagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = OdidMessage.fromMap(data);
      if (message == null) return;
      _updatePacks(message);
    });
    await _methodChannel.invokeMethod('start_scan');
  }

  /// Stops any currently running scan
  static Future<void> stopScan() async {
    await _methodChannel.invokeMethod('stop_scan');
    _messagesSubscription?.cancel();
  }

  static Future<void> enableAutoRestart({required bool enable}) async {
    await _methodChannel.invokeMethod('set_autorestart', {
      'enable': enable,
    });
  }

  static Future<bool> get isScanning async =>
      await _methodChannel.invokeMethod('is_scanning');

  static void _updatePacks(OdidMessage message) {
    final storedPack = _storedPacks[message.macAddress] ??
        MessagePack(macAddress: message.macAddress);
    _storedPacks[message.macAddress] = storedPack.updateWith(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }
}
