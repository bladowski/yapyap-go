import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yapyap_driver/models/driver_state.dart';
import 'package:yapyap_driver/providers/driver_state_controller.dart';

class ActiveTripPanel extends ConsumerWidget {
  const ActiveTripPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(
      driverStateProvider.select((s) => s.activeTrip),
    );
    final isLoading = ref.watch(
      driverStateProvider.select((s) => s.isLoading),
    );
    final controller = ref.read(driverStateProvider.notifier);

    if (trip == null) return const SizedBox.shrink();

    final icons = {
      'BodaBoda': Icons.motorcycle,
      'TukTuk': Icons.directions_car,
      'Car': Icons.local_taxi,
    };

    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor(trip.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(trip.status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(trip.status),
                  ),
                ),
                const Spacer(),
                Icon(icons[trip.category] ?? Icons.directions_car, size: 22),
                const SizedBox(width: 6),
                Text(trip.category,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),

            // Destination info
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heading to: ${trip.targetLabel}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Passenger: ${trip.passengerName}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (trip.estimatedPriceTzs != null)
                  Text(
                    '${trip.estimatedPriceTzs!.toStringAsFixed(0)} TZS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Action button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading ? null : () => controller.advanceTripStatus(),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_actionIcon(trip.status)),
                label: Text(
                  isLoading ? 'Updating...' : trip.actionLabel,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _actionColor(trip.status),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'DriverAssigned' => Colors.blue,
        'DriverArrived' => Colors.orange,
        'InProgress' => Colors.green,
        _ => Colors.grey,
      };

  String _statusLabel(String status) => switch (status) {
        'DriverAssigned' => 'En Route to Pickup',
        'DriverArrived' => 'Waiting at Pickup',
        'InProgress' => 'Trip in Progress',
        _ => status,
      };

  IconData _actionIcon(String status) => switch (status) {
        'DriverAssigned' => Icons.flag,
        'DriverArrived' => Icons.play_arrow,
        'InProgress' => Icons.stop,
        _ => Icons.check,
      };

  Color _actionColor(String status) => switch (status) {
        'DriverAssigned' => Colors.blue,
        'DriverArrived' => Colors.orange,
        'InProgress' => Colors.green,
        _ => Colors.grey,
      };
}
