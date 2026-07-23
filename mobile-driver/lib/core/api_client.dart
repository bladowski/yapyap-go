import 'package:dio/dio.dart';

class ApiClient {
  // Juma Ali — BodaBoda driver (seed data)
  static const _driverUserId = '701f5316-3fa9-4a78-9d95-207d10dfa211';
  static const _driverProfileId = '7a58af30-82b7-425d-ba8a-efa4dd8a617e';

  static const baseUrl = 'http://10.0.2.2:5180';

  late final Dio dio;

  String get driverProfileId => _driverProfileId;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': _driverUserId,
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<double> getWalletBalance() async {
    try {
      final response = await dio.get(
        '/api/v1/drivers/$_driverProfileId/wallet',
      );
      return (response.data['balanceTzs'] as num).toDouble();
    } catch (_) {
      return 0;
    }
  }

  Future<void> setOnlineStatus(bool online) async {
    await dio.post(
      '/api/v1/drivers/$_driverProfileId/online',
      queryParameters: {'online': online},
    );
  }

  Future<Map<String, dynamic>> acceptTrip(String tripId) async {
    final response = await dio.post('/api/v1/trips/$tripId/accept');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTripStatus(
      String tripId, String newStatus) async {
    final response = await dio.post(
      '/api/v1/trips/$tripId/status',
      data: {'newStatus': newStatus},
    );
    return response.data as Map<String, dynamic>;
  }
}
