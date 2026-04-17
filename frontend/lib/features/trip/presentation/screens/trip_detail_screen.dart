import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/presentation/widgets/quick_guide_timeline_entry.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/presentation/widgets/move_to_trip_sheet.dart';
import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 顯示單一 Trip 的條目時間軸。
///
/// 傳入 `tripId = null` 代表顯示「未分類」（tripId 為 null 的條目）。
class TripDetailScreen extends ConsumerStatefulWidget {
  final String? tripId;

  const TripDetailScreen({super.key, this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;
  bool _moving = false;

  bool get _isUncategorized => widget.tripId == null;

  void _enterSelectionMode() {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<JourneyItem> items) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(items.map((e) => e.id));
    });
  }

  Future<void> _moveSelected(List<JourneyItem> items) async {
    if (_selectedIds.isEmpty || _moving) return;
    final selection = await showMoveToTripSheet(
      context: context,
      currentTripId: widget.tripId,
      itemCount: _selectedIds.length,
    );
    if (selection == null) return;
    if (selection.tripId == widget.tripId) {
      _exitSelectionMode();
      return;
    }
    setState(() => _moving = true);
    try {
      final journeyRepo = ref.read(journeyRepositoryProvider);
      final quickGuideRepo = ref.read(quickGuideRepositoryProvider);
      await Future.wait(
        items.where((it) => _selectedIds.contains(it.id)).map((item) {
          return switch (item) {
            NarrationJourneyItem(:final entry) => journeyRepo.save(
              entry.copyWithTripId(selection.tripId),
            ),
            QuickGuideJourneyItem(:final entry) => quickGuideRepo.save(
              entry.copyWithTripId(selection.tripId),
            ),
          };
        }),
      );
      ref.invalidate(allJourneyItemsProvider);
      if (mounted) _exitSelectionMode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error_prefix'.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = _isUncategorized
        ? const AsyncValue<Trip?>.data(null)
        : ref.watch(tripByIdProvider(widget.tripId!));
    final itemsAsync = ref.watch(journeyItemsForTripProvider(widget.tripId));
    final items = itemsAsync.asData?.value ?? const <JourneyItem>[];

    return Scaffold(
      appBar: _buildAppBar(tripAsync, items),
      body: Column(
        children: [
          if (!_isUncategorized && !_selectionMode)
            tripAsync.when(
              data: (trip) => trip == null
                  ? const SizedBox.shrink()
                  : _TripMetaHeader(trip: trip),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          Expanded(
            child: _ItemsList(
              itemsAsync: itemsAsync,
              selectionMode: _selectionMode,
              selectedIds: _selectedIds,
              onToggleSelection: _toggleSelection,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectionMode ? _buildSelectionBar(items) : null,
    );
  }

  AppBar _buildAppBar(AsyncValue<Trip?> tripAsync, List<JourneyItem> items) {
    if (_selectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        ),
        title: Text('trip.selected_count'.tr(args: ['${_selectedIds.length}'])),
        actions: [
          TextButton(
            onPressed: items.isEmpty ? null : () => _selectAll(items),
            child: Text('trip.select_all'.tr()),
          ),
        ],
      );
    }

    return AppBar(
      title: tripAsync.when(
        data: (trip) => Text(
          _isUncategorized
              ? 'trip.uncategorized'.tr()
              : (trip?.name ?? 'trip.not_found'.tr()),
        ),
        loading: () => const Text(''),
        error: (_, _) => Text('trip.not_found'.tr()),
      ),
      actions: [
        if (_isUncategorized && items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'trip.select_action'.tr(),
            onPressed: _enterSelectionMode,
          )
        else if (!_isUncategorized)
          _TripMenuButton(tripId: widget.tripId!),
      ],
    );
  }

  Widget _buildSelectionBar(List<JourneyItem> items) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: FilledButton.icon(
          onPressed: _selectedIds.isEmpty || _moving
              ? null
              : () => _moveSelected(items),
          icon: _moving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.drive_file_move_outlined),
          label: Text('trip.move_selected'.tr()),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ),
    );
  }
}

