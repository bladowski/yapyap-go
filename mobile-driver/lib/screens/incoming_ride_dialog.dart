import 'package:flutter/material.dart';
import 'package:yapyap_driver/models/driver_state.dart';

class IncomingRideDialog extends StatelessWidget {
  final IncomingTrip trip;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingRideDialog({
    super.key,
    required this.trip,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final icons = {
      'BodaBoda': Icons.motorcycle,
      'TukTuk': Icons.directions_car,
      'Car': Icons.local_taxi,
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing indicator
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                'New Ride Request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              // Trip details
              _DetailRow(
                icon: icons[trip.category] ?? Icons.directions_car,
                label: trip.category,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.person,
                label: trip.passengerName,
              ),
              if (trip.estimatedPriceTzs != null) ...[
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.monetization_on,
                  label:
                      '${trip.estimatedPriceTzs!.toStringAsFixed(0)} TZS',
                ),
              ],
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Accept Ride',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}
