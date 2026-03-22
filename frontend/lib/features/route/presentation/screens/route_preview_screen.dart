import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/presentation/controllers/route_controller.dart';
import 'package:context_app/features/route/presentation/widgets/route_edit_sheet.dart';
import 'package:context_app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:context_app/features/route/presentation/widgets/route_timeline_widget.dart';
import 'package:context_app/features/route/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 路線預覽畫面
///
/// 顯示 AI 生成的路線詳情，包含路線標題、總覽統計、
/// 時間軸視圖。支援編輯模式與開始導覽。
class RoutePreviewScreen extends ConsumerStatefulWidget {
  const RoutePreviewScreen({super.key});

  @override
  ConsumerState<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends ConsumerState<RoutePreviewScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routeControllerProvider);
    final route = state.route;

    if (route == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text(
            'route.no_route'.tr(),
            style: const TextStyle(color: AppColors.textPrimaryDark),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            ref.read(routeControllerProvider.notifier).reset();
            context.go('/');
          },
        ),
        title: Text(
          _isEditMode ? 'route.edit_route'.tr() : 'route.preview_title'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isEditMode)
            TextButton(
              onPressed: () => setState(() => _isEditMode = false),
              child: Text(
                'route.done'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 路線摘要區
          _RouteHeader(
            title: route.title,
            totalStops: route.stops.length,
            estimatedDuration: route.estimatedDuration,
            totalDistance: route.totalDistance,
          ),
          // 主內容
          Expanded(
            child: _isEditMode
                ? _EditModeContent(
                    stops: route.stops,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(routeControllerProvider.notifier)
                          .reorderStops(oldIndex, newIndex);
                    },
                    onRemove: (index) {
                      ref
                          .read(routeControllerProvider.notifier)
                          .removeStop(index);
                    },
                    canRemove: route.stops.length > 2,
                  )
                : RouteTimelineWidget(stops: route.stops),
          ),
          // 底部按鈕
          _BottomActions(
            isEditMode: _isEditMode,
            onEdit: () => setState(() => _isEditMode = true),
            onStartTour: () => context.go('/route/navigate'),
            onAddStop: () => _showAddStopSheet(context, state),
          ),
        ],
      ),
    );
  }

  void _showAddStopSheet(BuildContext context, RouteState state) {
    final routeIds = state.route?.stops.map((s) => s.place.id).toSet() ?? {};
    final available = state.candidatePlaces
        .where((p) => !routeIds.contains(p.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RouteEditSheet(
        availablePlaces: available,
        onAddPlace: (place) {
          ref.read(routeControllerProvider.notifier).addStop(place);
        },
      ),
    );
  }
}

class _RouteHeader extends StatelessWidget {
  final String title;
  final int totalStops;
  final double estimatedDuration;
  final double totalDistance;

  const _RouteHeader({
    required this.title,
    required this.totalStops,
    required this.estimatedDuration,
    required this.totalDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.place,
                label: 'route.stops_count'.tr(
                  namedArgs: {'count': totalStops.toString()},
                ),
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.schedule,
                label: 'route.duration_value'.tr(
                  namedArgs: {'minutes': estimatedDuration.round().toString()},
                ),
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.straighten,
                label: _formatDistance(totalDistance),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _EditModeContent extends StatelessWidget {
  final List<RouteStop> stops;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onRemove;
  final bool canRemove;

  const _EditModeContent({
    required this.stops,
    required this.onReorder,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: stops.length,
      onReorder: onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) =>
              Material(color: Colors.transparent, elevation: 4, child: child),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final stop = stops[index];
        return Padding(
          key: ValueKey(stop.place.id),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // 拖曳把手
              const Icon(
                Icons.drag_handle,
                color: AppColors.textSecondaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              // 卡片
              Expanded(child: RouteStopCard(stop: stop)),
              const SizedBox(width: 4),
              // 上下移動按鈕
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MoveButton(
                    icon: Icons.keyboard_arrow_up,
                    enabled: index > 0,
                    onPressed: () => onReorder(index, index - 1),
                  ),
                  _MoveButton(
                    icon: Icons.keyboard_arrow_down,
                    enabled: index < stops.length - 1,
                    onPressed: () => onReorder(index, index + 2),
                  ),
                ],
              ),
              // 刪除按鈕
              IconButton(
                onPressed: canRemove ? () => onRemove(index) : null,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: canRemove
                      ? AppColors.error
                      : AppColors.textSecondaryDark.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoveButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _MoveButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          color: enabled
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryDark.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final bool isEditMode;
  final VoidCallback onEdit;
  final VoidCallback onStartTour;
  final VoidCallback onAddStop;

  const _BottomActions({
    required this.isEditMode,
    required this.onEdit,
    required this.onStartTour,
    required this.onAddStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: isEditMode
          ? ElevatedButton.icon(
              onPressed: onAddStop,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'route.add_stop'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text('route.edit'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryDark,
                      side: const BorderSide(
                        color: AppColors.textSecondaryDark,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onStartTour,
                    icon: const Icon(
                      Icons.navigation_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      'route.start_tour'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
