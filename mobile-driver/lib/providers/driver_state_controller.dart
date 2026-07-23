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
        final eventTripId = data['tripId'] as String?;

        if (status == 'Requested') {
          state = state.copyWith(
            incomingTrip: IncomingTrip(
              tripId: data['tripId'] as String,
              passengerName: 'Passenger',
              category: data['vehicleDescription'] as String? ?? 'Unknown',
              estimatedPriceTzs:
                  (data['estimatedPriceTzs'] as num?)?.toDouble(),
              pickupLat: -6.1659,
              pickupLng: 39.1990,
              dropoffLat: -6.1300,
              dropoffLng: 39.2200,
            ),
          );
        }

        // If an active trip's status changed via another party, sync it.
        if (eventTripId == state.activeTrip?.tripId && status != null) {
          state = state.copyWith(
            activeTrip: state.activeTrip!.copyWith(status: status),
          );

          if (status == 'Completed') {
            _onTripCompleted();
          }
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
      state = state.copyWith(
          isOnline: true, walletBalance: balance, isLoading: false);
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
      final result = await _api.acceptTrip(tripId);
      final activeTrip = ActiveTrip(
        tripId: result['tripId'] as String,
        passengerName: (result['driverName'] as String?) ?? 'Passenger',
        category: (result['vehicleDescription'] as String?) ?? 'Unknown',
        estimatedPriceTzs:
            (result['estimatedPriceTzs'] as num?)?.toDouble(),
        status: result['status'] as String? ?? 'DriverAssigned',
        pickupLat: state.incomingTrip?.pickupLat ?? -6.1659,
        pickupLng: state.incomingTrip?.pickupLng ?? 39.1990,
        dropoffLat: state.incomingTrip?.dropoffLat ?? -6.1300,
        dropoffLng: state.incomingTrip?.dropoffLng ?? 39.2200,
        pickupAddress: state.incomingTrip?.pickupAddress,
      );
      state = state.copyWith(
        activeTrip: activeTrip,
        clearIncomingTrip: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to accept trip: $e');
    }
  }

  void dismissTrip() {
    state = state.copyWith(clearIncomingTrip: true);
  }

  /// Advance the active trip to the next status.
  Future<void> advanceTripStatus() async {
    final trip = state.activeTrip;
    if (trip == null) return;

    final next = trip.nextStatus;
    if (next == trip.status) return;

    state = state.copyWith(isLoading: true);

    try {
      await _api.updateTripStatus(trip.tripId, next);
      state = state.copyWith(
        activeTrip: trip.copyWith(status: next),
        isLoading: false,
      );

      if (next == 'Completed') {
        _onTripCompleted();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update trip: $e',
      );
    }
  }

  void _onTripCompleted() {
    // Refresh wallet — backend just applied commission/credit.
    _loadWallet();
    state = state.copyWith(clearActiveTrip: true);
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
