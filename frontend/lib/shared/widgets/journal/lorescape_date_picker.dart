import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows the Field Journal date picker as a bottom sheet and resolves with the
/// chosen date (or null if cancelled). Matches the design `.cal` sheet.
Future<DateTime?> showLorescapeDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final tokens = Theme.of(context).extension<LorescapeTokens>();
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens?.rXl ?? 22),
      ),
    ),
    builder: (_) => _CalendarSheet(
      initialDate: _clamp(initialDate, firstDate, lastDate),
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

DateTime _clamp(DateTime d, DateTime min, DateTime max) {
  if (d.isBefore(min)) return min;
  if (d.isAfter(max)) return max;
  return d;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime _selected = _dateOnly(widget.initialDate);
  late DateTime _month = DateTime(_selected.year, _selected.month);

  String get _locale => context.locale.toLanguageTag();

  bool get _canGoPrev =>
      _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  bool get _canGoNext =>
      _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  bool _isEnabled(DateTime day) =>
      !day.isBefore(_dateOnly(widget.firstDate)) &&
      !day.isAfter(_dateOnly(widget.lastDate));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final ink3 = tokens?.ink3 ?? cs.onSurfaceVariant;
    final lineStrong = tokens?.lineStrong ?? cs.outline;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: lineStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'date_picker.title'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ink3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMMEEEEd(_locale).format(_selected),
              style: GoogleFonts.notoSerifTc(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMM(_locale).format(_month),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Row(
                  children: [
                    _NavButton(
                      icon: Icons.chevron_left,
                      color: cs.onSurfaceVariant,
                      onTap: _canGoPrev ? () => _shiftMonth(-1) : null,
                    ),
                    const SizedBox(width: 8),
                    _NavButton(
                      icon: Icons.chevron_right,
                      color: cs.onSurfaceVariant,
                      onTap: _canGoNext ? () => _shiftMonth(1) : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _WeekdayHeader(locale: _locale, color: ink3),
            const SizedBox(height: 4),
            _DayGrid(
              month: _month,
              selected: _selected,
              isEnabled: _isEnabled,
              onPick: (day) => setState(() => _selected = day),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('date_picker.cancel'.tr()),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text('date_picker.confirm'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Icon(
        icon,
        size: 24,
        color: onTap == null ? color.withValues(alpha: 0.3) : color,
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.locale, required this.color});

  final String locale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Build Sunday-first narrow weekday labels from a known week.
    final narrow = DateFormat('EEEEE', locale);
    // 2024-01-07 is a Sunday.
    final labels = List.generate(
      7,
      (i) => narrow.format(DateTime(2024, 1, 7 + i)),
    );
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.selected,
    required this.isEnabled,
    required this.onPick,
  });

  final DateTime month;
  final DateTime selected;
  final bool Function(DateTime) isEnabled;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Sunday-first leading blanks: Dart weekday Sun=7 → 0 blanks.
    final leading = DateTime(month.year, month.month).weekday % 7;
    final rows = ((leading + daysInMonth) / 7).ceil();

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
          day: DateTime(month.year, month.month, d),
          selected: selected,
          isEnabled: isEnabled,
          onPick: onPick,
        ),
      for (var i = leading + daysInMonth; i < rows * 7; i++)
        const SizedBox.shrink(),
    ];

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: 46,
            child: Row(
              children: [
                for (var c = 0; c < 7; c++) Expanded(child: cells[r * 7 + c]),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isEnabled,
    required this.onPick,
  });

  final DateTime day;
  final DateTime selected;
  final bool Function(DateTime) isEnabled;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final isSel = day == _dateOnly(selected);
    final enabled = isEnabled(day);
    final Color textColor;
    if (isSel) {
      textColor = const Color(0xFFFBF1E9);
    } else if (!enabled) {
      textColor = tokens?.lineStrong ?? cs.outline;
    } else {
      textColor = cs.onSurface;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onPick(day) : null,
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isSel ? cs.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
