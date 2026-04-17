import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/presentation/widgets/trip_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 共用的 Trip 卡片網格，包含未分類卡片。
class TripGrid extends StatelessWidget {
  final List<Trip> trips;
  final Map<String?, int> counts;
  final String? currentTripId;
  final EdgeInsetsGeometry padding;

  const TripGrid({
    super.key,
    required this.trips,
    required this.counts,
    required this.currentTripId,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final uncategorizedCount = counts[null] ?? 0;
    final showUncategorized = uncategorizedCount > 0 || trips.isEmpty;

    if (trips.isEmpty && !showUncategorized) {
      return Center(child: Text('trip.empty'.tr()));
    }

    final cards = <Widget>[
      if (showUncategorized)
        UncategorizedTripCard(
          itemCount: uncategorizedCount,
          onTap: () => context.push('/trip/uncategorized'),
        ),
      ...trips.map(
        (trip) => TripCard(
          trip: trip,
          itemCount: counts[trip.id] ?? 0,
          isCurrent: trip.id == currentTripId,
          onTap: () => context.push('/trip/${trip.id}'),
        ),
      ),
    ];

    return GridView.count(
      padding: padding,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: cards,
    );
  }
}
