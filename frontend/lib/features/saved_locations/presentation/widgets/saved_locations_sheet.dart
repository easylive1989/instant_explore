import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/presentation/extensions/place_category_extension.dart';
import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/journal/category_tag.dart';
import 'package:context_app/shared/widgets/journal/glyph_thumb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens the saved-locations list as a Field Journal bottom sheet.
Future<void> showSavedLocationsSheet(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final tokens = Theme.of(context).extension<LorescapeTokens>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens?.rXl ?? 22),
      ),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.of(sheetContext).size.height * 0.75;
      return SizedBox(height: height, child: const SavedLocationsSheet());
    },
  );
}

/// Content of the saved-locations bottom sheet: a header, then the saved
/// places (or an empty state).
class SavedLocationsSheet extends ConsumerWidget {
  const SavedLocationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLocations = ref.watch(savedLocationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetGrabHandle(),
            const SizedBox(height: 14),
            const _SheetHeader(),
            const SizedBox(height: 4),
            Expanded(
              child: savedLocations.when(
                data: (entries) => entries.isEmpty
                    ? const _EmptyState()
                    : _SavedLocationsList(entries: entries),
                loading: () => const Center(child: AdaptiveProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'common.error_prefix'.tr(),
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetGrabHandle extends StatelessWidget {
  const _SheetGrabHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.bookmark, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'saved_locations.title'.tr(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        AdaptiveIconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 56,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'saved_locations.empty'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'saved_locations.empty_hint'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedLocationsList extends StatelessWidget {
  final List<SavedLocationEntry> entries;

  const _SavedLocationsList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) => _SavedRow(entry: entries[index]),
    );
  }
}

class _SavedRow extends ConsumerWidget {
  final SavedLocationEntry entry;

  const _SavedRow({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final ink3 = tokens?.ink3 ?? colorScheme.onSurfaceVariant;
    final place = entry.toPlace();

    return Dismissible(
      key: ValueKey(entry.placeId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colorScheme.error,
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        ref.read(savedLocationsProvider.notifier).removePlace(entry.placeId);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: InkWell(
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.pushNamed('config', extra: place);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                _SavedThumb(place: place),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      CategoryTag(category: place.category.journalCategory),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showAdaptiveAlertDialog<bool>(
      context: context,
      title: 'saved_locations.delete_title'.tr(),
      content: 'saved_locations.delete_message'.tr(),
      actions: [
        AdaptiveDialogAction<bool>(
          label: 'saved_locations.cancel'.tr(),
          result: false,
        ),
        AdaptiveDialogAction<bool>(
          label: 'saved_locations.delete_confirm'.tr(),
          isDestructive: true,
          result: true,
        ),
      ],
    );
  }
}

/// 54×54 thumbnail for a saved place: photo when available, otherwise a
/// category glyph placeholder.
class _SavedThumb extends StatelessWidget {
  const _SavedThumb({required this.place});

  final Place place;

  static const _size = 54.0;
  static const _radius = 12.0;

  @override
  Widget build(BuildContext context) {
    final photoUrl = place.primaryPhoto?.url;
    if (photoUrl == null) return _glyph;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _glyph,
      ),
    );
  }

  Widget get _glyph => GlyphThumb(
    category: place.category.journalCategory,
    size: _size,
    borderRadius: _radius,
  );
}
