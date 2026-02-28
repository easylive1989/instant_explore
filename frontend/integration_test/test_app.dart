import 'package:context_app/features/narration/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/app.dart';
import 'package:context_app/features/explore/providers.dart';

import 'fakes/fake_places_repository.dart';
import 'fakes/fake_narration_service.dart';
import 'fakes/fake_location_service.dart';

/// 建立用於 E2E 測試的 App Widget
///
/// 注入 fake 依賴來隔離外部 API，但使用真實的 local Supabase
Widget createTestApp({
  FakePlacesRepository? placesRepository,
  FakeNarrationService? narrationService,
  FakeLocationService? locationService,
  List<Override>? additionalOverrides,
}) {
  final overrides = <Override>[
    // 覆蓋 PlacesRepository
    placesRepositoryProvider.overrideWithValue(
      placesRepository ?? FakePlacesRepository(),
    ),
    // 覆蓋 NarrationService
    narrationServiceProvider.overrideWithValue(
      narrationService ?? FakeNarrationService(),
    ),
    // 覆蓋 LocationService
    locationServiceProvider.overrideWithValue(
      locationService ?? FakeLocationService(),
    ),
    // 加入額外的 overrides
    ...?additionalOverrides,
  ];

  return EasyLocalization(
    supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('zh', 'TW'),
    startLocale: const Locale('en'), // Force English for testing
    saveLocale: false, // 測試時不儲存語言設定
    child: ProviderScope(overrides: overrides, child: const ContextureApp()),
  );
}
