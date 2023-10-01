import 'dart:async';
import 'dart:io';

import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_opendroneid/models/message_container.dart';
import 'package:flutter_opendroneid/models/permissions_missing_exception.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

export 'package:dart_opendroneid/src/types.dart';

enum UsedTechnologies { Wifi, Bluetooth, Both, None }

class FlutterOpenDroneId {
  static late pigeon.Api _api = pigeon.Api();
  static const odidPayloadEventChannel =
      const EventChannel('flutter_odid_data');
  static const _btStateEventChannel =
      const EventChannel('flutter_odid_bt_state');
  static const _wifiStateEventChannel =
      const EventChannel('flutter_odid_wifi_state');

  static StreamSubscription? _odidDataSubscription;

  static final _packController = StreamController<MessageContainer>.broadcast();
  static Map<String, MessageContainer> _storedPacks = {};

  static Stream<bool> get bluetoothState => _btStateEventChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  static Stream<MessageContainer> get allMessages => _packController.stream;

  static Stream<bool> get wifiState => _wifiStateEventChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  static Future<bool> get btTurnedOn async =>
      await _api.bluetoothState() ==
      pigeon.BluetoothState.values.indexOf(pigeon.BluetoothState.PoweredOn);

  static Future<bool> get wifiTurnedOn async =>
      await _api.wifiState() ==
      pigeon.WifiState.values.indexOf(pigeon.WifiState.Enabled);

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
    _odidDataSubscription = odidPayloadEventChannel
        .receiveBroadcastStream()
        .listen((payload) => _updatePacks(pigeon.ODIDPayload.decode(payload)));

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
    _odidDataSubscription?.cancel();
  }

  static Future<void> setBtScanPriority(pigeon.ScanPriority priority) async {
    await _api.setBtScanPriority(priority);
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

  static void _updatePacks(pigeon.ODIDPayload payload) {
    final storedPack = _storedPacks[payload.macAddress] ??
        MessageContainer(
          macAddress: payload.macAddress,
          source: payload.source,
          lastUpdate:
              DateTime.fromMillisecondsSinceEpoch(payload.receivedTimestamp),
        );
    final message = parseODIDMessage(payload.rawData);
    if (message == null) return;
    final updatedPack = storedPack.update(
      message: message,
      receivedTimestamp: payload.receivedTimestamp,
      rssi: payload.rssi,
      source: payload.source,
    );
    // update was refused if updatedPack is null
    if (updatedPack != null) {
      _storedPacks[payload.macAddress] = updatedPack;
      _packController.add(updatedPack);
    }
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

      // Android also requires location permission to scan BT devices

      if (!await Permission.location.status.isGranted)
        missingPermissions.add(Permission.location);
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

      final androidVersionNumber = await _getAndroidVersionNumber();
      if (androidVersionNumber == null) return;
      // Android < 12 also requires location permission
      // Android 13 has a new nearbyWifiDevicesPermission
      if (androidVersionNumber >= 13) {
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

  static Future<int?> _getAndroidVersionNumber() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidVersion = (await deviceInfo.androidInfo).version.release;
    return int.tryParse(androidVersion);
  }
}
