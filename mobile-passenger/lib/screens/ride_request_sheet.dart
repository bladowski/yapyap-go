import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yapyap_passenger/models/ride_request_state.dart';
import 'package:yapyap_passenger/models/trip.dart';
import 'package:yapyap_passenger/providers/ride_request_controller.dart';

class RideRequestBottomSheet extends ConsumerWidget {
  const RideRequestBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideRequestProvider);
    final controller = ref.read(rideRequestProvider.notifier);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: switch (state.step) {
            RideRequestStep.selectingDropoff =>
              _SelectingDropoff(controller: controller),
            RideRequestStep.fetchingEstimates => const _FetchingEstimates(),
            RideRequestStep.selectingVehicle => const _SelectingVehicle(),
            RideRequestStep.searchingForDriver => const _SearchingForDriver(),
            RideRequestStep.driverAssigned => const _DriverAssigned(),
          },
        ),
      ),
    );
  }
}

class _SelectingDropoff extends StatelessWidget {
  final RideRequestController controller;
  const _SelectingDropoff({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Where to?',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onTap: () {
            controller.setPickup(-6.1659, 39.1990);
            controller.selectDropoff(-6.1300, 39.2200);
            controller.fetchEstimates();
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              controller.setPickup(-6.1659, 39.1990);
              controller.selectDropoff(-6.1300, 39.2200);
              controller.fetchEstimates();
            },
            icon: const Icon(Icons.my_location, size: 20),
            label: const Text('Use current location → Nungwi'),
          ),
        ),
      ],
    );
  }
}

class _FetchingEstimates extends StatelessWidget {
  const _FetchingEstimates();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20),
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          'Calculating fares...',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

class _SelectingVehicle extends ConsumerWidget {
  const _SelectingVehicle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideRequestProvider);
    final controller = ref.read(rideRequestProvider.notifier);
    final estimates = controller.estimates;

    final icons = {
      'BodaBoda': Icons.motorcycle,
      'TukTuk': Icons.directions_car,
      'Car': Icons.local_taxi,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose a ride',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...estimates.map((est) {
          final isSelected = est.category == state.selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => controller.setCategory(est.category),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(icons[est.category] ?? Icons.directions_car,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(est.category,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(
                            '${(est.durationSeconds / 60).toStringAsFixed(0)} min · ${(est.distanceMeters / 1000).toStringAsFixed(1)} km',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${est.estimatedPriceTzs.toStringAsFixed(0)} TZS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Payment: ', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Cash'),
              selected: state.paymentMethod == 'Cash',
              onSelected: (_) => controller.setPaymentMethod('Cash'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Stripe'),
              selected: state.paymentMethod == 'Stripe',
              onSelected: (_) => controller.setPaymentMethod('Stripe'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => controller.confirmRide(),
            icon: const Icon(Icons.check),
            label: const Text('Confirm Ride',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchingForDriver extends StatelessWidget {
  const _SearchingForDriver();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 20),
        const Text(
          'Searching for a driver...',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Finding the nearest available driver',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DriverAssigned extends StatelessWidget {
  const _DriverAssigned();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Driver is on the way!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Your driver will arrive shortly',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
