import 'package:flutter/material.dart';

/// Platform-aware toggle switch.
///
/// Uses `Switch.adaptive` which renders a `CupertinoSwitch` on iOS/macOS and
/// a Material `Switch` elsewhere.
class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
    );
  }
}
