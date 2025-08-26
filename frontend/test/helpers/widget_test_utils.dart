import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_explore/providers/service_providers.dart';
import 'package:instant_explore/providers/map_provider.dart';
import 'package:instant_explore/services/interfaces/auth_service_interface.dart';
import 'package:instant_explore/services/interfaces/location_service_interface.dart';
import 'package:instant_explore/services/interfaces/places_service_interface.dart';
import '../fakes/fake_auth_service.dart';
import '../fakes/fake_location_service.dart';
import '../fakes/fake_places_service.dart';
import 'mock_map_factory.dart';

/// Widget 測試輔助工具
///
/// 提供便捷的方法來建立帶有測試服務的 Widget

/// 建立測試用 Widget
///
/// 自動包裝 MaterialApp 和 ProviderScope，並注入指定的服務
Widget createTestWidget(
  Widget widget, {
  IAuthService? authService,
  ILocationService? locationService,
  IPlacesService? placesService,
  List<Override>? additionalOverrides,
  ThemeData? theme,
}) {
  final overrides = <Override>[
    authServiceProvider.overrideWithValue(
      authService ?? FakeAuthService(),
    ),
    locationServiceProvider.overrideWithValue(
      locationService ?? FakeLocationService(),
    ),
    placesServiceProvider.overrideWithValue(
      placesService ?? FakePlacesService(),
    ),
    // 預設使用 Mock Map Widget
    mapWidgetProvider.overrideWithValue(createMockMapFactory()),
    ...?additionalOverrides,
  ];

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: widget,
    ),
  );
}

/// 建立只有 ProviderScope 的 Widget（不包含 MaterialApp）
///
/// 用於測試不需要完整 Material 架構的 Widget
Widget createTestProviderWidget(
  Widget widget, {
  IAuthService? authService,
  ILocationService? locationService,
  IPlacesService? placesService,
  List<Override>? additionalOverrides,
}) {
  final overrides = <Override>[
    authServiceProvider.overrideWithValue(
      authService ?? FakeAuthService(),
    ),
    locationServiceProvider.overrideWithValue(
      locationService ?? FakeLocationService(),
    ),
    placesServiceProvider.overrideWithValue(
      placesService ?? FakePlacesService(),
    ),
    // 預設使用 Mock Map Widget
    mapWidgetProvider.overrideWithValue(createMockMapFactory()),
    ...?additionalOverrides,
  ];

  return ProviderScope(
    overrides: overrides,
    child: widget,
  );
}

/// 建立已登入狀態的測試 Widget
Widget createAuthenticatedTestWidget(
  Widget widget, {
  ILocationService? locationService,
  IPlacesService? placesService,
  List<Override>? additionalOverrides,
}) {
  // 建立已登入的 fake auth service
  final authenticatedAuthService = FakeAuthService();
  
  return createTestWidget(
    widget,
    authService: authenticatedAuthService,
    locationService: locationService,
    placesService: placesService,
    additionalOverrides: additionalOverrides,
  );
}

/// 建立未登入狀態的測試 Widget
Widget createUnauthenticatedTestWidget(
  Widget widget, {
  ILocationService? locationService,
  IPlacesService? placesService,
  List<Override>? additionalOverrides,
}) {
  // 建立未登入的 fake auth service（預設就是未登入）
  final unauthenticatedAuthService = FakeAuthService();
  
  return createTestWidget(
    widget,
    authService: unauthenticatedAuthService,
    locationService: locationService,
    placesService: placesService,
    additionalOverrides: additionalOverrides,
  );
}