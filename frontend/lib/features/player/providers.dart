import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/player/models/narration_style.dart';

/// 導覽風格選擇 Provider
///
/// 管理用戶選擇的導覽風格
/// 預設為深度版（deepDive）
/// 使用 autoDispose 確保離開頁面時自動重置
final narrationStyleProvider = StateProvider.autoDispose<NarrationStyle>((ref) {
  return NarrationStyle.deepDive;
});
