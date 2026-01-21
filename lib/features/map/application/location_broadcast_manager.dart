import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/bluetooth_service.dart';

final locationBroadcastManagerProvider = Provider<LocationBroadcastManager>((ref) {
  return LocationBroadcastManager(ref);
});

class LocationBroadcastManager {
  final Ref _ref;
  Timer? _timer;
  bool _isRunning = false;

  LocationBroadcastManager(this._ref);

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _broadcast(); // Initial broadcast
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _broadcast());
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  Future<void> _broadcast() async {
    try {
      // 1. Check Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // We do not request permission here to avoid popping up dialogs in background
        // We assume permission was granted via Map or other flows
        return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // 2. Get Location
      // create a timeout to avoid hanging
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );

      // 3. Send via Bluetooth
      final bluetoothService = _ref.read(bluetoothServiceProvider);
      // We assume bluetoothService handles the "is connected" check gracefully (it checks _toRadioChar)
      await bluetoothService.sendPosition(
        position.latitude, 
        position.longitude, 
        position.altitude.toInt()
      );
      
    } catch (e) {
      // Log or ignore errors (e.g. timeout, no bluetooth connection)
      print("Error broadcasting location: $e");
    }
  }
}
