import 'package:context_app/app/config/app_colors.dart';
import 'package:context_app/app/config/legal_urls.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/presentation/widgets/subscription_plan_card.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight_kyoto_backdrop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

typedef UrlLauncher = Future<bool> Function(Uri uri);

/// Midnight Kyoto paywall screen.
///
/// Displays the current subscription plan with the billed amount as the
/// dominant typographic element, a clear subscription period, and
/// functional Terms of Use and Privacy Policy links. Complies with App
/// Store Review Guidelines 3.1.2(c).
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key, UrlLauncher? launchUrl})
    : _launchUrl = launchUrl;

  final UrlLauncher? _launchUrl;

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isPurchasing = false;
  bool _isLoadingPlan = true;
  SubscriptionPlan? _plan;
  String? _planError;
  bool _showHeadline = false;
  bool _showSubheadline = false;
  bool _showPlanCard = false;

  static Future<bool> _defaultLaunchUrl(Uri uri) {
    return url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
  }

  UrlLauncher get _launchUrl => widget._launchUrl ?? _defaultLaunchUrl;

  @override
  void initState() {
    super.initState();
    _loadPlan();
    _scheduleEntryAnimation();
  }

  Future<void> _scheduleEntryAnimation() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() => _showHeadline = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _showSubheadline = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _showPlanCard = true);
  }

  Widget _entry({required bool visible, required Widget child}) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.04),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoadingPlan = true;
      _planError = null;
    });
    try {
      final plan = await ref.read(subscriptionServiceProvider).getCurrentPlan();
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _isLoadingPlan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _planError = 'subscription.plan_load_failed'.tr();
        _isLoadingPlan = false;
      });
    }
  }

  Future<void> _purchase() async {
    setState(() => _isPurchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      final result = await service.purchase();
      if (result != null && result.isPremium && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error_prefix'.tr()}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      final result = await service.restorePurchases();
      if (mounted) {
        if (result.isPremium) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('subscription.no_purchases_found'.tr())),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error_prefix'.tr()}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _openUrl(Uri uri) async {
    final opened = await _launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'common.error_prefix'.tr()}: $uri'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  SubscriptionPlanCardState _cardState() {
    if (_isLoadingPlan) return const SubscriptionPlanCardState.loading();
    if (_planError != null) {
      return SubscriptionPlanCardState.error(message: _planError!);
    }
    final plan = _plan;
    if (plan == null) {
      return SubscriptionPlanCardState.error(
        message: 'subscription.plan_load_failed'.tr(),
      );
    }
    return SubscriptionPlanCardState.ready(
      planLabel: 'subscription.plan_label'.tr(),
      priceString: plan.priceString,
      periodLabel: 'subscription.plan_period'.tr(),
      bullets: [
        'subscription.benefit_unlimited'.tr(),
        'subscription.benefit_no_ads'.tr(),
        'subscription.benefit_route'.tr(),
      ],
      autoRenewNotice: 'subscription.auto_renew_notice'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: MidnightKyotoBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AdaptiveIconButton(
                    icon: Icon(Icons.close, color: cs.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const _PremiumIcon(),
                      const SizedBox(height: 20),
                      Text(
                        'subscription.category_label'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _entry(
                        visible: _showHeadline,
                        child: Text(
                          'subscription.headline'.tr(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: cs.onSurface,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _entry(
                        visible: _showSubheadline,
                        child: Text(
                          'subscription.subheadline'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _entry(
                        visible: _showPlanCard,
                        child: SubscriptionPlanCard(
                          state: _cardState(),
                          onRetry: _loadPlan,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SubscribeButton(
                        isLoading: _isPurchasing,
                        onPressed: _isPurchasing || _plan == null
                            ? null
                            : _purchase,
                      ),
                      const SizedBox(height: 4),
                      AdaptiveButton(
                        style: AdaptiveButtonStyle.text,
                        foregroundColor: cs.onSurfaceVariant,
                        onPressed: _isPurchasing ? null : _restore,
                        child: Text(
                          'subscription.restore'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _LegalFooter(onOpen: _openUrl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumIcon extends StatelessWidget {
  const _PremiumIcon();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.25),
                  cs.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/subscription/premium_badge.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        icon: isLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.lock_open_rounded),
        label: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: AdaptiveProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : Text('subscription.subscribe'.tr()),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.onOpen});

  final Future<void> Function(Uri) onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant.withValues(alpha: 0.7);
    final linkStyle = TextStyle(
      fontSize: 12,
      color: muted,
      decoration: TextDecoration.underline,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpen(Uri.parse(LegalUrls.termsOfUse)),
          child: Text('subscription.terms'.tr(), style: linkStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('·', style: TextStyle(fontSize: 12, color: muted)),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpen(Uri.parse(LegalUrls.privacyPolicy)),
          child: Text('subscription.privacy'.tr(), style: linkStyle),
        ),
      ],
    );
  }
}
