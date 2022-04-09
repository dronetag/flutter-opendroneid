import 'dart:async';

import 'package:flutter/services.dart';
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
  static const _systemDataMessagesEventChannel =
      const EventChannel('flutter_system_messages');
  static const _authMessagesEventChannel =
      const EventChannel('flutter_auth_messages');
  static const _selfIdMessagesEventChannel =
      const EventChannel('flutter_selfid_messages');
  static const _btStateEventChannel =
      const EventChannel('flutter_odid_bt_state');
  static const _scanStateEventChannel =
      const EventChannel('flutter_odid_scan_state');

  static Map<String, MessagePack> _storedPacks = {};
  static final _packController = StreamController<MessagePack>.broadcast();
  static StreamSubscription? _locationMessagesSubscription;
  static StreamSubscription? _basicMessagesSubscription;
  static StreamSubscription? _operatorIDMessagesSubscription;
  static StreamSubscription? _authMessagesSubscription;
  static StreamSubscription? _systemDataMessagesSubscription;
  static StreamSubscription? _selfIDMessagesSubscription;

  static Stream<pigeon.BluetoothState> get bluetoothState async* {
    yield pigeon.BluetoothState.values[await _api.bluetoothState()];
    yield* _btStateEventChannel
        .receiveBroadcastStream()
        .asyncMap((event) => pigeon.BluetoothState.values[event]);
  }

  static Stream<MessagePack> get allMessages => _packController.stream;

  static Stream<bool> get isScanningStream => _scanStateEventChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  /// Starts scanning for nearby traffic
  ///
  /// To further receive data, listen to
  /// streams.
  static Future<void> startScan() async {
    print('lib start');
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
    _authMessagesSubscription =
        _authMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.AuthenticationMessage.decode(data);
      if (message == null) return;
      _updatePacksWithAuthentication(message);
    });
    _systemDataMessagesSubscription =
        _systemDataMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.SystemDataMessage.decode(data);
      if (message == null) return;
      _updatePacksWithSystemData(message);
    });
    _selfIDMessagesSubscription =
        _selfIdMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.SelfIdMessage.decode(data);
      if (message == null) return;
      _updatePacksWithSelfId(message);
    });
    await _api.startScanBluetooth();
    await _api.startScanWifi();
  }

  /// Stops any currently running scan
  static Future<void> stopScan() async {
    await _api.stopScanBluetooth();
    await _api.stopScanWifi();
    _locationMessagesSubscription?.cancel();
    _basicMessagesSubscription?.cancel();
    _operatorIDMessagesSubscription?.cancel();
  }

  static Future<void> enableAutoRestart({required bool enable}) async {
    await _api.setAutorestartBluetooth(enable);
  }

  static Future<bool> get isScanningBluetooth async =>
      await _api.isScanningBluetooth();

  static Future<bool> get isBluetoothExtendedSupported async =>
      await _api.btExtendedSupported();

  static Future<bool> get isWifiNanSupported async =>
      await _api.wifiNaNSupported();

  static Future<int> get btMaxAdvDataLen async => await _api.btMaxAdvDataLen();

  static Future<bool> get isScanningWifi async => await _api.isScanningWifi();

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

  static void _updatePacksWithSystemData(pigeon.SystemDataMessage message) {
    if (message.macAddress == null) return;
    final mac = message.macAddress as String;
    final storedPack =
        _storedPacks[message.macAddress] ?? MessagePack(macAddress: mac);
    _storedPacks[mac] = storedPack.updateWithSystemData(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  static void _updatePacksWithAuthentication(
      pigeon.AuthenticationMessage message) {
    if (message.macAddress == null) return;
    final mac = message.macAddress as String;
    final storedPack =
        _storedPacks[message.macAddress] ?? MessagePack(macAddress: mac);
    _storedPacks[mac] = storedPack.updateWithAuthentication(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  static void _updatePacksWithSelfId(pigeon.SelfIdMessage message) {
    if (message.macAddress == null) return;
    final mac = message.macAddress as String;
    final storedPack =
        _storedPacks[message.macAddress] ?? MessagePack(macAddress: mac);
    _storedPacks[mac] = storedPack.updateWithSelfId(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }
}
