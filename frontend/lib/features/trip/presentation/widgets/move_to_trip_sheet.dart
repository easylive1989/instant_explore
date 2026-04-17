import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 顯示旅程選擇底部表單，讓使用者把條目移到指定旅程或未分類。
///
/// 回傳 [TripSelection]：
/// - `null`：使用者取消
/// - `TripSelection(null)`：移到未分類
/// - `TripSelection(id)`：移到該 trip
Future<TripSelection?> showMoveToTripSheet({
  required BuildContext context,
  String? currentTripId,
  int itemCount = 1,
}) {
  return showModalBottomSheet<TripSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) =>
        _MoveToTripSheet(currentTripId: currentTripId, itemCount: itemCount),
  );
}

/// 底部表單回傳的選擇結果。`tripId == null` 代表未分類。
class TripSelection {
  final String? tripId;
  const TripSelection(this.tripId);
}

class _MoveToTripSheet extends ConsumerWidget {
  final String? currentTripId;
  final int itemCount;

  const _MoveToTripSheet({
    required this.currentTripId,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                itemCount > 1
                    ? 'trip.move_title_batch'.tr(args: ['$itemCount'])
                    : 'trip.move_title'.tr(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Flexible(
              child: tripsAsync.when(
                data: (trips) => _buildList(context, trips, colorScheme),
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '${'trip.load_error'.tr()}: $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text('trip.create_action'.tr()),
              onTap: () {
                Navigator.pop(context);
                context.push('/trip/edit');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Trip> trips,
    ColorScheme colorScheme,
  ) {
    return ListView(
      shrinkWrap: true,
      children: [
        _MoveOption(
          icon: Icons.inbox_outlined,
          label: 'trip.uncategorized'.tr(),
          selected: currentTripId == null,
          onTap: () => Navigator.pop(context, const TripSelection(null)),
        ),
        if (trips.isNotEmpty) const Divider(height: 1),
        for (final trip in trips)
          _MoveOption(
            icon: Icons.flag_outlined,
            label: trip.name,
            selected: currentTripId == trip.id,
            onTap: () => Navigator.pop(context, TripSelection(trip.id)),
          ),
      ],
    );
  }
}

class _MoveOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoveOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
