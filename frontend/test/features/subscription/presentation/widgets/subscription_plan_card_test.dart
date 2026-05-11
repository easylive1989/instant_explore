import 'package:context_app/features/subscription/presentation/widgets/subscription_plan_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SubscriptionPlanCard', () {
    testWidgets(
      'given the loading state, when the card is shown, '
      'then it renders a price skeleton and no subscribe-ready text',
      (tester) async {
        await _pumpCard(tester, const SubscriptionPlanCardState.loading());

        expect(
          find.byKey(const ValueKey('planCard.priceSkeleton')),
          findsOneWidget,
        );
        expect(find.text('NT\$90'), findsNothing);
      },
    );

    testWidgets(
      'given a ready state, when the card is shown, '
      'then the price string is the largest font on the card',
      (tester) async {
        await _pumpCard(
          tester,
          const SubscriptionPlanCardState.ready(
            planLabel: 'MONTHLY PLAN',
            priceString: 'NT\$90',
            periodLabel: '/ month',
            bullets: ['Unlimited', 'Ad-free', 'Routes'],
            autoRenewNotice: 'Auto-renews monthly. Cancel anytime.',
            selected: true,
          ),
        );

        final priceSize = _fontSize(tester, 'NT\$90');
        final periodSize = _fontSize(tester, '/ month');
        final planLabelSize = _fontSize(tester, 'MONTHLY PLAN');
        final noticeSize =
            _fontSize(tester, 'Auto-renews monthly. Cancel anytime.');
        final bulletSize = _fontSize(tester, 'Unlimited');

        expect(priceSize, greaterThan(periodSize));
        expect(priceSize, greaterThan(planLabelSize));
        expect(priceSize, greaterThan(noticeSize));
        expect(priceSize, greaterThan(bulletSize));
      },
    );

    testWidgets(
      'given a ready state, when the card is shown, '
      'then every provided bullet appears',
      (tester) async {
        await _pumpCard(
          tester,
          const SubscriptionPlanCardState.ready(
            planLabel: 'MONTHLY PLAN',
            priceString: 'NT\$90',
            periodLabel: '/ month',
            bullets: ['Unlimited', 'Ad-free', 'Routes'],
            autoRenewNotice: 'Notice',
            selected: true, // bullets only render in the selected state
          ),
        );

        expect(find.text('Unlimited'), findsOneWidget);
        expect(find.text('Ad-free'), findsOneWidget);
        expect(find.text('Routes'), findsOneWidget);
      },
    );

    testWidgets(
      'given an error state, when the user taps retry, '
      'then onRetry is invoked exactly once',
      (tester) async {
        var retryCount = 0;
        await _pumpCard(
          tester,
          const SubscriptionPlanCardState.error(message: 'oops'),
          onRetry: () => retryCount++,
        );

        await tester.tap(find.byKey(const ValueKey('planCard.retry')));
        await tester.pump();

        expect(retryCount, 1);
        expect(find.text('oops'), findsOneWidget);
      },
    );

    testWidgets(
      'given a ready state with isBestValue=true, when the card is shown, '
      'then the Best value badge text is visible',
      (tester) async {
        await _pumpCard(
          tester,
          const SubscriptionPlanCardState.ready(
            planLabel: 'YEARLY PLAN',
            priceString: 'NT\$900',
            periodLabel: '/ year',
            bullets: ['Unlimited'],
            autoRenewNotice: 'auto',
            isBestValue: true,
          ),
        );

        expect(find.text('subscription.badge_best_value'), findsOneWidget);
      },
    );

    testWidgets(
      'given a ready state with selected=true, when the card is shown, '
      'then the selection check icon is visible',
      (tester) async {
        await _pumpCard(
          tester,
          const SubscriptionPlanCardState.ready(
            planLabel: 'MONTHLY PLAN',
            priceString: 'NT\$90',
            periodLabel: '/ month',
            bullets: ['Unlimited'],
            autoRenewNotice: 'auto',
            selected: true,
          ),
        );

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    testWidgets(
      'given selected=false, when the card is shown, '
      'then bullets are not rendered',
      (tester) async {
        await _pumpCard(
          tester,
          const SubscriptionPlanCardState.ready(
            planLabel: 'WEEKLY PLAN',
            priceString: 'NT\$30',
            periodLabel: '/ week',
            bullets: ['Unlimited', 'Ad-free'],
            autoRenewNotice: 'auto',
            selected: false,
          ),
        );

        expect(find.text('Unlimited'), findsNothing);
        expect(find.text('Ad-free'), findsNothing);
      },
    );

    testWidgets(
      'given an onTap callback, when the card is tapped, '
      'then onTap is invoked exactly once',
      (tester) async {
        var taps = 0;
        await _pumpCard(
          tester,
          SubscriptionPlanCardState.ready(
            planLabel: 'WEEKLY PLAN',
            priceString: 'NT\$30',
            periodLabel: '/ week',
            bullets: const ['Unlimited'],
            autoRenewNotice: 'auto',
            onTap: () => taps++,
          ),
        );

        await tester.tap(find.text('WEEKLY PLAN'));
        await tester.pump();

        expect(taps, 1);
      },
    );
  });
}

double _fontSize(WidgetTester tester, String text) {
  final widget = tester.widget<Text>(find.text(text));
  final size = widget.style?.fontSize;
  expect(size, isNotNull, reason: 'Text "$text" should have explicit fontSize');
  return size!;
}

Future<void> _pumpCard(
  WidgetTester tester,
  SubscriptionPlanCardState state, {
  VoidCallback? onRetry,
}) async {
  await pumpScreen(
    tester,
    child: Scaffold(
      backgroundColor: const Color(0xFF101922),
      body: Center(
        child: SubscriptionPlanCard(state: state, onRetry: onRetry),
      ),
    ),
  );
}
