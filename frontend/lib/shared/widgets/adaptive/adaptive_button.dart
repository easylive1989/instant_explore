import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Visual prominence of an [AdaptiveButton].
enum AdaptiveButtonStyle {
  /// Primary call-to-action. Material: `ElevatedButton`/`FilledButton`.
  /// Cupertino: filled `CupertinoButton`.
  filled,

  /// Low-emphasis action with a border. Material: `OutlinedButton`.
  /// Cupertino: bordered `CupertinoButton` (tinted outline).
  outlined,

  /// Minimal emphasis, text only. Material: `TextButton`.
  /// Cupertino: plain `CupertinoButton`.
  text,
}

/// Platform-aware button that switches between Material and Cupertino
/// appearance. Keeps the API small and covers the use cases present in the
/// app (label + optional leading icon).
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = AdaptiveButtonStyle.filled,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.padding,
    this.minSize,
    this.expanded = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final AdaptiveButtonStyle style;
  final Widget? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final Size? minSize;

  /// When true the button stretches to fill the horizontal space.
  final bool expanded;

  bool _isCupertino(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final button = _isCupertino(context)
        ? _buildCupertino(context)
        : _buildMaterial(context);
    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _wrapChild() {
    if (icon == null) return child;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon!,
        const SizedBox(width: 8),
        Flexible(child: child),
      ],
    );
  }

  Widget _buildMaterial(BuildContext context) {
    final materialChild = _wrapChild();
    switch (style) {
      case AdaptiveButtonStyle.filled:
        final filledStyle = ElevatedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          padding: padding,
        );
        return ElevatedButton(
          onPressed: onPressed,
          style: filledStyle,
          child: materialChild,
        );
      case AdaptiveButtonStyle.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            padding: padding,
          ),
          child: materialChild,
        );
      case AdaptiveButtonStyle.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            padding: padding,
          ),
          child: materialChild,
        );
    }
  }

  Widget _buildCupertino(BuildContext context) {
    final cupertinoChild = _wrapChild();
    final primary = CupertinoTheme.of(context).primaryColor;
    switch (style) {
      case AdaptiveButtonStyle.filled:
        return CupertinoButton.filled(
          onPressed: onPressed,
          padding: padding,
          minimumSize: minSize,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foregroundColor ?? CupertinoColors.white),
            child: IconTheme.merge(
              data: IconThemeData(
                color: foregroundColor ?? CupertinoColors.white,
              ),
              child: cupertinoChild,
            ),
          ),
        );
      case AdaptiveButtonStyle.outlined:
        final outlineColor = foregroundColor ?? primary;
        Widget borderBox = DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: outlineColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: cupertinoChild,
          ),
        );
        if (expanded) {
          borderBox = SizedBox(width: double.infinity, child: borderBox);
        }
        return CupertinoButton(
          onPressed: onPressed,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: minSize,
          color: backgroundColor,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: outlineColor),
            child: IconTheme.merge(
              data: IconThemeData(color: outlineColor),
              child: borderBox,
            ),
          ),
        );
      case AdaptiveButtonStyle.text:
        return CupertinoButton(
          onPressed: onPressed,
          padding: padding,
          minimumSize: minSize,
          color: backgroundColor,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foregroundColor ?? primary),
            child: IconTheme.merge(
              data: IconThemeData(color: foregroundColor ?? primary),
              child: cupertinoChild,
            ),
          ),
        );
    }
  }
}
