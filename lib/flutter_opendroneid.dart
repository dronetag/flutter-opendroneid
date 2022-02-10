import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_opendroneid/models/odid_message.dart';

import 'models/enums.dart';
import 'models/message_pack.dart';

import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

class FlutterOpenDroneId {
  static late pigeon.Api _api = pigeon.Api();

  static const _locationMessagesEventChannel =
      const EventChannel('flutter_location_messages');
  static const _operatorIDMessagesEventChannel =
      const EventChannel('flutter_operatorid_messages');
  static const _basicMessagesEventChannel =
      const EventChannel('flutter_basic_messages');
  static const _btStateEventChannel =
      const EventChannel('flutter_odid_bt_state');
  static const _scanStateEventChannel =
      const EventChannel('flutter_odid_scan_state');

  static Map<String, MessagePack> _storedPacks = {};
  static final _packController = StreamController<MessagePack>.broadcast();
  static StreamSubscription? _locationMessagesSubscription;
  static StreamSubscription? _basicMessagesSubscription;
  static StreamSubscription? _operatorIDMessagesSubscription;

  static Stream<BluetoothState> get bluetoothState async* {
    yield BluetoothState.values[await await _api.bluetoothState()];
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
    _locationMessagesSubscription =
        _locationMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.LocationMessage.decode(data);
      if (message == null) return;
      _updatePacksWithLocation(message);
    });
    _basicMessagesSubscription =
        _basicMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.BasicIdMessage.decode(data);
      if (message == null) return;
      _updatePacksWithBasic(message);
    });
    _operatorIDMessagesSubscription =
        _operatorIDMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.OperatorIdMessage.decode(data);
      if (message == null) return;
      _updatePacksWithOperatorId(message);
    });
    await _api.startScan();
  }

  /// Stops any currently running scan
  static Future<void> stopScan() async {
    await _api.stopScan();
    _locationMessagesSubscription?.cancel();
    _basicMessagesSubscription?.cancel();
    _operatorIDMessagesSubscription?.cancel();
  }

  static Future<void> enableAutoRestart({required bool enable}) async {
    await _api.setAutorestart(enable);
  }

  static Future<bool> get isScanning async => await _api.isScanning();

  static void _updatePacksWithBasic(pigeon.BasicIdMessage message) {
    if (message.macAddress == null) return;
    final mac = message.macAddress as String;
    final storedPack =
        _storedPacks[message.macAddress] ?? MessagePack(macAddress: mac);
    _storedPacks[mac] = storedPack.updateWithBasic(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  static void _updatePacksWithLocation(pigeon.LocationMessage message) {
    if (message.macAddress == null) return;
    final mac = message.macAddress as String;
    final storedPack =
        _storedPacks[message.macAddress] ?? MessagePack(macAddress: mac);
    _storedPacks[mac] = storedPack.updateWithLocation(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  static void _updatePacksWithOperatorId(pigeon.OperatorIdMessage message) {
    if (message.macAddress == null) return;
    final mac = message.macAddress as String;
    final storedPack =
        _storedPacks[message.macAddress] ?? MessagePack(macAddress: mac);
    _storedPacks[mac] = storedPack.updateWithOperatorId(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }
}
