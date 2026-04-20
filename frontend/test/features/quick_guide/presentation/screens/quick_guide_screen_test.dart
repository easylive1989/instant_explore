import 'package:context_app/core/services/image_picker_service.dart';
import 'package:context_app/features/ads/domain/services/rewarded_ad_service.dart';
import 'package:context_app/features/ads/providers.dart';
import 'package:context_app/features/quick_guide/presentation/screens/quick_guide_screen.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../fakes/fake_image_picker_service.dart';
import '../../../../fakes/fake_quick_guide_ai_service.dart';
import '../../../../fakes/fake_rewarded_ad_service.dart';
import '../../../../fakes/in_memory_quick_guide_repository.dart';
import '../../../../fakes/in_memory_trip_repository.dart';
import '../../../../fakes/in_memory_usage_repository.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('QuickGuideScreen', () {
    testWidgets(
      'given no picked image, when the screen loads, '
      'then the large title and instruction copy are visible',
      (tester) async {
        await _givenQuickGuideScreen(tester);

        _thenTitleAndInstructionsAreVisible();
      },
    );

    testWidgets(
      'given no picked image, when the screen loads, '
      'then the take-photo and gallery buttons are visible',
      (tester) async {
        await _givenQuickGuideScreen(tester);

        _thenImageSourceButtonsAreVisible();
      },
    );

    testWidgets(
      'given remaining quota, when the user taps take photo, '
      'then the image picker is invoked with the camera source',
      (tester) async {
        final picker = FakeImagePickerService.withImage();

        await _givenQuickGuideScreen(tester, picker: picker);
        await _whenUserTapsTakePhoto(tester);

        _thenPickerWasCalledWith(picker, ImageSource.camera);
      },
    );

    testWidgets(
      'given remaining quota, when the user taps gallery, '
      'then the image picker is invoked with the gallery source',
      (tester) async {
        final picker = FakeImagePickerService.withImage();

        await _givenQuickGuideScreen(tester, picker: picker);
        await _whenUserTapsFromGallery(tester);

        _thenPickerWasCalledWith(picker, ImageSource.gallery);
      },
    );

    testWidgets(
      'given the user cancels the picker, when no image is returned, '
      'then the source selector remains visible',
      (tester) async {
        final picker = FakeImagePickerService.cancelled();

        await _givenQuickGuideScreen(tester, picker: picker);
        await _whenUserTapsTakePhoto(tester);

        _thenImageSourceButtonsAreVisible();
      },
    );

    testWidgets(
      'given the daily quota is exhausted, when the user taps take photo, '
      'then the image picker is not invoked',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final exhaustedUsage = InMemoryUsageRepository(
          usedToday: 1,
          dailyFreeLimit: 1,
        );

        await _givenQuickGuideScreen(
          tester,
          picker: picker,
          usage: exhaustedUsage,
        );
        await _whenUserTapsTakePhoto(tester);

        _thenPickerWasNotCalled(picker);
      },
    );
  });
}

Future<void> _givenQuickGuideScreen(
  WidgetTester tester, {
  InMemoryUsageRepository? usage,
  RewardedAdService? rewardedAdService,
  FakeImagePickerService? picker,
}) async {
  await pumpScreen(
    tester,
    child: const QuickGuideScreen(),
    overrides: [
      quickGuideRepositoryProvider.overrideWithValue(
        InMemoryQuickGuideRepository(),
      ),
      quickGuideAiServiceProvider.overrideWithValue(FakeQuickGuideAiService()),
      tripRepositoryProvider.overrideWithValue(InMemoryTripRepository()),
      usageRepositoryProvider.overrideWithValue(
        usage ?? InMemoryUsageRepository(),
      ),
      rewardedAdServiceProvider.overrideWithValue(
        rewardedAdService ?? FakeRewardedAdService(),
      ),
      imagePickerServiceProvider.overrideWithValue(
        picker ?? FakeImagePickerService.withImage(),
      ),
    ],
  );
}

Future<void> _whenUserTapsTakePhoto(WidgetTester tester) async {
  await tester.tap(find.text('quick_guide.take_photo'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _whenUserTapsFromGallery(WidgetTester tester) async {
  await tester.tap(find.text('quick_guide.from_gallery'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void _thenTitleAndInstructionsAreVisible() {
  expect(find.text('quick_guide.title'), findsOneWidget);
  expect(find.text('quick_guide.instruction'), findsOneWidget);
  expect(find.text('quick_guide.instruction_subtitle'), findsOneWidget);
}

void _thenImageSourceButtonsAreVisible() {
  expect(find.text('quick_guide.take_photo'), findsOneWidget);
  expect(find.text('quick_guide.from_gallery'), findsOneWidget);
}

void _thenPickerWasCalledWith(
  FakeImagePickerService picker,
  ImageSource source,
) {
  expect(picker.pickCount, equals(1));
  expect(picker.lastSource, equals(source));
}

void _thenPickerWasNotCalled(FakeImagePickerService picker) {
  expect(picker.pickCount, equals(0));
}
