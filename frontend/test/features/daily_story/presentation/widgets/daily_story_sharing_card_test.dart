import 'dart:typed_data';

import 'package:context_app/features/daily_story/presentation/widgets/daily_story_sharing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyStorySharingCard', () {
    testWidgets(
      'given a story with no image, when rendered, then title, hook, '
      'place-era caption and the LORESCAPE wordmark are visible',
      (tester) async {
        await _pumpCard(
          tester,
          title: 'A century of ruin and rebirth',
          hook: 'Pope Julius II tore down a thousand-year-old basilica.',
          placeName: "St. Peter's Basilica",
          placeLocation: 'Vatican',
          era: '1506-1626',
        );

        expect(find.text('A century of ruin and rebirth'), findsOneWidget);
        expect(
          find.text('Pope Julius II tore down a thousand-year-old basilica.'),
          findsOneWidget,
        );
        expect(find.textContaining("St. Peter's Basilica"), findsOneWidget);
        expect(find.text('LORESCAPE'), findsOneWidget);
      },
    );

    testWidgets(
      'given a long hook, when rendered, then the hook is capped at '
      'three lines with ellipsis',
      (tester) async {
        final longHook = List.filled(30, 'lorem ipsum').join(' ');
        await _pumpCard(
          tester,
          title: 'Long hook',
          hook: longHook,
          placeName: 'Anywhere',
          placeLocation: 'Nowhere',
          era: '2026',
        );

        final hook = tester.widget<Text>(find.text(longHook));
        expect(hook.maxLines, 3);
        expect(hook.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets(
      'given imageBytes, when rendered, then an Image.memory header '
      'replaces the placeholder',
      (tester) async {
        await _pumpCard(
          tester,
          title: 'With photo',
          hook: 'hook',
          placeName: 'Place',
          placeLocation: 'Loc',
          era: '2026',
          imageBytes: _transparentPngBytes(),
        );

        final memoryImages = find.byWidgetPredicate(
          (w) => w is Image && w.image is MemoryImage,
        );
        expect(memoryImages, findsOneWidget);
      },
    );
  });
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required String title,
  required String hook,
  required String placeName,
  required String placeLocation,
  required String era,
  Uint8List? imageBytes,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Material(
          color: Colors.transparent,
          child: Center(
            child: DailyStorySharingCard(
              title: title,
              hook: hook,
              placeName: placeName,
              placeLocation: placeLocation,
              era: era,
              imageBytes: imageBytes,
            ),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 3; i += 1) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Uint8List _transparentPngBytes() {
  return Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
}
