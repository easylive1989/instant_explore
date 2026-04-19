import 'package:flutter/material.dart';

/// Platform-aware slider.
///
/// Uses `Slider.adaptive` which renders a `CupertinoSlider` on iOS/macOS and
/// a Material `Slider` elsewhere.
class AdaptiveSlider extends StatelessWidget {
  const AdaptiveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Slider.adaptive(
      value: value,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      min: min,
      max: max,
      divisions: divisions,
    );
  }
}
