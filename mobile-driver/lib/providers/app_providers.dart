import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yapyap_driver/core/api_client.dart';
import 'package:yapyap_driver/core/signalr_service.dart';
import 'package:yapyap_driver/services/location_tracking_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final signalRProvider = Provider<SignalRService>((ref) => SignalRService());

final locationTrackingProvider = Provider<LocationTrackingService>((ref) {
  final signalR = ref.read(signalRProvider);
  return LocationTrackingService(signalR);
});
