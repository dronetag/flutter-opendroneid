import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scan-active callbacks reach the public streams', () async {
    final bluetooth = expectLater(
      FlutterOpenDroneId.bluetoothState,
      emitsInOrder(<bool>[true, false]),
    );
    final wifi = expectLater(
      FlutterOpenDroneId.wifiState,
      emitsInOrder(<bool>[true, false]),
    );
    await Future<void>.delayed(Duration.zero);

    FlutterOpenDroneId.debugFlutterApi
      ..onBluetoothScanActive(true)
      ..onWifiScanActive(true)
      ..onBluetoothScanActive(false)
      ..onWifiScanActive(false);

    await bluetooth;
    await wifi;
  });
}
