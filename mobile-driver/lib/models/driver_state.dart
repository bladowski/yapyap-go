class DriverState {
  final bool isOnline;
  final double walletBalance;
  final IncomingTrip? incomingTrip;
  final String? errorMessage;
  final bool isLoading;

  const DriverState({
    this.isOnline = false,
    this.walletBalance = 0,
    this.incomingTrip,
    this.errorMessage,
    this.isLoading = false,
  });

  DriverState copyWith({
    bool? isOnline,
    double? walletBalance,
    IncomingTrip? incomingTrip,
    String? errorMessage,
    bool? isLoading,
    bool clearTrip = false,
    bool clearError = false,
  }) {
    return DriverState(
      isOnline: isOnline ?? this.isOnline,
      walletBalance: walletBalance ?? this.walletBalance,
      incomingTrip: clearTrip ? null : (incomingTrip ?? this.incomingTrip),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class IncomingTrip {
  final String tripId;
  final String passengerName;
  final String category;
  final double? estimatedPriceTzs;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String? pickupAddress;

  IncomingTrip({
    required this.tripId,
    required this.passengerName,
    required this.category,
    this.estimatedPriceTzs,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.pickupAddress,
  });
}
