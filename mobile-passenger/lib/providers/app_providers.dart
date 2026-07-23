import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yapyap_passenger/core/api_client.dart';
import 'package:yapyap_passenger/core/signalr_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final signalRProvider = Provider<SignalRService>((ref) {
  return SignalRService();
});

final signalRConnectedProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(signalRProvider);
  await service.connect();
  return service.isConnected;
});
