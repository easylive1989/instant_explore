import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/core/config/app_config.dart';
import 'package:travel_diary/core/config/router_config.dart';

/// Main application widget using go_router for navigation.
///
/// This widget sets up the app theme, routing, and global configuration.
class TravelDiaryApp extends ConsumerWidget {
  const TravelDiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      localizationsDelegates: const [FlutterQuillLocalizations.delegate],
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
