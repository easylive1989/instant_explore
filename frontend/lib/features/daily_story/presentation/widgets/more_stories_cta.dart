import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "想知道更多嗎？ / 探索更多故事" call-to-action shown at the bottom of a
/// story reader, taking the user to the place-discovery flow to generate
/// more stories.
///
/// Colours are passed in so the CTA matches its host surface — the daily
/// story card body uses a fixed cream palette, while the legacy layout
/// follows the active theme.
class MoreStoriesCta extends StatelessWidget {
  const MoreStoriesCta({
    super.key,
    required this.onTap,
    required this.accentColor,
    required this.onAccentColor,
    this.eyebrowColor,
  });

  /// Invoked when the button is tapped.
  final VoidCallback onTap;

  /// Button fill colour.
  final Color accentColor;

  /// Button label/icon colour.
  final Color onAccentColor;

  /// Eyebrow colour; defaults to [accentColor].
  final Color? eyebrowColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'daily_story.more_eyebrow'.tr(),
          style: TextStyle(
            color: eyebrowColor ?? accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: onAccentColor,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.auto_awesome, size: 20),
            label: Text('daily_story.explore_more'.tr()),
          ),
        ),
      ],
    );
  }
}
