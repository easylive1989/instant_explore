import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_explore/providers/service_providers.dart';
import 'package:instant_explore/services/interfaces/auth_service_interface.dart';
import 'package:instant_explore/services/interfaces/location_service_interface.dart';
import 'package:instant_explore/services/interfaces/places_service_interface.dart';
import '../fakes/fake_auth_service.dart';
import '../fakes/fake_location_service.dart';
import '../fakes/fake_places_service.dart';

/// 測試用 App Wrapper
///
/// 提供 Riverpod overrides 機制來注入測試服務
class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final List<Override>? overrides;
  
  const TestAppWrapper({
    super.key,
    required this.child,
    this.overrides,
  });
  
  @override
  Widget build(BuildContext context) {
    // 預設的測試 overrides
    final defaultOverrides = [
      authServiceProvider.overrideWithValue(FakeAuthService()),
      locationServiceProvider.overrideWithValue(FakeLocationService()),
      placesServiceProvider.overrideWithValue(FakePlacesService()),
    ];
    
    return ProviderScope(
      overrides: overrides ?? defaultOverrides,
      child: MaterialApp(
        title: 'Instant Explore (Test)',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: child,
      ),
    );
  }
}

/// 建立測試用的 ProviderScope 
///
/// 提供自定義的 fake services
ProviderScope createTestProviderScope({
  required Widget child,
  IAuthService? authService,
  ILocationService? locationService,  
  IPlacesService? placesService,
  List<Override>? additionalOverrides,
}) {
  final overrides = <Override>[
    if (authService != null)
      authServiceProvider.overrideWithValue(authService),
    if (locationService != null)
      locationServiceProvider.overrideWithValue(locationService),
    if (placesService != null)
      placesServiceProvider.overrideWithValue(placesService),
    ...?additionalOverrides,
  ];
  
  // 如果沒有提供任何服務，使用預設的 fake services
  if (overrides.isEmpty) {
    overrides.addAll([
      authServiceProvider.overrideWithValue(FakeAuthService()),
      locationServiceProvider.overrideWithValue(FakeLocationService()),
      placesServiceProvider.overrideWithValue(FakePlacesService()),
    ]);
  }
  
  return ProviderScope(
    overrides: overrides,
    child: child,
  );
}