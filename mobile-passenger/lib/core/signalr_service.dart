import 'package:signalr_core/signalr_core.dart';

class SignalRService {
  static const _baseUrl = 'http://10.0.2.2:5180';
  static const _passengerUserId = 'eca1143b-5cae-4867-ab85-403909324899';

  HubConnection? _tripHub;
  HubConnection? _locationHub;

  HubConnection get tripHub => _tripHub!;
  HubConnection get locationHub => _locationHub!;

  bool get isConnected =>
      _tripHub?.state == HubConnectionState.Connected &&
      _locationHub?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    _tripHub = HubConnectionBuilder()
        .withUrl('$_baseUrl/hubs/trip')
        .withAutomaticReconnect()
        .build();

    _locationHub = HubConnectionBuilder()
        .withUrl('$_baseUrl/hubs/location')
        .withAutomaticReconnect()
        .build();

    _tripHub!.onclose(({error}) {
      print('TripHub closed: $error');
    });

    _locationHub!.onclose(({error}) {
      print('LocationHub closed: $error');
    });

    await _tripHub!.start();
    await _locationHub!.start();

    if (_tripHub!.state == HubConnectionState.Connected) {
      await _tripHub!.invoke('RegisterAsync', args: [_passengerUserId]);
    }
  }

  /// Listen for trip events (TripAccepted, TripUpdated).
  void onTripEvent(String method, void Function(List<Object?>?) handler) {
    _tripHub?.on(method, handler);
  }

  /// Listen for live driver location updates.
  void onDriverLocation(void Function(List<Object?>?) handler) {
    _locationHub?.on('DriverLocationUpdated', handler);
  }

  Future<void> disconnect() async {
    await _tripHub?.stop();
    await _locationHub?.stop();
  }
}
