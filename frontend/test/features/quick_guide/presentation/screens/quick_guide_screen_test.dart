import 'package:context_app/core/services/image_picker_service.dart';
import 'package:context_app/features/ads/domain/services/rewarded_ad_service.dart';
import 'package:context_app/features/ads/providers.dart';
import 'package:context_app/features/quick_guide/presentation/screens/quick_guide_screen.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:context_app/features/trip/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
      'then the title, instructions, and source buttons are visible',
      (tester) async {
        await _givenQuickGuideScreen(tester);

        _thenTitleAndInstructionsAreVisible();
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

    testWidgets(
      'given the daily quota is exhausted, when the user taps take photo, '
      'then the watch-ad dialog is shown',
      (tester) async {
        await _givenQuickGuideScreen(
          tester,
          usage: InMemoryUsageRepository(usedToday: 1, dailyFreeLimit: 1),
        );

        await _whenUserTapsTakePhoto(tester);
        await tester.pumpAndSettle();

        expect(find.text('ads.quota_exceeded_title'), findsOneWidget);
        expect(find.text('ads.watch_video'), findsOneWidget);
      },
    );

    testWidgets(
      'given the AI service throws, when the user picks a gallery image, '
      'then the error state replaces the selector',
      (tester) async {
        await _givenQuickGuideScreen(
          tester,
          ai: FakeQuickGuideAiService(error: Exception('boom')),
        );

        await _whenUserTapsFromGallery(tester);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('quick_guide.analysis_error'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets(
      'given an error state is shown, when the controller resets, '
      'then the source selector is restored',
      (tester) async {
        await _givenQuickGuideScreen(
          tester,
          ai: FakeQuickGuideAiService(error: Exception('boom')),
        );

        await _whenUserTapsFromGallery(tester);
        await tester.pumpAndSettle();

        // Invoke the retake callback through the provider notifier: the
        // refresh GestureDetector is stacked over the image preview and
        // can't be tapped reliably via the test surface's hit-testing.
        final element = tester.element(find.byType(QuickGuideScreen));
        final scope = ProviderScope.containerOf(element, listen: false);
        scope.read(quickGuideControllerProvider.notifier).reset();
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(find.text('quick_guide.instruction'), findsOneWidget);
      },
    );

    testWidgets(
      'given AI succeeds under a router, when the user picks a gallery image, '
      'then the player route is pushed with narration content',
      (tester) async {
        final extras = <Object?>[];

        await _givenQuickGuideScreenWithRouter(
          tester,
          ai: FakeQuickGuideAiService(response: 'This is a friendly place.'),
          onPlayerPush: extras.add,
        );

        await _whenUserTapsFromGallery(tester);
        await tester.pumpAndSettle();

        expect(extras, hasLength(1));
        final extra = extras.single as Map<String, dynamic>;
        expect(extra['narrationContent'], isNotNull);
        expect(extra['autoPlay'], isTrue);
      },
    );
  });
}

Future<void> _givenQuickGuideScreen(
  WidgetTester tester, {
  InMemoryUsageRepository? usage,
  RewardedAdService? rewardedAdService,
  FakeImagePickerService? picker,
  FakeQuickGuideAiService? ai,
}) async {
  // The screen pushes `/player` on successful analysis, so a fake AI service
  // that throws keeps the test focused on the picker interaction without
  // requiring a full router scaffold.
  await pumpScreen(
    tester,
    child: const QuickGuideScreen(),
    overrides: _buildOverrides(
      usage: usage,
      rewardedAdService: rewardedAdService,
      picker: picker,
      ai: ai,
    ),
  );
}

Future<void> _givenQuickGuideScreenWithRouter(
  WidgetTester tester, {
  InMemoryUsageRepository? usage,
  RewardedAdService? rewardedAdService,
  FakeImagePickerService? picker,
  FakeQuickGuideAiService? ai,
  required void Function(Object? extra) onPlayerPush,
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const QuickGuideScreen()),
      GoRoute(
        path: '/player',
        builder: (_, state) {
          onPlayerPush(state.extra);
          return const Scaffold(
            key: Key('player-screen'),
            body: SizedBox.shrink(),
          );
        },
      ),
    ],
    overrides: _buildOverrides(
      usage: usage,
      rewardedAdService: rewardedAdService,
      picker: picker,
      ai: ai,
    ),
  );
}

List<Override> _buildOverrides({
  InMemoryUsageRepository? usage,
  RewardedAdService? rewardedAdService,
  FakeImagePickerService? picker,
  FakeQuickGuideAiService? ai,
}) {
  return [
    quickGuideRepositoryProvider.overrideWithValue(
      InMemoryQuickGuideRepository(),
    ),
    quickGuideAiServiceProvider.overrideWithValue(
      ai ?? FakeQuickGuideAiService(error: Exception('stubbed ai failure')),
    ),
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
  ];
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
