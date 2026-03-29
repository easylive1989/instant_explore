import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsController extends StateNotifier<AsyncValue<void>> {
  SettingsController() : super(const AsyncValue.data(null));

  void changeLanguage(BuildContext context) {
    final currentLocale = context.locale;
    if (currentLocale.languageCode == 'en') {
      context.setLocale(const Locale('zh', 'TW'));
    } else {
      context.setLocale(const Locale('en'));
    }
  }
}
