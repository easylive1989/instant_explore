import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/route/presentation/controllers/route_controller.dart';
import 'package:context_app/features/route/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 路線規劃畫面（生成中）
///
/// 接收候選地點後呼叫 AI 生成路線，
/// 成功後自動跳轉至路線預覽畫面。
class RoutePlanningScreen extends ConsumerStatefulWidget {
  final List<Place> candidatePlaces;

  const RoutePlanningScreen({super.key, required this.candidatePlaces});

  @override
  ConsumerState<RoutePlanningScreen> createState() =>
      _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends ConsumerState<RoutePlanningScreen> {
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _generateRoute();
      });
    }
  }

  void _generateRoute() {
    final language =
        EasyLocalization.of(context)?.locale.toLanguageTag() ?? 'zh-TW';

    // 以第一個地點的位置作為使用者位置近似值
    final userLocation = widget.candidatePlaces.first.location;

    ref
        .read(routeControllerProvider.notifier)
        .generateRoute(
          candidatePlaces: widget.candidatePlaces,
          userLocation: userLocation,
          language: language,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routeControllerProvider);

    // 路線生成成功，跳轉至預覽畫面
    ref.listen<RouteState>(routeControllerProvider, (previous, current) {
      if (current.route != null && !current.isLoading) {
        context.go(
          '/route/preview',
          extra: {
            'route': current.route,
            'candidatePlaces': widget.candidatePlaces,
          },
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            ref.read(routeControllerProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text(
          'route.planning_title'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: state.error != null
            ? _ErrorContent(
                error: state.error!,
                onRetry: _generateRoute,
                onBack: () {
                  ref.read(routeControllerProvider.notifier).reset();
                  context.pop();
                },
              )
            : _LoadingContent(),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'route.generating'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'route.generating_hint'.tr(),
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorContent({
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            'route.generate_error'.tr(),
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimaryDark,
                  side: const BorderSide(color: AppColors.textSecondaryDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text('route.back'.tr()),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text('route.retry'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
