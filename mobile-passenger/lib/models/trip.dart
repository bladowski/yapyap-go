class TripResponse {
  final String tripId;
  final String status;
  final String? driverId;
  final String? driverName;
  final String? vehicleDescription;
  final double? estimatedPriceTzs;
  final DateTime createdAt;

  TripResponse({
    required this.tripId,
    required this.status,
    this.driverId,
    this.driverName,
    this.vehicleDescription,
    this.estimatedPriceTzs,
    required this.createdAt,
  });

  factory TripResponse.fromJson(Map<String, dynamic> json) {
    return TripResponse(
      tripId: json['tripId'] as String,
      status: json['status'] as String,
      driverId: json['driverId'] as String?,
      driverName: json['driverName'] as String?,
      vehicleDescription: json['vehicleDescription'] as String?,
      estimatedPriceTzs: (json['estimatedPriceTzs'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class FareEstimate {
  final String category;
  final double estimatedPriceTzs;
  final double distanceMeters;
  final double durationSeconds;
  final String currency;

  FareEstimate({
    required this.category,
    required this.estimatedPriceTzs,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.currency,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    return FareEstimate(
      category: json['category'] as String,
      estimatedPriceTzs: (json['estimatedPriceTzs'] as num).toDouble(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
}

class DriverLocation {
  final String driverId;
  final String driverName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  DriverLocation({
    required this.driverId,
    required this.driverName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
