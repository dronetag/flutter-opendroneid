import 'dart:async';
import 'dart:io';

import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_opendroneid/exceptions/odid_message_parsing_exception.dart';
import 'package:flutter_opendroneid/models/dri_source_type.dart';
import 'package:flutter_opendroneid/models/permissions_missing_exception.dart';
import 'package:flutter_opendroneid/models/received_odid_message.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

export 'package:dart_opendroneid/src/types.dart';

class FlutterOpenDroneId {
  static late pigeon.Api _api = pigeon.Api();
  // event channels
  static const bluetoothOdidPayloadEventChannel =
      const EventChannel('flutter_odid_data_bt');
  static const wifiOdidPayloadEventChannel =
      const EventChannel('flutter_odid_data_wifi');
  static const _btStateEventChannel =
      const EventChannel('flutter_odid_state_bt');
  static const _wifiStateEventChannel =
      const EventChannel('flutter_odid_state_wifi');

  static StreamSubscription? _receivedBluetoothMessagesSubscription;
  static StreamSubscription? _receivedWiFiMessagesSubscription;

  static final _receivedMessagesController =
      StreamController<ReceivedODIDMessage>.broadcast();

  static Stream<ReceivedODIDMessage> get receivedMessages =>
      _receivedMessagesController.stream;

  static Stream<bool> get bluetoothState => _btStateEventChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  static Stream<bool> get wifiState => _wifiStateEventChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  static Future<bool> get btTurnedOn async =>
      await _api.bluetoothState() ==
      pigeon.BluetoothState.values.indexOf(pigeon.BluetoothState.PoweredOn);

  static Future<bool> get wifiTurnedOn async =>
      await _api.wifiState() ==
      pigeon.WifiState.values.indexOf(pigeon.WifiState.Enabled);

  /// Initialize the plugin before using.
  static Future<void> initialize() async {
    await _api.initialize();
  }

  /// Check whether plugin was correctly initialized.
  static Future<bool> isInitialized() async {
    return await _api.isInitialized();
  }

  /// Starts scanning for nearby traffic
  /// For Bluetooth scanning, bluetooth perm. are required on both platforms,
  /// Android requires Bluetooth scan permission location permission on ver.< 12
  ///
  /// For Wi-Fi scanning, location permission is required on Android.
  ///
  /// Throws [PermissionsMissingException] if permissions were not granted.
  ///
  /// To further receive data, listen to [receivedMessages]
  /// stream.
  ///
  /// Plugin must be initialized by calling [initialize] before using.
  static Future<void> startScan(DriSourceType sourceType) async {
    if (sourceType == DriSourceType.Bluetooth) {
      await _assertBluetoothPermissions();
      _receivedBluetoothMessagesSubscription?.cancel();
      _receivedBluetoothMessagesSubscription = bluetoothOdidPayloadEventChannel
          .receiveBroadcastStream()
          .listen(
              (payload) => _handlePayload(pigeon.ODIDPayload.decode(payload)));
      await _api.startScanBluetooth();
    } else if (sourceType == DriSourceType.Wifi) {
      await _assertWifiPermissions();
      _receivedWiFiMessagesSubscription?.cancel();
      _receivedWiFiMessagesSubscription = wifiOdidPayloadEventChannel
          .receiveBroadcastStream()
          .listen(
              (payload) => _handlePayload(pigeon.ODIDPayload.decode(payload)));
      await _api.startScanWifi();
    }
  }

  /// Stops any currently running scan
  static Future<void> stopScan(DriSourceType sourceType) async {
    if (sourceType == DriSourceType.Bluetooth &&
        (await _api.isScanningBluetooth())) {
      await _api.stopScanBluetooth();
      _receivedBluetoothMessagesSubscription?.cancel();
    }
    if (sourceType == DriSourceType.Wifi && await _api.isScanningWifi()) {
      await _api.stopScanWifi();
      _receivedWiFiMessagesSubscription?.cancel();
    }
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

  static void _handlePayload(pigeon.ODIDPayload payload) {
    ODIDMessage? message;
    try {
      message = parseODIDMessage(payload.rawData);
    } catch (e) {
      throw ODIDMessageParsingException(
        relatedException: e,
        macAddress: payload.macAddress,
        rssi: payload.rssi,
        receivedTimestamp: payload.receivedTimestamp,
        source: payload.source,
        btName: payload.btName,
      );
    }

    if (message == null) return;

    _receivedMessagesController.add(
      ReceivedODIDMessage(
        odidMessage: message,
        macAddress: payload.macAddress,
        source: payload.source,
        rssi: payload.rssi,
        receivedTimestamp:
            DateTime.fromMillisecondsSinceEpoch(payload.receivedTimestamp),
      ),
    );
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
