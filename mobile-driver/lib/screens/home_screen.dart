import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:yapyap_driver/core/signalr_service.dart';
import 'package:yapyap_driver/models/driver_state.dart';
import 'package:yapyap_driver/providers/app_providers.dart';
import 'package:yapyap_driver/providers/driver_state_controller.dart';
import 'package:yapyap_driver/screens/incoming_ride_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _defaultCenter = Point(
    coordinates: Position(-6.1659, 39.1990),
  );

  @override
  void initState() {
    super.initState();
    _connectSignalR();
  }

  Future<void> _connectSignalR() async {
    await ref.read(signalRProvider).connect();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverStateProvider);
    final controller = ref.read(driverStateProvider.notifier);

    // Show incoming ride dialog.
    if (state.incomingTrip != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIncomingRideDialog(context, state.incomingTrip!, controller);
      });
    }

    // Show error snackbar.
    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: controller.clearError,
            ),
          ),
        );
        controller.clearError();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapWidget'),
            cameraOptions: const CameraOptions(
              center: _defaultCenter,
              zoom: 14.0,
            ),
            resourceOptions: const ResourceOptions(
              accessToken: 'YOUR_MAPBOX_TOKEN_HERE',
            ),
          ),
          // Wallet balance card
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: _WalletCard(balance: state.walletBalance),
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
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () => controller.toggleOnline(),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.isOnline ? Colors.red : const Color(0xFF00B341),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      state.isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showIncomingRideDialog(
    BuildContext context,
    IncomingTrip trip,
    DriverStateController controller,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingRideDialog(
        trip: trip,
        onAccept: () {
          controller.acceptTrip(trip.tripId);
          Navigator.of(context).pop();
        },
        onDecline: () {
          controller.dismissTrip();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final double balance;
  const _WalletCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.account_balance_wallet : Icons.warning,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Balance: ${balance.toStringAsFixed(0)} TZS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
