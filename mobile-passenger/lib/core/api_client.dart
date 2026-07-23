import 'package:dio/dio.dart';

class ApiClient {
  static const _passengerUserId = 'eca1143b-5cae-4867-ab85-403909324899';

  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator.
  static const baseUrl = 'http://10.0.2.2:5180';

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
}
