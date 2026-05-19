// Camera feature had no screen tests before this file — the camera flow
// is the second AI-driven entry point alongside Quick Guide, but only
// the latter had behavioural coverage. These tests exercise the happy
// path (pick → analyze → start narration), the retry-after-error path,
// and the empty path so a regression that breaks one of these states
// is caught early.

import 'package:context_app/core/services/image_picker_service.dart';
import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';
import 'package:context_app/features/camera/presentation/screens/camera_screen.dart';
import 'package:context_app/features/camera/providers.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_image_analysis_service.dart';
import '../../../../fakes/fake_image_picker_service.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('CameraScreen', () {
    testWidgets(
      'given the screen has just opened, when no image is picked yet, '
      'then the camera and gallery source buttons are visible',
      (tester) async {
        await _pumpCamera(tester);

        expect(find.text('camera.take_photo'), findsOneWidget);
        expect(find.text('camera.from_gallery'), findsOneWidget);
        expect(find.text('camera.instruction'), findsOneWidget);
      },
    );

    testWidgets(
      'given the user picks an image and analysis succeeds, '
      'when analysis returns, then the result card and start-narration '
      'button are shown',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final analysis = FakeImageAnalysisService(
          result: const ImageAnalysisResult(
            name: 'Kiyomizu-dera',
            description: 'A 13th-century Buddhist temple in eastern Kyoto.',
            category: PlaceCategory.historicalCultural,
          ),
        );

        await _pumpCamera(tester, picker: picker, analysis: analysis);
        await _tapGallery(tester);
        await tester.pumpAndSettle();

        expect(find.text('Kiyomizu-dera'), findsOneWidget);
        expect(find.text('camera.start_narration'), findsOneWidget);
      },
    );

    testWidgets(
      'given the user cancels the image picker, '
      'when no image is returned, then the source selector remains visible',
      (tester) async {
        final picker = FakeImagePickerService.cancelled();

        await _pumpCamera(tester, picker: picker);
        await _tapGallery(tester);
        await tester.pumpAndSettle();

        expect(find.text('camera.from_gallery'), findsOneWidget);
        expect(find.text('camera.start_narration'), findsNothing);
      },
    );

    testWidgets(
      'given the AI analysis throws, when the user picks an image, '
      'then the error UI with the retry button is shown',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final analysis = FakeImageAnalysisService(error: Exception('boom'));

        await _pumpCamera(tester, picker: picker, analysis: analysis);
        await _tapGallery(tester);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('camera.retry'), findsOneWidget);
      },
    );

    testWidgets(
      'given the error UI is shown, when the user taps retry, '
      'then the source selector is restored for another attempt',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final analysis = FakeImageAnalysisService(error: Exception('boom'));

        await _pumpCamera(tester, picker: picker, analysis: analysis);
        await _tapGallery(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('camera.retry'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(find.text('camera.from_gallery'), findsOneWidget);
      },
    );

    testWidgets(
      'given analysis succeeded under a router, when the user taps start '
      'narration, then the config route receives the analysed place and '
      'captured image bytes as extras',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final analysis = FakeImageAnalysisService(
          result: const ImageAnalysisResult(
            name: 'Fushimi Inari',
            description: 'Famous shrine with thousands of vermilion torii.',
            category: PlaceCategory.historicalCultural,
          ),
        );
        final extras = <Object?>[];

        await _pumpCameraWithRouter(
          tester,
          picker: picker,
          analysis: analysis,
          onConfigPush: extras.add,
        );
        await _tapGallery(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('camera.start_narration'));
        await tester.pumpAndSettle();

        expect(extras, hasLength(1));
        final extra = extras.single as Map<String, dynamic>;
        expect(extra['place'], isA<Place>());
        expect((extra['place'] as Place).name, 'Fushimi Inari');
        expect(extra['capturedImageBytes'], isNotNull);
      },
    );
  });
}

Future<void> _pumpCamera(
  WidgetTester tester, {
  FakeImagePickerService? picker,
  FakeImageAnalysisService? analysis,
}) async {
  await pumpScreen(
    tester,
    child: const CameraScreen(),
    overrides: _overrides(picker: picker, analysis: analysis),
  );
}

Future<void> _pumpCameraWithRouter(
  WidgetTester tester, {
  required FakeImagePickerService picker,
  required FakeImageAnalysisService analysis,
  required void Function(Object? extra) onConfigPush,
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const CameraScreen()),
      GoRoute(
        name: 'config',
        path: '/config',
        builder: (_, state) {
          onConfigPush(state.extra);
          return const Scaffold(
            key: Key('config-stub'),
            body: SizedBox.shrink(),
          );
        },
      ),
    ],
    overrides: _overrides(picker: picker, analysis: analysis),
  );
}

List<Override> _overrides({
  FakeImagePickerService? picker,
  FakeImageAnalysisService? analysis,
}) {
  return [
    imagePickerServiceProvider.overrideWithValue(
      picker ?? FakeImagePickerService.withImage(),
    ),
    imageAnalysisServiceProvider.overrideWithValue(
      analysis ?? FakeImageAnalysisService(),
    ),
  ];
}

Future<void> _tapGallery(WidgetTester tester) async {
  await tester.tap(find.text('camera.from_gallery'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
