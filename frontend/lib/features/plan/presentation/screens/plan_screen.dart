import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/ads/presentation/widgets/watch_ad_dialog.dart';
import 'package:context_app/features/plan/domain/models/plan.dart';
import 'package:context_app/features/plan/presentation/widgets/plan_card.dart';
import 'package:context_app/features/plan/providers.dart';
import 'package:context_app/features/route/providers.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Plan Tab 主畫面：顯示已儲存的路線規劃列表。
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  bool _isGenerating = false;

  Language _currentLanguage() {
    final locale = EasyLocalization.of(context)?.locale;
    return locale?.languageCode == 'zh'
        ? Language.traditionalChinese
        : Language.english;
  }

  Future<void> _generatePlan() async {
    // Disable button immediately to prevent re-entrant taps
    setState(() => _isGenerating = true);
    try {
      // Pre-flight quota check
      final status = await ref.read(usageStatusProvider.future);
      if (!status.canUse) {
        if (!mounted) return;
        final result = await showWatchAdDialog(context, ref);
        if (result == 'subscribe') {
          if (!mounted) return;
          context.pushNamed('subscription');
        }
        return;
      }

      final places = await ref
          .read(planListControllerProvider.notifier)
          .findNearbyPlaces(_currentLanguage());

      if (!mounted) return;

      if (places.length < 3) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('plan.not_enough_places'.tr())));
        return;
      }

      context.pushNamed('route_planning', extra: places);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('plan.location_failed'.tr())));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _openPlan(Plan plan) {
    ref.read(routeControllerProvider.notifier).setRoute(plan.toTourRoute());
    context.push('/route/preview');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'plan.title'.tr(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  IconButton(
                    onPressed: _isGenerating ? null : _generatePlan,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : state.plans.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.plans.length,
                      itemBuilder: (context, index) {
                        final plan = state.plans[index];
                        return PlanCard(
                          plan: plan,
                          onTap: () => _openPlan(plan),
                          onDelete: () {
                            ref
                                .read(planListControllerProvider.notifier)
                                .deletePlan(plan.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'plan.empty_title'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'plan.empty_subtitle'.tr(),
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
