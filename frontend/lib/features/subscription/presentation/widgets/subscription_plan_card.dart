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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHigh,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
        ),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('planCard.retry'),
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          planLabel,
          style: TextStyle(
            fontSize: SubscriptionPlanCard._planLabelFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              priceString,
              style: TextStyle(
                fontSize: SubscriptionPlanCard._priceFontSize,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              periodLabel,
              style: TextStyle(
                fontSize: SubscriptionPlanCard._periodFontSize,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Divider(),
        const SizedBox(height: 16),
        ...bullets.map((b) => _bulletRow(b, cs)),
        const SizedBox(height: 16),
        const _Divider(),
        const SizedBox(height: 12),
        Text(
          autoRenewNotice,
          style: TextStyle(
            fontSize: SubscriptionPlanCard._noticeFontSize,
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _bulletRow(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✦',
            style: TextStyle(fontSize: 14, color: cs.primary, height: 1.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: SubscriptionPlanCard._bulletFontSize,
                color: cs.onSurface,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      child: const SizedBox(height: 1),
    );
  }
}
