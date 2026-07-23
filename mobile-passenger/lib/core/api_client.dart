import 'package:dio/dio.dart';
import 'package:yapyap_passenger/models/trip.dart';

class ApiClient {
  static const _passengerUserId = 'eca1143b-5cae-4867-ab85-403909324899';

  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator.
  static const baseUrl = 'http://192.168.88.104:5180';

  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': _passengerUserId,
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  /// Fetch fare estimates for all vehicle categories between two points.
  /// The backend returns one estimate per category — we call once per category.
  Future<List<FareEstimate>> estimatePrice({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    const categories = ['BodaBoda', 'TukTuk', 'Car'];
    final estimates = <FareEstimate>[];

    for (final cat in categories) {
      final response = await dio.post('/api/v1/trips/estimate', data: {
        'pickupLatitude': pickupLat,
        'pickupLongitude': pickupLng,
        'dropoffLatitude': dropoffLat,
        'dropoffLongitude': dropoffLng,
        'categoryRequested': cat,
        'paymentMethod': 'Cash',
      });
      estimates.add(FareEstimate.fromJson(response.data as Map<String, dynamic>));
    }

    return estimates;
  }

  /// Request a ride. Returns the created trip.
  Future<TripResponse> requestTrip({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String category,
    required String paymentMethod,
  }) async {
    final response = await dio.post('/api/v1/trips', data: {
      'pickupLatitude': pickupLat,
      'pickupLongitude': pickupLng,
      'dropoffLatitude': dropoffLat,
      'dropoffLongitude': dropoffLng,
      'categoryRequested': category,
      'paymentMethod': paymentMethod,
    });

    return TripResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
