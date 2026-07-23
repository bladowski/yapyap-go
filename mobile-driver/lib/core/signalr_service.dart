import 'dart:async';
import 'dart:convert';
import 'package:signalr_core/signalr_core.dart';

class SignalRService {
  static const _baseUrl = 'http://192.168.88.104:5180';
  static const _driverUserId = '701f5316-3fa9-4a78-9d95-207d10dfa211';

  HubConnection? _tripHub;
  HubConnection? _locationHub;

  final _tripEventController = StreamController<String>.broadcast();

  Stream<String> get tripEventStream => _tripEventController.stream;

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

    _tripHub!.onclose(({error}) => print('TripHub closed: $error'));
    _locationHub!.onclose(({error}) => print('LocationHub closed: $error'));

    _tripHub!.on('TripAccepted', _onTripEvent);
    _tripHub!.on('TripUpdated', _onTripEvent);

    await _tripHub!.start();
    await _locationHub!.start();

    if (_tripHub!.state == HubConnectionState.Connected) {
      await _tripHub!.invoke('RegisterAsync', args: [_driverUserId]);
    }
  }

  void _onTripEvent(List<Object?>? args) {
    if (args?.isNotEmpty == true && args!.first is String) {
      _tripEventController.add(args.first as String);
    } else if (args?.isNotEmpty == true) {
      _tripEventController.add(jsonEncode(args!.first));
    }
  }

  /// Register driver on the location hub and set initial position.
  Future<void> registerDriver(double lat, double lng) async {
    if (_locationHub?.state == HubConnectionState.Connected) {
      await _locationHub!.invoke('RegisterDriverAsync',
          args: [_driverUserId, lat, lng]);
    }
  }

  /// Send location update to backend (calls DriverLocationHub.SendLocationUpdateAsync).
  Future<void> sendLocationUpdate(double lat, double lng) async {
    if (_locationHub?.state == HubConnectionState.Connected) {
      await _locationHub!.invoke('SendLocationUpdateAsync',
          args: [_driverUserId, lat, lng]);
    }
  }

  Future<void> disconnect() async {
    await _tripHub?.stop();
    await _locationHub?.stop();
    await _tripEventController.close();
  }
}
