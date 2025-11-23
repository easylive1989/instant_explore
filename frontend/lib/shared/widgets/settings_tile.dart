import 'package:flutter/material.dart';

/// 設定項目元件
///
/// 提供統一的設定項目樣式，包含圖示、標題、副標題和尾部元件
class SettingsTile extends StatelessWidget {
  /// 前導圖示或元件
  final Widget? leading;

  /// 項目標題
  final String title;

  /// 項目副標題（選填）
  final String? subtitle;

  /// 尾部元件（選填）
  final Widget? trailing;

  /// 點擊回調（選填）
  final VoidCallback? onTap;

  /// 圖示顏色（選填）
  final Color? iconColor;

  /// 文字顏色（選填）
  final Color? textColor;

  const SettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? leadingWidget = leading;
    if (leading != null && leading is Icon && iconColor != null) {
      leadingWidget = IconTheme(
        data: IconThemeData(color: iconColor),
        child: leading!,
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leadingWidget,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
