import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// flutter_bluetooth_serial only works on Android
// On Windows we use WiFi only; Nearby works on Android only
abstract class BluetoothService {
  bool get isSupported;
  Future<void> dispose();
}

class AndroidBluetoothService extends BluetoothService {
  @override
  bool get isSupported => true;

  @override
  Future<void> dispose() async {}
}

class StubBluetoothService extends BluetoothService {
  @override
  bool get isSupported => false;

  @override
  Future<void> dispose() async {}
}

BluetoothService createBluetoothService() {
  if (Platform.isAndroid) return AndroidBluetoothService();
  return StubBluetoothService();
}

final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final svc = createBluetoothService();
  ref.onDispose(svc.dispose);
  return svc;
});
