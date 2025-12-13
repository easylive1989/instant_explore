import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/settings/application/delete_account_use_case.dart';
import 'package:context_app/features/settings/application/logout_use_case.dart';

class SettingsController extends StateNotifier<AsyncValue<void>> {
  final LogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;

  SettingsController(this._logoutUseCase, this._deleteAccountUseCase)
    : super(const AsyncValue.data(null));

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _logoutUseCase.execute());
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _deleteAccountUseCase.execute());
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

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) {
      final logoutUseCase = ref.watch(logoutUseCaseProvider);
      final deleteAccountUseCase = ref.watch(deleteAccountUseCaseProvider);
      return SettingsController(logoutUseCase, deleteAccountUseCase);
    });
