import 'package:context_app/features/narration/domain/models/grounding_info.dart';
import 'package:context_app/features/narration/presentation/widgets/grounding_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroundingInfoSheet', () {
    testWidgets('lists every source with title and uri', (tester) async {
      final grounding = GroundingInfo.fromRaw(
        sources: const [
          GroundingSource(uri: 'https://a.example.com', title: 'A'),
          GroundingSource(uri: 'https://b.example.com', title: 'B'),
        ],
      )!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GroundingInfoSheet(grounding: grounding)),
        ),
      );

      expect(find.text('來源'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('https://a.example.com'), findsOneWidget);
      expect(find.text('https://b.example.com'), findsOneWidget);
    });

    testWidgets('hides 來源 section when no sources present', (tester) async {
      final grounding = GroundingInfo.fromRaw(
        webSearchQueries: const ['taipei 101'],
      )!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GroundingInfoSheet(grounding: grounding)),
        ),
      );

      expect(find.text('來源'), findsNothing);
    });
  });
}
