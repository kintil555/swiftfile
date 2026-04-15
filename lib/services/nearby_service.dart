// Nearby Connections — Android only (WiFi Direct + BLE)
// On Windows, SwiftShare uses WiFi LAN (HTTP) instead.
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NearbyPeer {
  final String endpointId;
  final String name;
  NearbyPeer(this.endpointId, this.name);
}

class NearbyService {
  bool get isSupported => Platform.isAndroid;
  final List<NearbyPeer> peers = [];

  Future<void> startDiscovery({
    required String deviceName,
    required void Function(NearbyPeer peer) onFound,
    required void Function(String id) onLost,
  }) async {
    if (!isSupported) return;
    // Integrate nearby_connections plugin here for Android builds
  }

  Future<void> startAdvertising({
    required String deviceName,
    required void Function(String id, String name) onConnection,
  }) async {
    if (!isSupported) return;
  }

  Future<bool> connect(String endpointId) async => false;
  Future<void> sendFile(String endpointId, String filePath) async {}
  Future<void> stopAll() async {}
  void dispose() => stopAll();
}

final nearbyServiceProvider = Provider<NearbyService>((ref) {
  final svc = NearbyService();
  ref.onDispose(svc.dispose);
  return svc;
});
