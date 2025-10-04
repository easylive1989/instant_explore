import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patrol/patrol.dart';
import 'package:instant_explore/main.dart' as app;
import 'package:instant_explore/providers/service_providers.dart';
import 'package:instant_explore/providers/map_provider.dart';
import '../test/fakes/fake_auth_service.dart';
import '../test/fakes/fake_location_service.dart';
import '../test/fakes/fake_places_service.dart';
import '../test/helpers/mock_map_factory.dart';

void main() {
  patrolTest(
    '完整流程測試：隨機推薦 -> 驗證結果',
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
    ($) async {
      // 準備 fake services
      final fakeAuth = FakeAuthService();
      final fakeLocation = FakeLocationService();
      final fakePlaces = FakePlacesService();

      // 1. 啟動應用程式並注入 fake services
      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(fakeAuth),
            locationServiceProvider.overrideWithValue(fakeLocation),
            placesServiceProvider.overrideWithValue(fakePlaces),
            mapWidgetProvider.overrideWithValue(createMockMapFactory()),
          ],
          child: const app.InstantExploreApp(),
        ),
      );

      // 等待應用程式完全載入
      await $.pump(const Duration(seconds: 2));

      // 2. 驗證直接進入首頁
      expect(find.text('隨機推薦'), findsOneWidget);

      // 檢查是否有 E2E 測試模式指示器
      expect(find.text('E2E 測試模式'), findsOneWidget);

      // 3. 點擊隨機推薦按鈕
      await $(find.text('隨機推薦')).tap();

      // 等待推薦結果載入
      await $.pump(const Duration(seconds: 2));

      // 等待載入完成
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // 4. 驗證推薦結果顯示
      // 檢查是否顯示測試餐廳資料
      final testRestaurantNames = ['測試餐廳', 'E2E 咖啡廳', '模擬火鍋店'];

      bool foundTestRestaurant = false;
      for (final restaurantName in testRestaurantNames) {
        if (find.text(restaurantName).evaluate().isNotEmpty) {
          foundTestRestaurant = true;
          break;
        }
      }

      expect(
        foundTestRestaurant,
        isTrue,
        reason: '應該要找到至少一個測試餐廳: ${testRestaurantNames.join(", ")}',
      );

      // 5. 驗證地圖上顯示標記
      // 檢查是否有標記顯示（透過查看是否有位置圖標）
      expect(find.byIcon(Icons.location_on), findsAtLeastNWidgets(1));
    },
  );
}
