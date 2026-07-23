import 'dart:async';
import 'dart:convert';
import 'package:signalr_core/signalr_core.dart';

class SignalRService {
  static const _baseUrl = 'http://10.0.2.2:5180';
  static const _passengerUserId = 'eca1143b-5cae-4867-ab85-403909324899';

  HubConnection? _tripHub;
  HubConnection? _locationHub;

  final _tripEventController = StreamController<String>.broadcast();
  final _driverLocationController = StreamController<Map<String, dynamic>>.broadcast();

  /// Broadcast stream of raw JSON trip event payloads.
  Stream<String> get tripEventStream => _tripEventController.stream;

  /// Broadcast stream of parsed driver location updates.
  Stream<Map<String, dynamic>> get driverLocationStream =>
      _driverLocationController.stream;

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

    _tripHub!.on('TripAccepted', _onTripEvent);
    _tripHub!.on('TripUpdated', _onTripEvent);
    _locationHub!.on('DriverLocationUpdated', _onDriverLocation);

    await _tripHub!.start();
    await _locationHub!.start();

    if (_tripHub!.state == HubConnectionState.Connected) {
      await _tripHub!.invoke('RegisterAsync', args: [_passengerUserId]);
    }
  }

  void _onTripEvent(List<Object?>? args) {
    if (args?.isNotEmpty == true && args!.first is String) {
      _tripEventController.add(args.first as String);
    } else if (args?.isNotEmpty == true) {
      _tripEventController.add(jsonEncode(args!.first));
    }
  }

  void _onDriverLocation(List<Object?>? args) {
    if (args?.isNotEmpty == true && args!.first is Map) {
      _driverLocationController.add(args.first as Map<String, dynamic>);
    } else if (args?.isNotEmpty == true) {
      try {
        final map = jsonDecode(args!.first.toString()) as Map<String, dynamic>;
        _driverLocationController.add(map);
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    await _tripHub?.stop();
    await _locationHub?.stop();
    await _tripEventController.close();
    await _driverLocationController.close();
  }
}
