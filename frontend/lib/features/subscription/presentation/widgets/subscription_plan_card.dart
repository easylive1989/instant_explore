import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

/// Paywall plan card in the Midnight Kyoto brand language.
///
/// Renders a single subscription plan inside a glass-style container.
/// The billed price is the most visually dominant element on the card
/// to satisfy App Store Guideline 3.1.2(c).
class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({super.key, required this.state, this.onRetry});

  final SubscriptionPlanCardState state;
  final VoidCallback? onRetry;

  static const double _priceFontSize = 40;
  static const double _periodFontSize = 14;
  static const double _planLabelFontSize = 11;
  static const double _bulletFontSize = 14;
  static const double _noticeFontSize = 11;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceDarkCard, AppColors.surfaceDark],
        ),
        border: Border.all(color: AppColors.glassBorder),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14137FEC),
            blurRadius: 40,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: switch (state) {
        SubscriptionPlanCardStateLoading() => const _Loading(),
        SubscriptionPlanCardStateError(:final message) => _Error(
          message: message,
          onRetry: onRetry,
        ),
        SubscriptionPlanCardStateReady(
          :final planLabel,
          :final priceString,
          :final periodLabel,
          :final bullets,
          :final autoRenewNotice,
        ) =>
          _Ready(
            planLabel: planLabel,
            priceString: priceString,
            periodLabel: periodLabel,
            bullets: bullets,
            autoRenewNotice: autoRenewNotice,
          ),
      },
    );
  }
}

/// Discriminated state for [SubscriptionPlanCard].
sealed class SubscriptionPlanCardState {
  const SubscriptionPlanCardState();

  const factory SubscriptionPlanCardState.loading() =
      SubscriptionPlanCardStateLoading;

  const factory SubscriptionPlanCardState.error({required String message}) =
      SubscriptionPlanCardStateError;

  const factory SubscriptionPlanCardState.ready({
    required String planLabel,
    required String priceString,
    required String periodLabel,
    required List<String> bullets,
    required String autoRenewNotice,
  }) = SubscriptionPlanCardStateReady;
}

final class SubscriptionPlanCardStateLoading extends SubscriptionPlanCardState {
  const SubscriptionPlanCardStateLoading();
}

final class SubscriptionPlanCardStateError extends SubscriptionPlanCardState {
  const SubscriptionPlanCardStateError({required this.message});
  final String message;
}

final class SubscriptionPlanCardStateReady extends SubscriptionPlanCardState {
  const SubscriptionPlanCardStateReady({
    required this.planLabel,
    required this.priceString,
    required this.periodLabel,
    required this.bullets,
    required this.autoRenewNotice,
  });

  final String planLabel;
  final String priceString;
  final String periodLabel;
  final List<String> bullets;
  final String autoRenewNotice;
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonBar(
          key: ValueKey('planCard.labelSkeleton'),
          width: 120,
          height: 12,
        ),
        SizedBox(height: 16),
        _SkeletonBar(
          key: ValueKey('planCard.priceSkeleton'),
          width: 160,
          height: 36,
        ),
        SizedBox(height: 20),
        _SkeletonBar(width: double.infinity, height: 14),
        SizedBox(height: 10),
        _SkeletonBar(width: double.infinity, height: 14),
        SizedBox(height: 10),
        _SkeletonBar(width: 180, height: 14),
      ],
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('planCard.retry'),
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.planLabel,
    required this.priceString,
    required this.periodLabel,
    required this.bullets,
    required this.autoRenewNotice,
  });

  final String planLabel;
  final String priceString;
  final String periodLabel;
  final List<String> bullets;
  final String autoRenewNotice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          planLabel,
          style: const TextStyle(
            fontSize: SubscriptionPlanCard._planLabelFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textTertiaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              priceString,
              style: const TextStyle(
                fontSize: SubscriptionPlanCard._priceFontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryDark,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              periodLabel,
              style: const TextStyle(
                fontSize: SubscriptionPlanCard._periodFontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Divider(),
        const SizedBox(height: 16),
        ...bullets.map(_bulletRow),
        const SizedBox(height: 16),
        const _Divider(),
        const SizedBox(height: 12),
        Text(
          autoRenewNotice,
          style: const TextStyle(
            fontSize: SubscriptionPlanCard._noticeFontSize,
            color: AppColors.textTertiaryDark,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _bulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✦',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: SubscriptionPlanCard._bulletFontSize,
                color: AppColors.textPrimaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.glassBorder);
  }
}
