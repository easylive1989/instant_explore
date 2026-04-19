import 'package:flutter/material.dart';

/// Platform-aware circular progress indicator.
///
/// On iOS/macOS shows `CupertinoActivityIndicator`, on other platforms shows
/// a Material `CircularProgressIndicator`. Thin wrapper around
/// `CircularProgressIndicator.adaptive` that exposes the same handful of
/// options used throughout the app.
class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({
    super.key,
    this.strokeWidth = 4.0,
    this.color,
    this.value,
  });

  final double strokeWidth;
  final Color? color;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator.adaptive(
      strokeWidth: strokeWidth,
      value: value,
      valueColor: color == null ? null : AlwaysStoppedAnimation<Color>(color!),
    );
  }
}
