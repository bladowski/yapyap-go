import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:yapyap_passenger/providers/app_providers.dart';
import 'package:yapyap_passenger/providers/ride_request_controller.dart';
import 'package:yapyap_passenger/screens/ride_request_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MapboxMap? _mapboxMap;
  bool _mapReady = false;

  // Stone Town, Zanzibar center
  static const _defaultCenter = Point(
    coordinates: Position(-6.1659, 39.1990),
  );

  @override
  void initState() {
    super.initState();
    _connectSignalR();
  }

  Future<void> _connectSignalR() async {
    final signalR = ref.read(signalRProvider);
    await signalR.connect();

    signalR.onTripEvent('TripAccepted', (args) {
      if (args?.isNotEmpty == true) {
        print('Trip accepted: ${args!.first}');
      }
    });

    signalR.onTripEvent('TripUpdated', (args) {
      if (args?.isNotEmpty == true) {
        print('Trip updated: ${args!.first}');
      }
    });

    signalR.onDriverLocation((args) {
      if (args?.isNotEmpty == true) {
        print('Driver location: ${args!.first}');
      }
    });
  }

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    setState(() => _mapReady = true);
  }

  void _onRequestRide() {
    ref.read(rideRequestProvider.notifier).reset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RideRequestBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapWidget'),
            cameraOptions: CameraOptions(
              center: _defaultCenter,
              zoom: 14.0,
            ),
            resourceOptions: ResourceOptions(
              accessToken: 'YOUR_MAPBOX_TOKEN_HERE',
            ),
            onMapCreated: _onMapCreated,
          ),
          // SignalR connection indicator
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Consumer(
              builder: (context, ref, _) {
                final connected = ref.watch(signalRConnectedProvider);
                return connected.when(
                  data: (isConnected) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.green.withOpacity(0.9)
                          : Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConnected ? Icons.wifi : Icons.wifi_off,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'Connected' : 'Connecting...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Disconnected',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _onRequestRide,
              icon: const Icon(Icons.local_taxi),
              label: const Text(
                'Request Ride',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    ref.read(signalRProvider).disconnect();
    super.dispose();
  }
}
