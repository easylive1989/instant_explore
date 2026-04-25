import 'dart:ui';

import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';

/// A single item in [MidnightBottomNav].
class MidnightBottomNavItem {
  const MidnightBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;
  final String label;

  /// Icon displayed when the item is active; falls back to [icon].
  final IconData? activeIcon;
}

/// A frosted-glass bottom navigation bar for the Midnight Kyoto theme.
class MidnightBottomNav extends StatelessWidget {
  const MidnightBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.blurSigma = 16,
  });

  final List<MidnightBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Blur strength applied to the backdrop filter.
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xCC0B1117),
            border: Border(top: BorderSide(color: AppColors.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavItem(
                      item: items[i],
                      active: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final MidnightBottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : AppColors.onSurfaceVariant.withValues(alpha: 0.7);

    return PressScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? (item.activeIcon ?? item.icon) : item.icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                item.label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
