import 'package:flutter_opendroneid/src/pigeon/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enum ordinals are a stable ABI', () {
    expect(ScanPriority.values, <ScanPriority>[
      ScanPriority.High,
      ScanPriority.Low,
    ]);
    expect(MessageSource.values, <MessageSource>[
      MessageSource.BluetoothLegacy,
      MessageSource.BluetoothLongRange,
      MessageSource.WifiNan,
      MessageSource.WifiBeacon,
      MessageSource.Unknown,
    ]);
    expect(BluetoothState.values, <BluetoothState>[
      BluetoothState.Unknown,
      BluetoothState.Resetting,
      BluetoothState.Unsupported,
      BluetoothState.Unauthorized,
      BluetoothState.PoweredOff,
      BluetoothState.PoweredOn,
    ]);
    expect(WifiState.values, <WifiState>[
      WifiState.Disabling,
      WifiState.Disabled,
      WifiState.Enabling,
      WifiState.Enabled,
    ]);
    expect(BluetoothPhy.values, <BluetoothPhy>[
      BluetoothPhy.None,
      BluetoothPhy.Phy1M,
      BluetoothPhy.Phy2M,
      BluetoothPhy.PhyLECoded,
      BluetoothPhy.Unknown,
    ]);
  });
}
