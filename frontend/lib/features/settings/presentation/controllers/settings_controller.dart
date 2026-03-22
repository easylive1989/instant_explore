import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';
import 'package:context_app/features/settings/domain/use_cases/logout_use_case.dart';

class SettingsController extends StateNotifier<AsyncValue<void>> {
  final LogoutUseCase _logoutUseCase;
  final AuthService _authService;
  final SubscriptionService _subscriptionService;

  SettingsController(
    this._logoutUseCase,
    this._authService,
    this._subscriptionService,
  ) : super(const AsyncValue.data(null));

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _logoutUseCase.execute());
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _subscriptionService.logOut();
      await _authService.deleteAccount();
    });
  }

  void changeLanguage(BuildContext context) {
    final currentLocale = context.locale;
    if (currentLocale.languageCode == 'en') {
      context.setLocale(const Locale('zh', 'TW'));
    } else {
      context.setLocale(const Locale('en'));
    }
  }
}
