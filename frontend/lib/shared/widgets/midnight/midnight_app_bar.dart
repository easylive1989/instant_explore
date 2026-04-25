import 'dart:ui';

import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

/// A blur-backed app bar with uppercase title and ghost-border bottom divider.
///
/// Wraps Flutter's [AppBar] inside a [BackdropFilter] for the frosted-glass
/// look used throughout the Midnight Kyoto theme.
class MidnightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MidnightAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.uppercaseTitle = true,
    this.blurSigma = 12,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;

  /// When `true` (default), transforms the title text to uppercase.
  final bool uppercaseTitle;

  /// Blur strength for the backdrop filter.
  final double blurSigma;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = _resolveTitle();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xCC0B1117),
            border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
          ),
          child: AppBar(
            title: resolvedTitle,
            leading: leading,
            actions: actions,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
          ),
        ),
      ),
    );
  }

  Widget? _resolveTitle() {
    if (!uppercaseTitle || title is! Text) return title;

    final t = title! as Text;
    return Text(
      (t.data ?? '').toUpperCase(),
      style:
          t.style ??
          const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.onSurface,
          ),
    );
  }
}
