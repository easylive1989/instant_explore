import 'package:flutter/material.dart';

/// 評分選擇器 (1-5 星)
class RatingPicker extends StatelessWidget {
  final int? rating;
  final ValueChanged<int?> onRatingChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingPicker({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 32.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultActiveColor = activeColor ?? theme.colorScheme.primary;
    final defaultInactiveColor =
        inactiveColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () {
              // 如果點擊已選擇的星星,則取消評分
              if (rating == i) {
                onRatingChanged(null);
              } else {
                onRatingChanged(i);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                rating != null && i <= rating! ? Icons.star : Icons.star_border,
                size: size,
                color: rating != null && i <= rating!
                    ? defaultActiveColor
                    : defaultInactiveColor,
              ),
            ),
          ),
      ],
    );
  }
}
