import 'package:context_app/features/export/presentation/widgets/pdf_cover_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders trip name, date range and entry count', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1131));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap(
        PdfCoverWidget(
          tripName: 'Kyoto Getaway',
          startDate: DateTime(2026, 4, 10),
          endDate: DateTime(2026, 4, 14),
          entryCount: 7,
          appName: 'Context',
          tagline: 'Explore instantly',
          stampLabel: 'VISITED',
          entryCountLabel: '{count} places',
        ),
      ),
    );

    expect(find.text('Kyoto Getaway'), findsOneWidget);
    expect(find.text('2026.04.10 – 2026.04.14'), findsOneWidget);
    expect(find.text('7 places'), findsOneWidget);
    expect(find.text('Context'), findsOneWidget);
    expect(find.text('VISITED'), findsOneWidget);
  });

  testWidgets('collapses single-day date range', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1131));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap(
        PdfCoverWidget(
          tripName: 'Day trip',
          startDate: DateTime(2026, 4, 10),
          endDate: DateTime(2026, 4, 10),
          entryCount: 1,
          appName: 'Context',
          tagline: 'tagline',
          stampLabel: 'stamp',
          entryCountLabel: '{count} place',
        ),
      ),
    );

    expect(find.text('2026.04.10'), findsOneWidget);
    expect(find.textContaining('–'), findsNothing);
  });
}
