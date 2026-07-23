import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yapyap_passenger/core/api_client.dart';
import 'package:yapyap_passenger/core/signalr_service.dart';
import 'package:yapyap_passenger/models/ride_request_state.dart';
import 'package:yapyap_passenger/models/trip.dart';
import 'package:yapyap_passenger/providers/app_providers.dart';

class RideRequestController extends StateNotifier<RideRequestState> {
  final ApiClient _api;
  final SignalRService _signalR;

  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
  List<FareEstimate> _estimates = [];
  StreamSubscription? _tripSubscription;

  RideRequestController(this._api, this._signalR)
      : super(const RideRequestState());

  List<FareEstimate> get estimates => _estimates;

  void selectDropoff(double lat, double lng) {
    _dropoffLat = lat;
    _dropoffLng = lng;
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Hardcoded pickup in Stone Town for MVP. Real app uses geolocator.
  void setPickup(double lat, double lng) {
    _pickupLat = lat;
    _pickupLng = lng;
  }

  Future<void> fetchEstimates() async {
    if (_pickupLat == null || _dropoffLat == null) return;
    state = state.copyWith(step: RideRequestStep.fetchingEstimates);

    try {
      _estimates = await _api.estimatePrice(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        dropoffLat: _dropoffLat!,
        dropoffLng: _dropoffLng!,
      );
      state = state.copyWith(step: RideRequestStep.selectingVehicle);
    } catch (e) {
      state = state.copyWith(step: RideRequestStep.selectingDropoff);
      rethrow;
    }
  }

  Future<void> confirmRide() async {
    if (_pickupLat == null || _dropoffLat == null) return;
    state = state.copyWith(step: RideRequestStep.searchingForDriver);

    try {
      final trip = await _api.requestTrip(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        dropoffLat: _dropoffLat!,
        dropoffLng: _dropoffLng!,
        category: state.selectedCategory,
        paymentMethod: state.paymentMethod,
      );
      state = state.copyWith(tripId: trip.tripId);
      _listenForDriverAssignment();
    } catch (e) {
      state = state.copyWith(step: RideRequestStep.selectingVehicle);
      rethrow;
    }
  }

  void _listenForDriverAssignment() {
    final stream = _signalR.tripEventStream;
    _tripSubscription = stream.listen((event) {
      try {
        final data = jsonDecode(event) as Map<String, dynamic>;
        final status = data['status'] as String?;
        final eventTripId = data['tripId'] as String?;

        if (eventTripId == state.tripId && status == 'DriverAssigned') {
          state = state.copyWith(step: RideRequestStep.driverAssigned);
          _tripSubscription?.cancel();
        }
      } catch (_) {}
    });
  }

  void reset() {
    _tripSubscription?.cancel();
    _estimates = [];
    _pickupLat = null;
    _pickupLng = null;
    _dropoffLat = null;
    _dropoffLng = null;
    state = const RideRequestState();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }
}

final rideRequestProvider =
    StateNotifierProvider<RideRequestController, RideRequestState>((ref) {
  final api = ref.read(apiClientProvider);
  final signalR = ref.read(signalRProvider);
  return RideRequestController(api, signalR);
});
