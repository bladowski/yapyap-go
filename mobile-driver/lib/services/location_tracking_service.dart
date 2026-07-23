import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:yapyap_driver/core/signalr_service.dart';

class LocationTrackingService {
  final SignalRService _signalR;
  Timer? _timer;
  bool _isTracking = false;

  LocationTrackingService(this._signalR);

  bool get isTracking => _isTracking;

  Future<void> start() async {
    if (_isTracking) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    _isTracking = true;

    // Get initial position and register.
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _signalR.registerDriver(pos.latitude, pos.longitude);
      await _signalR.sendLocationUpdate(pos.latitude, pos.longitude);
    } catch (_) {
      // Fallback to Stone Town center if GPS unavailable (emulator).
      await _signalR.registerDriver(-6.1659, 39.1990);
      await _signalR.sendLocationUpdate(-6.1659, 39.1990);
    }

    // Poll every 5 seconds.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isTracking) return;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _signalR.sendLocationUpdate(pos.latitude, pos.longitude);
      } catch (_) {}
    });
  }

  Future<void> stop() async {
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
  }
}
