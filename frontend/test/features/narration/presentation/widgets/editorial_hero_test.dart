import 'package:context_app/features/narration/presentation/widgets/editorial_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('EditorialHeroBackground', () {
    testWidgets(
      'given a place with no photo, when rendered, '
      'then it falls back to a category glyph (an Icon), not a network image',
      (tester) async {
        await pumpScreen(
          tester,
          child: EditorialHeroBackground(place: buildPlace()),
        );

        expect(find.byType(Icon), findsOneWidget);
      },
    );
  });
}
