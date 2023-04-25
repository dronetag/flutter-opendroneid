import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_opendroneid/models/permissions_missing_exception.dart';
import 'models/message_pack.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

enum UsedTechnologies { Wifi, Bluetooth, Both, None }

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
  // auth messages are not yet supported
  //static const _authMessagesEventChannel =
  //    const EventChannel('flutter_auth_messages');
  static const _selfIdMessagesEventChannel =
      const EventChannel('flutter_selfid_messages');
  static const _btStateEventChannel =
      const EventChannel('flutter_odid_bt_state');
  static const _wifiStateEventChannel =
      const EventChannel('flutter_odid_wifi_state');

  static Map<String, MessagePack> _storedPacks = {};
  static final _packController = StreamController<MessagePack>.broadcast();
  static StreamSubscription? _locationMessagesSubscription;
  static StreamSubscription? _basicMessagesSubscription;
  static StreamSubscription? _operatorIDMessagesSubscription;
  //static StreamSubscription? _authMessagesSubscription;
  static StreamSubscription? _systemDataMessagesSubscription;
  static StreamSubscription? _selfIDMessagesSubscription;

  static Stream<bool> get bluetoothState => _btStateEventChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  static Stream<MessagePack> get allMessages => _packController.stream;

  static Stream<bool> get wifiState => _wifiStateEventChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  static Future<bool> get btTurnedOn async {
    return await _api.bluetoothState() ==
        pigeon.BluetoothState.values.indexOf(pigeon.BluetoothState.PoweredOn);
  }

  static Future<bool> get wifiTurnedOn async {
    return await _api.wifiState() ==
        pigeon.WifiState.values.indexOf(pigeon.WifiState.Enabled);
  }

  /// Starts scanning for nearby traffic
  /// For Bluetooth scanning, bluetooth permissions are required on both platforms,
  /// Android requires Bluetooth scan permission location permission on ver.  < 12
  ///
  /// For Wi-Fi scanning, location permission is required on Android
  ///
  /// Throws PermissionMissingException if permissions were not granted
  ///
  /// To further receive data, listen to
  /// streams.
  static Future<void> startScan(UsedTechnologies usedTechnologies) async {
    _locationMessagesSubscription =
        _locationMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.LocationMessage.decode(data);
      _updatePacksWithLocation(message);
    });
    _basicMessagesSubscription =
        _basicMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.BasicIdMessage.decode(data);
      _updatePacksWithBasic(message);
    });
    _operatorIDMessagesSubscription =
        _operatorIDMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.OperatorIdMessage.decode(data);
      _updatePacksWithOperatorId(message);
    });
    // to-do: debug auth message parsing, causes exception
    /*_authMessagesSubscription =
        _authMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.AuthenticationMessage.decode(data);
      if (message == null) return;
      _updatePacksWithAuthentication(message);
    });*/
    _systemDataMessagesSubscription =
        _systemDataMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.SystemDataMessage.decode(data);
      _updatePacksWithSystemData(message);
    });
    _selfIDMessagesSubscription =
        _selfIdMessagesEventChannel.receiveBroadcastStream().listen((data) {
      final message = pigeon.SelfIdMessage.decode(data);
      _updatePacksWithSelfId(message);
    });
    if (usedTechnologies == UsedTechnologies.Bluetooth ||
        usedTechnologies == UsedTechnologies.Both) {
      await _assertBluetoothPermissions();
      await _api.startScanBluetooth();
    }
    if (usedTechnologies == UsedTechnologies.Wifi ||
        usedTechnologies == UsedTechnologies.Both) {
      await _assertWifiPermissions();
      await _api.startScanWifi();
    }
  }

  /// Stops any currently running scan
  static Future<void> stopScan() async {
    if (await _api.isScanningBluetooth()) await _api.stopScanBluetooth();
    if (await _api.isScanningWifi()) await _api.stopScanWifi();
    _locationMessagesSubscription?.cancel();
    _basicMessagesSubscription?.cancel();
    _operatorIDMessagesSubscription?.cancel();
    //_authMessagesSubscription?.cancel();
    _selfIDMessagesSubscription?.cancel();
    _systemDataMessagesSubscription?.cancel();
  }

  static Future<void> setBtScanPriority(pigeon.ScanPriority priority) async {
    await _api.setBtScanPriority(priority);
  }

  /// Checks all required Bluetooth permissions and throws
  /// [PermissionsMissingException] if any of them are not granted.
  static Future<void> _assertBluetoothPermissions() async {
    List<Permission> missingPermissions = [];

    // Bluetooth permission is required on all platforms
    if (!await Permission.bluetooth.status.isGranted)
      missingPermissions.add(Permission.bluetooth);

    if (Platform.isAndroid) {
      // Bluetooth Scan permission is required on all Android phones
      if (!await Permission.bluetoothScan.status.isGranted)
        missingPermissions.add(Permission.bluetoothScan);

      final androidVersionNumber = await getAndroidVersionNumber();

      // Android < 12 also requires location permission to scan BT devices
      if (androidVersionNumber != null && androidVersionNumber < 12) {
        if (!await Permission.location.status.isGranted)
          missingPermissions.add(Permission.location);
      }
    }

    if (missingPermissions.isNotEmpty)
      throw PermissionsMissingException(missingPermissions);
  }

  /// Checks all required Wi-Fi permissions and throws
  /// [PermissionsMissingException] if any of them are not granted.
  static Future<void> _assertWifiPermissions() async {
    // Android requires location permission to scan Wi-Fi devices
    if (Platform.isAndroid) {
      List<Permission> missingPermissions = [];

      final androidVersionNumber = await getAndroidVersionNumber();
      if (androidVersionNumber == null) return;
      // Android < 12 also requires location permission
      // Android 13 has a new nearbyWifiDevicesPermission
      if (androidVersionNumber! >= 13) {
        if (!await Permission.nearbyWifiDevices.status.isGranted)
          missingPermissions.add(Permission.nearbyWifiDevices);
      } else {
        if (!await Permission.location.status.isGranted)
          missingPermissions.add(Permission.location);
      }
      if (missingPermissions.isNotEmpty)
        throw PermissionsMissingException(missingPermissions);
    }
  }

  static Future<int?> getAndroidVersionNumber() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidVersion = (await deviceInfo.androidInfo).version.release;
    return int.tryParse(androidVersion);
  }

  static Future<bool> get isScanningBluetooth async {
    return _api.isScanningBluetooth();
  }

  static Future<bool> get isBluetoothExtendedSupported async =>
      await _api.btExtendedSupported();

  static Future<bool> get isWifiNanSupported async =>
      await _api.wifiNaNSupported();

  static Future<int> get btMaxAdvDataLen async => await _api.btMaxAdvDataLen();

  static Future<bool> get isScanningWifi async => await _api.isScanningWifi();

  static void _updatePacksWithBasic(pigeon.BasicIdMessage message) {
    final mac = message.macAddress;
    final storedPack = _storedPacks[message.macAddress] ??
        MessagePack(
          macAddress: mac,
          lastUpdate:
              DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp),
        );
    _storedPacks[mac] = storedPack.updateWithBasic(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  static void _updatePacksWithLocation(pigeon.LocationMessage message) {
    final mac = message.macAddress;
    final storedPack = _storedPacks[message.macAddress] ??
        MessagePack(
            macAddress: mac,
            lastUpdate:
                DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
    _storedPacks[mac] = storedPack.updateWithLocation(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  static void _updatePacksWithOperatorId(pigeon.OperatorIdMessage message) {
    final mac = message.macAddress;
    final storedPack = _storedPacks[message.macAddress] ??
        MessagePack(
            macAddress: mac,
            lastUpdate:
                DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
    _storedPacks[mac] = storedPack.updateWithOperatorId(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  static void _updatePacksWithSystemData(pigeon.SystemDataMessage message) {
    final mac = message.macAddress;
    final storedPack = _storedPacks[message.macAddress] ??
        MessagePack(
            macAddress: mac,
            lastUpdate:
                DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
    _storedPacks[mac] = storedPack.updateWithSystemData(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  // ignore: unused_element
  static void _updatePacksWithAuthentication(
      pigeon.AuthenticationMessage message) {
    final mac = message.macAddress;
    final storedPack = _storedPacks[message.macAddress] ??
        MessagePack(
            macAddress: mac,
            lastUpdate:
                DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
    _storedPacks[mac] = storedPack.updateWithAuthentication(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }

  static void _updatePacksWithSelfId(pigeon.SelfIdMessage message) {
    final mac = message.macAddress;
    final storedPack = _storedPacks[message.macAddress] ??
        MessagePack(
          macAddress: mac,
          lastUpdate:
              DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp),
        );
    _storedPacks[mac] = storedPack.updateWithSelfId(message);
    _packController.add(_storedPacks[message.macAddress]!);
  }
}
