import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-aware icon-only button.
///
/// On iOS/macOS renders a `CupertinoButton` without a background; on other
/// platforms renders a Material `IconButton`. Use this for navigation or
/// toolbar-style icon actions; for primary chips keep using a styled button.
class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
    this.padding,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  bool _isCupertino(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS ||
        platform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCupertino(context)) {
      return CupertinoButton(
        onPressed: onPressed,
        padding: padding ?? const EdgeInsets.all(8),
        minimumSize: Size.zero,
        child: IconTheme.merge(
          data: IconThemeData(color: color),
          child: icon,
        ),
      );
    }
    return IconButton(
      onPressed: onPressed,
      icon: icon,
      color: color,
      tooltip: tooltip,
      padding: padding ?? const EdgeInsets.all(8),
    );
  }
}
