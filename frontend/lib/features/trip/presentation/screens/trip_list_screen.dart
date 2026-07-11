import 'package:context_app/app/config/app_colors.dart';
import 'package:context_app/features/trip/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';

/// 顯示所有旅程 + 「未分類」群組的列表頁。
class TripListScreen extends ConsumerWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTrips = ref.watch(tripsProvider);
    final asyncCounts = ref.watch(tripItemCountsProvider);
    final currentTripId = ref.watch(currentTripIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('trip.list_title'.tr()),
        actions: [
          AdaptiveIconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/trip/edit'),
          ),
        ],
      ),
      body: asyncTrips.when(
        data: (trips) {
          final counts = asyncCounts.asData?.value ?? const <String?, int>{};
          return TripGrid(
            trips: trips,
            counts: counts,
            currentTripId: currentTripId,
          );
        },
        loading: () => const Center(child: AdaptiveProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '${'trip.load_error'.tr()}: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
