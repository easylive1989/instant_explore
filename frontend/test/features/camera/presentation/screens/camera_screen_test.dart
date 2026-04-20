import 'package:context_app/features/camera/presentation/screens/camera_screen.dart';
import 'package:context_app/features/camera/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_image_analysis_service.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('CameraScreen', () {
    testWidgets(
      'given no captured image, when the screen loads, '
      'then the instruction text and source buttons are rendered',
      (tester) async {
        await _givenCameraScreen(tester);

        _thenInstructionCopyIsVisible();
        _thenImageSourceButtonsAreVisible();
      },
    );

    testWidgets(
      'given no captured image, when the screen loads, '
      'then the retake icon is hidden from the app bar',
      (tester) async {
        await _givenCameraScreen(tester);

        _thenRetakeIconIsHidden();
      },
    );

    testWidgets(
      'given no captured image, when the screen loads, '
      'then the app bar back button is visible',
      (tester) async {
        await _givenCameraScreen(tester);

        _thenBackNavigationIsAvailable();
      },
    );
  });
}

Future<void> _givenCameraScreen(WidgetTester tester) async {
  await pumpScreen(
    tester,
    child: const CameraScreen(),
    overrides: [
      imageAnalysisServiceProvider.overrideWithValue(FakeImageAnalysisService()),
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
