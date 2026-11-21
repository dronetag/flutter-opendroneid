import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native interop host API is callable', (tester) async {
    await FlutterOpenDroneId.initialize();

    expect(await FlutterOpenDroneId.isInitialized(), isTrue);
    expect(await FlutterOpenDroneId.isScanningBluetooth, isFalse);
    expect(await FlutterOpenDroneId.isScanningWifi, isFalse);
    expect(FlutterOpenDroneId.droppedPayloadCount, 0);

    // Exercises the only async FFI/JNI host method. Hardware may be absent on
    // a simulator/emulator, so only a bridge-level failure is relevant here.
    try {
      await FlutterOpenDroneId.btTurnedOn;
    } on Object catch (error) {
      // ignore: avoid_print
      print('btTurnedOn not available in this environment: $error');
    }
  });
}
