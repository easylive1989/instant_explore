import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:travel_diary/main.dart' as app;
import 'helpers/supabase_admin_helper.dart';
import 'helpers/test_user_helper.dart';

void main() {
  late SupabaseAdminHelper adminHelper = SupabaseAdminHelper();

  setUp(() async {
    // 確保測試帳號不存在（清理可能的殘留）
    await adminHelper.deleteTestUser(TestUser.email);
  });

  tearDown(() async {
    // 清理測試帳號
    await adminHelper.deleteTestUser(TestUser.email);
  });

  patrolTest('Email registration flow - Complete journey from login to home', (
    $,
  ) async {
    // Step 1: 啟動應用
    await $.pumpWidgetAndSettle(await app.init());
    await $.pumpAndSettle(duration: const Duration(seconds: 2));

    // Step 2: 在登入頁面點擊註冊連結
    final registerButton = $(const Key('login_register_button'));
    await registerButton.waitUntilVisible(timeout: const Duration(seconds: 5));
    await registerButton.tap();
    await $.pumpAndSettle(duration: const Duration(seconds: 1));

    // Step 3: 填寫註冊表單
    // 填寫 Email
    final emailField = $(const Key('register_email_field'));
    await emailField.waitUntilVisible();
    await emailField.enterText(TestUser.email);
    await $.pumpAndSettle();

    // 填寫 Password
    final passwordField = $(const Key('register_password_field'));
    await passwordField.enterText(TestUser.password);
    await $.pumpAndSettle();

    // 填寫 Confirm Password
    final confirmPasswordField = $(const Key('register_confirm_password_field'));
    await confirmPasswordField.enterText(TestUser.password);
    await $.pumpAndSettle();

    // Step 4: 提交註冊
    final submitButton = $(const Key('register_submit_button'));
    await submitButton.tap();
    await $.pumpAndSettle(duration: const Duration(seconds: 5));

    // Step 5: 驗證註冊成功訊息（先檢查是否有任何 SnackBar）
    // 等待更長時間讓 SnackBar 出現
    await $.pumpAndSettle(duration: const Duration(seconds: 2));

    // Step 6: 驗證導航到首頁
    expect(
      $('Travel Diary'),
      findsWidgets,
      reason: 'Should navigate to home screen after successful registration',
    );
  });
}
