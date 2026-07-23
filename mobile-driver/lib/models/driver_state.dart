class DriverState {
  final bool isOnline;
  final double walletBalance;
  final ActiveTrip? activeTrip;
  final IncomingTrip? incomingTrip;
  final String? errorMessage;
  final bool isLoading;

  const DriverState({
    this.isOnline = false,
    this.walletBalance = 0,
    this.activeTrip,
    this.incomingTrip,
    this.errorMessage,
    this.isLoading = false,
  });

  DriverState copyWith({
    bool? isOnline,
    double? walletBalance,
    ActiveTrip? activeTrip,
    IncomingTrip? incomingTrip,
    String? errorMessage,
    bool? isLoading,
    bool clearActiveTrip = false,
    bool clearIncomingTrip = false,
    bool clearError = false,
  }) {
    return DriverState(
      isOnline: isOnline ?? this.isOnline,
      walletBalance: walletBalance ?? this.walletBalance,
      activeTrip:
          clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      incomingTrip: clearIncomingTrip
          ? null
          : (incomingTrip ?? this.incomingTrip),
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

  ActiveTrip toActiveTrip({String status = 'DriverAssigned'}) {
    return ActiveTrip(
      tripId: tripId,
      passengerName: passengerName,
      category: category,
      estimatedPriceTzs: estimatedPriceTzs,
      status: status,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      pickupAddress: pickupAddress,
    );
  }
}

class ActiveTrip {
  final String tripId;
  final String passengerName;
  final String category;
  final double? estimatedPriceTzs;
  final String status;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String? pickupAddress;

  ActiveTrip({
    required this.tripId,
    required this.passengerName,
    required this.category,
    this.estimatedPriceTzs,
    required this.status,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.pickupAddress,
  });

  ActiveTrip copyWith({String? status}) {
    return ActiveTrip(
      tripId: tripId,
      passengerName: passengerName,
      category: category,
      estimatedPriceTzs: estimatedPriceTzs,
      status: status ?? this.status,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      pickupAddress: pickupAddress,
    );
  }

  /// Target coordinates for navigation: pickup before arrival, dropoff after.
  double get targetLat => status == 'DriverAssigned' ? pickupLat : dropoffLat;
  double get targetLng => status == 'DriverAssigned' ? pickupLng : dropoffLng;

  String get targetLabel =>
      status == 'DriverAssigned' ? 'Pickup' : 'Dropoff';

  String get actionLabel => switch (status) {
        'DriverAssigned' => 'Arrived at Pickup',
        'DriverArrived' => 'Start Trip',
        'InProgress' => 'Complete Trip',
        _ => '...',
      };

  String get nextStatus => switch (status) {
        'DriverAssigned' => 'DriverArrived',
        'DriverArrived' => 'InProgress',
        'InProgress' => 'Completed',
        _ => status,
      };
}
