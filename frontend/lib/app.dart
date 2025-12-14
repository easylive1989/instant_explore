import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/core/config/theme_config.dart';
import 'package:context_app/core/config/router_config.dart';

/// Main application widget using go_router for navigation.
///
/// This widget sets up the app theme, routing, and global configuration.
class ContextureApp extends ConsumerWidget {
  const ContextureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => 'name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.dark, // Force dark mode to match design
      routerConfig: router,
    );
  }
}
