import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yapyap_driver/core/api_client.dart';
import 'package:yapyap_driver/core/signalr_service.dart';
import 'package:yapyap_driver/models/driver_state.dart';
import 'package:yapyap_driver/providers/app_providers.dart';
import 'package:yapyap_driver/services/location_tracking_service.dart';

class DriverStateController extends StateNotifier<DriverState> {
  final ApiClient _api;
  final SignalRService _signalR;
  final LocationTrackingService _locationTracker;
  StreamSubscription? _tripSubscription;

  DriverStateController(this._api, this._signalR, this._locationTracker)
      : super(const DriverState()) {
    _loadWallet();
    _listenForTrips();
  }

  Future<void> _loadWallet() async {
    final balance = await _api.getWalletBalance();
    state = state.copyWith(walletBalance: balance);
  }

  void _listenForTrips() {
    _tripSubscription = _signalR.tripEventStream.listen((event) {
      try {
        final data = jsonDecode(event) as Map<String, dynamic>;
        final status = data['status'] as String?;

        // When a trip is accepted (assigned to this driver), it arrives via TripHub.
        // The driver receives the trip request before accepting.
        // For MVP: listen for any trip where status is Requested — in production,
        // the backend would broadcast ride requests to nearby drivers.
        if (status == 'Requested' || status == 'DriverAssigned') {
          final trip = IncomingTrip(
            tripId: data['tripId'] as String,
            passengerName: data['driverName'] as String? ?? 'Passenger',
            category: data['vehicleDescription'] as String? ?? 'Unknown',
            estimatedPriceTzs:
                (data['estimatedPriceTzs'] as num?)?.toDouble(),
            pickupLat: 0, // Backend doesn't send coords in trip event yet
            pickupLng: 0,
            dropoffLat: 0,
            dropoffLng: 0,
            pickupAddress: null,
          );
          state = state.copyWith(incomingTrip: trip);
        }
      } catch (_) {}
    });
  }

  Future<void> toggleOnline() async {
    if (state.isOnline) {
      await _goOffline();
    } else {
      await _goOnline();
    }
  }

  Future<void> _goOnline() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Refresh wallet before online check.
    final balance = await _api.getWalletBalance();

    if (balance < 0) {
      state = state.copyWith(
        isLoading: false,
        walletBalance: balance,
        errorMessage:
            'Wallet balance is negative (${balance.toStringAsFixed(0)} TZS). '
            'Please settle your balance before going online.',
      );
      return;
    }

    try {
      await _api.setOnlineStatus(true);
      await _locationTracker.start();
      state = state.copyWith(isOnline: true, walletBalance: balance, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to go online: $e',
      );
    }
  }

  Future<void> _goOffline() async {
    state = state.copyWith(isLoading: true);
    try {
      await _locationTracker.stop();
      await _api.setOnlineStatus(false);
      state = state.copyWith(isOnline: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to go offline: $e',
      );
    }
  }

  Future<void> acceptTrip(String tripId) async {
    try {
      await _api.acceptTrip(tripId);
      state = state.copyWith(clearTrip: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to accept trip: $e');
    }
  }

  void dismissTrip() {
    state = state.copyWith(clearTrip: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }
}

final driverStateProvider =
    StateNotifierProvider<DriverStateController, DriverState>((ref) {
  final api = ref.read(apiClientProvider);
  final signalR = ref.read(signalRProvider);
  final tracker = ref.read(locationTrackingProvider);
  return DriverStateController(api, signalR, tracker);
});
