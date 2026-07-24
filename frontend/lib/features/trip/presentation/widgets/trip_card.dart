import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 顯示單一 Trip 的卡片（Field Journal clay 磚）。
class TripCard extends StatelessWidget {
  final Trip trip;
  final int itemCount;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TripCard({
    super.key,
    required this.trip,
    required this.itemCount,
    required this.onTap,
    this.isCurrent = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final clay = tokens?.clay ?? colorScheme.primary;
    final clayDeep = context.tokens.clayDeep;
    const onClay = Color(0xFFFBEFE7);
    final radius = context.tokens.rXl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [clay, clayDeep],
            ),
            border: isCurrent
                ? Border.all(color: onClay.withValues(alpha: 0.7), width: 2)
                : null,
            boxShadow: context.tokens.e2,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      color: onClay.withValues(alpha: 0.85),
                      size: 26,
                    ),
                    const Spacer(),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: onClay.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'trip.current_badge'.tr(),
                          style: const TextStyle(
                            color: onClay,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: GoogleFonts.notoSerifTc(
                        color: onClay,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (trip.startDate != null || trip.endDate != null)
                      Text(
                        _formatDateRange(trip.startDate, trip.endDate),
                        style: TextStyle(
                          color: onClay.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'trip.item_count'.tr(args: ['$itemCount']),
                      style: TextStyle(
                        color: onClay.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    final fmt = DateFormat.yMd();
    if (start != null && end != null) {
      return '${fmt.format(start)} – ${fmt.format(end)}';
    }
    return fmt.format(start ?? end!);
  }
}

/// 代表「未分類」群組的卡片（tripId = null 的條目集合）— 紙感磚。
class UncategorizedTripCard extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;

  const UncategorizedTripCard({
    super.key,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = context.tokens.rXl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: context.tokens.e1,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 26,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'trip.uncategorized'.tr(),
                      style: GoogleFonts.notoSerifTc(
                        color: colorScheme.onSurface,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'trip.item_count'.tr(args: ['$itemCount']),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
