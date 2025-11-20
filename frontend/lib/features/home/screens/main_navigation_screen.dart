import 'package:flutter/material.dart';
import '../../diary/screens/diary_list_screen.dart';

/// 主導航畫面
///
/// 直接顯示日記列表頁面
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiaryListScreen();
  }
}
