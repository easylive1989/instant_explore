import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// 圖片亮度分析工具
class ImageBrightnessHelper {
  /// 分析圖片亮度並返回適合的前景色（黑色或白色）
  ///
  /// [imageProvider] 要分析的圖片提供者
  /// [defaultColor] 當分析失敗時使用的預設顏色
  ///
  /// 返回 Colors.white 或 Colors.black
  static Future<Color> getForegroundColor(
    ImageProvider imageProvider, {
    Color defaultColor = Colors.white,
  }) async {
    try {
      // 生成調色盤
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 10,
      );

      // 取得主色調
      final dominantColor = paletteGenerator.dominantColor?.color;

      if (dominantColor == null) {
        return defaultColor;
      }

      // 計算相對亮度
      final luminance = dominantColor.computeLuminance();

      // 亮度 > 0.5 使用黑色，否則使用白色
      return luminance > 0.5 ? Colors.black : Colors.white;
    } catch (e) {
      debugPrint('分析圖片亮度失敗: $e');
      return defaultColor;
    }
  }

  /// 判斷顏色是否為深色
  ///
  /// [color] 要判斷的顏色
  ///
  /// 返回 true 表示深色，false 表示淺色
  static bool isDark(Color color) {
    return color.computeLuminance() < 0.5;
  }

  /// 取得對比色（黑色或白色）
  ///
  /// [color] 背景顏色
  ///
  /// 返回 Colors.white（深色背景）或 Colors.black（淺色背景）
  static Color getContrastColor(Color color) {
    return isDark(color) ? Colors.white : Colors.black;
  }
}
