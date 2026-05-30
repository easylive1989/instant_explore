import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings appearance section: switch brand accent, reading surface and
/// headline font. The section header is rendered by the call site using
/// the shared `_SectionHeader` widget so it stays visually consistent
/// with sibling groups.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appearanceNotifierProvider);
    final notifier = ref.read(appearanceNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SegmentedRow<BrandAccent>(
          label: 'settings.appearance_accent'.tr(),
          value: state.accent,
          options: {
            BrandAccent.terracotta: 'settings.accent_terracotta'.tr(),
            BrandAccent.amber: 'settings.accent_amber'.tr(),
            BrandAccent.sage: 'settings.accent_sage'.tr(),
          },
          onChanged: notifier.setAccent,
        ),
        _SegmentedRow<ReadingSurface>(
          label: 'settings.appearance_reading'.tr(),
          value: state.reading,
          options: {
            ReadingSurface.paper: 'settings.reading_paper'.tr(),
            ReadingSurface.sepia: 'settings.reading_sepia'.tr(),
            ReadingSurface.night: 'settings.reading_night'.tr(),
          },
          onChanged: notifier.setReadingSurface,
        ),
        _SegmentedRow<HeadlineFont>(
          label: 'settings.appearance_headline'.tr(),
          value: state.headlineFont,
          options: {
            HeadlineFont.serif: 'settings.font_serif'.tr(),
            HeadlineFont.sans: 'settings.font_sans'.tr(),
          },
          onChanged: notifier.setHeadlineFont,
        ),
      ],
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                for (final entry in options.entries)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: entry.key == value,
                      label: entry.value,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(entry.key),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: entry.key == value
                                ? scheme.surfaceContainerLow
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: entry.key == value
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
