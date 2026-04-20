import 'package:context_app/core/services/image_picker_service.dart';
import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';
import 'package:context_app/features/camera/presentation/screens/camera_screen.dart';
import 'package:context_app/features/camera/presentation/widgets/analysis_result_card.dart';
import 'package:context_app/features/camera/providers.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../fakes/fake_image_analysis_service.dart';
import '../../../../fakes/fake_image_picker_service.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('CameraScreen', () {
    testWidgets(
      'given no captured image, when the screen loads, '
      'then the initial layout and app bar are rendered correctly',
      (tester) async {
        await _givenCameraScreen(tester);

        _thenInstructionCopyIsVisible();
        _thenImageSourceButtonsAreVisible();
        _thenRetakeIconIsHidden();
        _thenBackNavigationIsAvailable();
      },
    );

    testWidgets(
      'given a stubbed picker, when the user taps take photo, '
      'then the picker is invoked with the camera source',
      (tester) async {
        final picker = FakeImagePickerService.withImage();

        await _givenCameraScreen(tester, picker: picker);
        await _whenUserTapsTakePhoto(tester);

        _thenPickerWasCalledWith(picker, ImageSource.camera);
      },
    );

    testWidgets(
      'given a stubbed picker, when the user taps gallery, '
      'then the picker is invoked with the gallery source',
      (tester) async {
        final picker = FakeImagePickerService.withImage();

        await _givenCameraScreen(tester, picker: picker);
        await _whenUserTapsFromGallery(tester);

        _thenPickerWasCalledWith(picker, ImageSource.gallery);
      },
    );

    testWidgets(
      'given the picker returns an image and analysis succeeds, '
      'when the user picks from gallery, then the analysis result card is shown',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final analyzer = FakeImageAnalysisService(
          result: const ImageAnalysisResult(
            name: 'Senso-ji Temple',
            description: 'A beloved Buddhist temple in Asakusa.',
            category: PlaceCategory.historicalCultural,
          ),
        );

        await _givenCameraScreen(tester, picker: picker, analyzer: analyzer);
        await _whenUserTapsFromGallery(tester);
        await _whenAnalysisCompletes(tester);

        _thenAnalysisResultIsShown();
      },
    );

    testWidgets(
      'given the user cancels the picker, when the picker returns null, '
      'then the source selector remains visible',
      (tester) async {
        final picker = FakeImagePickerService.cancelled();

        await _givenCameraScreen(tester, picker: picker);
        await _whenUserTapsTakePhoto(tester);

        _thenImageSourceButtonsAreVisible();
      },
    );

    testWidgets(
      'given analysis has succeeded, when the screen rebuilds, '
      'then the retake icon is exposed in the app bar',
      (tester) async {
        await _givenCameraScreen(tester);
        await _whenUserTapsFromGallery(tester);
        await _whenAnalysisCompletes(tester);

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets(
      'given analysis has succeeded, when the user taps retake, '
      'then the source selector is shown again and the result card is gone',
      (tester) async {
        await _givenCameraScreen(tester);
        await _whenUserTapsFromGallery(tester);
        await _whenAnalysisCompletes(tester);

        await _whenUserTapsRetake(tester);

        _thenImageSourceButtonsAreVisible();
        expect(find.byType(AnalysisResultCard), findsNothing);
        expect(find.byIcon(Icons.refresh), findsNothing);
      },
    );

    testWidgets(
      'given the analyzer throws, when the user picks from gallery, '
      'then the error icon, message and retry button are shown',
      (tester) async {
        final analyzer = FakeImageAnalysisService(
          error: Exception('network down'),
        );

        await _givenCameraScreen(tester, analyzer: analyzer);
        await _whenUserTapsFromGallery(tester);
        await _whenAnalysisCompletes(tester);

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('camera.analysis_error'), findsOneWidget);
        expect(find.text('camera.retry'), findsOneWidget);
      },
    );

    testWidgets(
      'given an analysis error is on screen, when the user taps retry, '
      'then the image source selector is restored',
      (tester) async {
        final analyzer = FakeImageAnalysisService(
          error: Exception('network down'),
        );

        await _givenCameraScreen(tester, analyzer: analyzer);
        await _whenUserTapsFromGallery(tester);
        await _whenAnalysisCompletes(tester);

        await tester.tap(find.text('camera.retry'));
        await tester.pumpAndSettle();

        _thenImageSourceButtonsAreVisible();
        expect(find.byIcon(Icons.error_outline), findsNothing);
      },
    );

    testWidgets(
      'given analysis has succeeded under a router, '
      'when the user taps start narration, '
      'then the config route is pushed with the place and image bytes',
      (tester) async {
        final navigatedExtras = <Object?>[];

        await _givenCameraScreenWithRouter(
          tester,
          onConfigPush: navigatedExtras.add,
        );
        await _whenUserTapsFromGallery(tester);
        await _whenAnalysisCompletes(tester);

        await tester.tap(find.text('camera.start_narration'));
        await tester.pumpAndSettle();

        expect(navigatedExtras, hasLength(1));
        final extra = navigatedExtras.single as Map<String, dynamic>;
        expect(extra['place'], isNotNull);
        expect(extra['capturedImageBytes'], isNotNull);
      },
    );
  });
}

Future<void> _givenCameraScreen(
  WidgetTester tester, {
  FakeImagePickerService? picker,
  FakeImageAnalysisService? analyzer,
}) async {
  await pumpScreen(
    tester,
    child: const CameraScreen(),
    overrides: [
      imageAnalysisServiceProvider.overrideWithValue(
        analyzer ?? FakeImageAnalysisService(),
      ),
      imagePickerServiceProvider.overrideWithValue(
        picker ?? FakeImagePickerService.withImage(),
      ),
    ],
  );
}

Future<void> _whenUserTapsTakePhoto(WidgetTester tester) async {
  await tester.tap(find.text('camera.take_photo'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _whenUserTapsFromGallery(WidgetTester tester) async {
  await tester.tap(find.text('camera.from_gallery'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _whenAnalysisCompletes(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _whenUserTapsRetake(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.refresh));
  await tester.pumpAndSettle();
}

Future<void> _givenCameraScreenWithRouter(
  WidgetTester tester, {
  required void Function(Object? extra) onConfigPush,
  FakeImagePickerService? picker,
  FakeImageAnalysisService? analyzer,
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
            key: Key('config-screen'),
            body: SizedBox.shrink(),
          );
        },
      ),
    ],
    overrides: [
      imageAnalysisServiceProvider.overrideWithValue(
        analyzer ?? FakeImageAnalysisService(),
      ),
      imagePickerServiceProvider.overrideWithValue(
        picker ?? FakeImagePickerService.withImage(),
      ),
    ],
  );
}

void _thenInstructionCopyIsVisible() {
  expect(find.text('camera.instruction'), findsOneWidget);
  expect(find.text('camera.instruction_subtitle'), findsOneWidget);
}

void _thenImageSourceButtonsAreVisible() {
  expect(find.text('camera.take_photo'), findsOneWidget);
  expect(find.text('camera.from_gallery'), findsOneWidget);
}

void _thenRetakeIconIsHidden() {
  expect(find.byIcon(Icons.refresh), findsNothing);
}

void _thenBackNavigationIsAvailable() {
  expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
}

void _thenPickerWasCalledWith(
  FakeImagePickerService picker,
  ImageSource source,
) {
  expect(picker.pickCount, equals(1));
  expect(picker.lastSource, equals(source));
}

void _thenAnalysisResultIsShown() {
  expect(find.byType(AnalysisResultCard), findsOneWidget);
  expect(find.text('camera.start_narration'), findsOneWidget);
}