class _TripMetaHeader extends StatelessWidget {
  final Trip trip;
  const _TripMetaHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final range = _formatDateRange(trip.startDate, trip.endDate);
    if (range == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Icon(Icons.event, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            range,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String? _formatDateRange(DateTime? start, DateTime? end) {
    final fmt = DateFormat.yMMMd();
    if (start == null && end == null) return null;
    if (start != null && end != null) {
      return '${fmt.format(start)} – ${fmt.format(end)}';
    }
    return fmt.format(start ?? end!);
  }
}

class _TripMenuButton extends ConsumerWidget {
  final String tripId;

  const _TripMenuButton({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTripId = ref.watch(currentTripIdProvider);
    final isCurrent = currentTripId == tripId;

    return PopupMenuButton<_TripMenuAction>(
      onSelected: (action) => _handleAction(context, ref, action, isCurrent),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _TripMenuAction.setCurrent,
          child: Text(
            isCurrent ? 'trip.end_current'.tr() : 'trip.set_as_current'.tr(),
          ),
        ),
        PopupMenuItem(
          value: _TripMenuAction.edit,
          child: Text('trip.edit_action'.tr()),
        ),
        PopupMenuItem(
          value: _TripMenuAction.delete,
          child: Text(
            'trip.delete_action'.tr(),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _TripMenuAction action,
    bool isCurrent,
  ) async {
    switch (action) {
      case _TripMenuAction.setCurrent:
        await ref
            .read(currentTripIdProvider.notifier)
            .setCurrentTripId(isCurrent ? null : tripId);
      case _TripMenuAction.edit:
        if (context.mounted) context.push('/trip/edit/$tripId');
      case _TripMenuAction.delete:
        final confirmed = await _confirmDelete(context);
        if (!confirmed) return;
        // 孤兒化：把屬於此 trip 的條目 tripId 清成 null，回到「未分類」。
        await _orphanItemsOfTrip(ref, tripId);
        await ref.read(tripRepositoryProvider).delete(tripId);
        if (isCurrent) {
          await ref.read(currentTripIdProvider.notifier).clear();
        }
        ref.invalidate(tripsProvider);
        ref.invalidate(allJourneyItemsProvider);
        if (context.mounted) context.pop();
    }
  }

  Future<void> _orphanItemsOfTrip(WidgetRef ref, String tripId) async {
    final journeyRepo = ref.read(journeyRepositoryProvider);
    final quickGuideRepo = ref.read(quickGuideRepositoryProvider);
    final journeyEntries = await journeyRepo.getAll();
    final quickGuideEntries = await quickGuideRepo.getAll();
    await Future.wait([
      for (final e in journeyEntries.where((e) => e.tripId == tripId))
        journeyRepo.save(e.copyWithTripId(null)),
      for (final e in quickGuideEntries.where((e) => e.tripId == tripId))
        quickGuideRepo.save(e.copyWithTripId(null)),
    ]);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('trip.delete_title'.tr()),
        content: Text('trip.delete_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('trip.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'trip.delete_confirm'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

enum _TripMenuAction { setCurrent, edit, delete }

class _ItemsList extends StatelessWidget {
  final AsyncValue<List<JourneyItem>> itemsAsync;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String id) onToggleSelection;

  const _ItemsList({
    required this.itemsAsync,
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'trip.no_items'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isLast = index == items.length - 1;
            final entryWidget = switch (item) {
              NarrationJourneyItem(:final entry) => TimelineEntry(
                key: ValueKey(item.id),
                entry: entry,
                isLast: isLast,
              ),
              QuickGuideJourneyItem(:final entry) => QuickGuideTimelineEntry(
                key: ValueKey(item.id),
                entry: entry,
                isLast: isLast,
              ),
            };

            if (!selectionMode) return entryWidget;

            final isSelected = selectedIds.contains(item.id);
            return _SelectableEntry(
              isSelected: isSelected,
              onTap: () => onToggleSelection(item.id),
              child: entryWidget,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '${'trip.load_error'.tr()}: $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _SelectableEntry extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableEntry({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        AbsorbPointer(child: child),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            child: Container(
              margin: TimelineEntry.contentPadding,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
