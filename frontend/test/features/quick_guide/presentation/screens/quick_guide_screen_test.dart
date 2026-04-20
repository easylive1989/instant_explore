import 'package:context_app/features/ads/domain/services/rewarded_ad_service.dart';
import 'package:context_app/features/ads/providers.dart';
import 'package:context_app/features/quick_guide/presentation/screens/quick_guide_screen.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}

Future<void> _givenQuickGuideScreen(
  WidgetTester tester, {
  InMemoryUsageRepository? usage,
  RewardedAdService? rewardedAdService,
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
    ],
  );
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
