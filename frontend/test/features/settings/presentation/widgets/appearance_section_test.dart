import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/presentation/widgets/appearance_section.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('AppearanceSection', () {
    testWidgets('renders the three appearance controls', (tester) async {
      await pumpScreen(
        tester,
        child: const SingleChildScrollView(child: AppearanceSection()),
      );
      expect(find.text('settings.accent_terracotta'), findsOneWidget);
      expect(find.text('settings.reading_paper'), findsOneWidget);
      expect(find.text('settings.font_serif'), findsOneWidget);
    });

    testWidgets('tapping an accent option updates the notifier',
        (tester) async {
      await pumpScreen(
        tester,
        child: const SingleChildScrollView(child: AppearanceSection()),
      );
      await tester.tap(find.text('settings.accent_sage'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppearanceSection)),
      );
      expect(
        container.read(appearanceNotifierProvider).accent,
        BrandAccent.sage,
      );
    });
  });
}
