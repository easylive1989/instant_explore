import 'package:context_app/core/services/image_picker_service.dart';
import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';
import 'package:context_app/features/camera/presentation/screens/camera_screen.dart';
import 'package:context_app/features/camera/presentation/widgets/analysis_result_card.dart';
import 'package:context_app/features/camera/providers.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
