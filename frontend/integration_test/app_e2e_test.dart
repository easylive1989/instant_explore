import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:instant_explore/main.dart' as app;

void main() {
  patrolTest(
    '完整流程測試：登入 -> 隨機推薦 -> 驗證結果',
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
    ($) async {
      // 1. 啟動應用程式
      await $.pumpWidgetAndSettle(app.InstantExploreApp());

      // 等待應用程式完全載入
      await $.pump(const Duration(seconds: 2));

      // 2. 驗證登入畫面顯示
      expect($('Instant Explore'), findsOneWidget);
      expect($('隨性探點'), findsOneWidget);
      expect($('使用 Google 登入'), findsOneWidget);

      // 3. 點擊 Google 登入按鈕
      await $('使用 Google 登入').tap();

      // 等待登入處理完成
      await $.pumpAndSettle(timeout: const Duration(seconds: 8));

      // 4. 驗證成功進入首頁
      // 檢查是否顯示歡迎訊息或登入成功的 SnackBar
      // 等待可能的 SnackBar 消失
      await $.pump(const Duration(seconds: 3));

      // 驗證進入首頁 - 檢查隨機推薦按鈕
      expect(find.text('隨機推薦'), findsOneWidget);

      // 檢查是否有 E2E 測試模式指示器
      expect(find.text('E2E 測試模式'), findsOneWidget);

      // 5. 點擊隨機推薦按鈕
      await $(find.text('隨機推薦')).tap();

      // 等待推薦結果載入
      await $.pump(const Duration(seconds: 2));

      // 等待載入完成
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // 6. 驗證推薦結果顯示
      // 檢查是否顯示測試餐廳資料
      final testRestaurantNames = ['測試餐廳', 'E2E 咖啡廳', '模擬火鍋店'];

      bool foundTestRestaurant = false;
      for (final restaurantName in testRestaurantNames) {
        if (find.text(restaurantName).evaluate().isNotEmpty) {
          foundTestRestaurant = true;
          print('✅ 找到測試餐廳: $restaurantName');
          break;
        }
      }

      expect(
        foundTestRestaurant,
        isTrue,
        reason: '應該要找到至少一個測試餐廳: ${testRestaurantNames.join(", ")}',
      );

      // 7. 驗證地圖上顯示標記
      // 檢查是否有標記顯示（透過查看是否有位置圖標）
      expect(find.byIcon(Icons.location_on), findsAtLeastNWidgets(1));
    },
  );

  patrolTest('測試模式驗證', ($) async {
    // 啟動應用程式
    await $.pumpWidgetAndSettle(app.InstantExploreApp());

    // 登入
    await $('使用 Google 登入').tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    // 驗證 E2E 測試模式指示器存在
    expect(find.text('E2E 測試模式'), findsOneWidget);

    // 驗證測試模式圖標
    expect(find.byIcon(Icons.science), findsOneWidget);
  });
}
