import 'package:flutter/material.dart';

/// Horizontal divider with centered text
///
/// Creates a divider line with text in the center, commonly used
/// to separate different sign-in options (e.g., "or" between social
/// login and email/password login).
class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
