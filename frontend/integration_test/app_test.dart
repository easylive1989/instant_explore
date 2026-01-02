import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/firebase_options.dart';

import 'test_app.dart';
import 'helpers/helpers.dart';

/// 初始化測試環境
///
/// 此函數應在測試開始前呼叫一次
Future<void> initializeTestEnvironment() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load API configuration
  final apiConfig = ApiConfig.fromEnvironment();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: apiConfig.supabaseUrl,
    anonKey: apiConfig.supabaseAnonKey,
  );
}

void main() {
  setUpAll(() async {
    await initializeTestEnvironment();
  });

  setUp(() async {
    await SupabaseTestHelper.signInTestUser();
  });

  tearDown(() async {
    await SupabaseTestHelper.cleanupAllTables();
  });

  patrolTest('generate narration success', ($) async {
    // Arrange
    await $.pumpWidgetAndSettle(createTestApp());

    // Act: 導航到播放器頁面
    await $.tap(find.text('台北 101'));
    await $.waitUntilVisible(find.textContaining('Select Narration Aspect'));

    // 選擇一個導覽面向並開始播放
    await $.tap(find.textContaining('Impressive Facts'));

    await $.tap(find.textContaining('Start Guide'));

    // Assert: 等待導覽內容生成並顯示
    await $.waitUntilVisible(find.textContaining('歡迎來到'));
  });

  patrolTest('saved generate narration success', ($) async {
    // Arrange
    await $.pumpWidgetAndSettle(createTestApp());

    // Step 1: 從首頁選擇地點
    await $.tap(find.text('台北 101'));

    // Step 2: 選擇導覽面向
    await $.waitUntilVisible(find.textContaining('Select Narration Aspect'));
    // Wait for options before tapping
    await $.waitUntilVisible(find.textContaining('Impressive Facts'));
    await $.tap(find.textContaining('Impressive Facts').first);

    await $.tap(find.textContaining('Start Guide'));

    // Step 3: 等待導覽生成
    await $.waitUntilVisible(find.textContaining('歡迎來到'));

    // Step 4: 儲存到旅行記錄
    await $.tap(find.byIcon(Icons.bookmark_add));
    await $.waitUntilVisible(find.textContaining('Item Saved!'));

    // Step 5: 導航到旅行記錄頁面確認
    await $.tap(find.textContaining('View Journey of Exploration'));

    // Assert: 確認新增的記錄顯示
    await $.waitUntilVisible(find.text('台北 101'));
  });
}
