import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/narration/presentation/screens/select_narration_aspect_screen.dart';
import 'package:context_app/features/route/presentation/widgets/route_progress_indicator.dart';
import 'package:context_app/features/route/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// 路線導覽畫面
///
/// 顯示當前停靠站的詳細資訊，提供導航、開始導覽、
/// 前往下一站等操作。使用 PopScope 攔截返回防止意外退出。
class RouteNavigationScreen extends ConsumerWidget {
  const RouteNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final currentIndex = state.currentStopIndex;
    final currentStop = route.stops[currentIndex];
    final isLastStop = currentIndex >= route.stops.length - 1;
    final place = currentStop.place;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _showExitDialog(context);
        if (shouldLeave == true && context.mounted) {
          ref.read(routeControllerProvider.notifier).reset();
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Column(
            children: [
              // 頂部列
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () async {
                        final shouldLeave = await _showExitDialog(context);
                        if (shouldLeave == true && context.mounted) {
                          ref.read(routeControllerProvider.notifier).reset();
                          context.go('/');
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        route.title,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // 進度指示器
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: RouteProgressIndicator(
                  totalStops: route.stops.length,
                  currentIndex: currentIndex,
                ),
              ),
              const SizedBox(height: 16),
              // 當前站詳細資訊
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 站次標籤
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'route.stop_label'.tr(
                            args: [
                              (currentIndex + 1).toString(),
                              route.stops.length.toString(),
                            ],
                          ),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 地點名稱
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 地址
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.textSecondaryDark,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              place.formattedAddress,
                              style: const TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 概覽
                      if (currentStop.overview != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            currentStop.overview!,
                            style: const TextStyle(
                              color: AppColors.textPrimaryDark,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // 導航到這裡按鈕
                      _ActionButton(
                        icon: Icons.navigation_outlined,
                        label: 'route.navigate_here'.tr(),
                        color: AppColors.primary,
                        onPressed: () => _openGoogleMaps(
                          place.location.latitude,
                          place.location.longitude,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 開始導覽按鈕
                      _ActionButton(
                        icon: Icons.headphones,
                        label: 'route.start_narration'.tr(),
                        color: AppColors.success,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SelectNarrationAspectScreen(place: place),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // 下一站的距離資訊
                      if (!isLastStop &&
                          currentStop.distanceToNext != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.directions_walk,
                                color: AppColors.textSecondaryDark,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'route.next_stop_info'.tr(
                                  args: [
                                    currentStop.walkingTimeToNext
                                            ?.round()
                                            .toString() ??
                                        '-',
                                    _formatDistance(
                                      currentStop.distanceToNext!,
                                    ),
                                  ],
                                ),
                                style: const TextStyle(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // 底部導航按鈕
              _NavigationButtons(
                currentIndex: currentIndex,
                totalStops: route.stops.length,
                isLastStop: isLastStop,
                onPrevious: () {
                  ref.read(routeControllerProvider.notifier).goToPreviousStop();
                },
                onNext: () {
                  ref.read(routeControllerProvider.notifier).goToNextStop();
                },
                onEndRoute: () {
                  ref.read(routeControllerProvider.notifier).reset();
                  context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'route.exit_title'.tr(),
          style: const TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Text(
          'route.exit_message'.tr(),
          style: const TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'route.cancel'.tr(),
              style: const TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'route.confirm_exit'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=walking',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  final int currentIndex;
  final int totalStops;
  final bool isLastStop;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onEndRoute;

  const _NavigationButtons({
    required this.currentIndex,
    required this.totalStops,
    required this.isLastStop,
    required this.onPrevious,
    required this.onNext,
    required this.onEndRoute,
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
      child: Row(
        children: [
          if (currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('route.previous_stop'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimaryDark,
                  side: const BorderSide(color: AppColors.textSecondaryDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          if (currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: currentIndex > 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: isLastStop ? onEndRoute : onNext,
              icon: Icon(
                isLastStop ? Icons.flag : Icons.arrow_forward,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                isLastStop ? 'route.end_route'.tr() : 'route.next_stop'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStop
                    ? AppColors.success
                    : AppColors.primary,
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
