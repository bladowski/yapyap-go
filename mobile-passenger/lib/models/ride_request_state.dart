enum RideRequestStep {
  selectingDropoff,
  fetchingEstimates,
  selectingVehicle,
  searchingForDriver,
  driverAssigned,
}

class RideRequestState {
  final RideRequestStep step;
  final String selectedCategory;
  final String paymentMethod;
  final String? tripId;

  const RideRequestState({
    this.step = RideRequestStep.selectingDropoff,
    this.selectedCategory = 'BodaBoda',
    this.paymentMethod = 'Cash',
    this.tripId,
  });

  RideRequestState copyWith({
    RideRequestStep? step,
    String? selectedCategory,
    String? paymentMethod,
    String? tripId,
    bool clearTripId = false,
  }) {
    return RideRequestState(
      step: step ?? this.step,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tripId: clearTripId ? null : (tripId ?? this.tripId),
    );
  }
}
