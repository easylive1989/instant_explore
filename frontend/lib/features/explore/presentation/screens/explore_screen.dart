import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_fab.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/journal/category_tag.dart';
import 'package:context_app/shared/widgets/journal/glyph_thumb.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Fallback warm card shadow (design token `e1`) for contexts where the
/// [LorescapeTokens] theme extension is not installed (e.g. widget tests).
const List<BoxShadow> _kCardShadow = [
  BoxShadow(color: Color(0x0F281E12), offset: Offset(0, 1), blurRadius: 2),
];

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 同步 EasyLocalization 的語言到 languageProvider
    // 使用 addPostFrameCallback 延遲更新，避免在 widget build 期間修改 provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLanguage();
    });
  }

  /// 同步 EasyLocalization 語言到 Provider
  void _syncLanguage() {
    if (!mounted) return;
    final localeTag =
        EasyLocalization.of(context)?.locale.toLanguageTag() ?? 'zh-TW';
    ref.read(currentLanguageProvider.notifier).updateLanguage(localeTag);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterPanel() {
    showAdaptiveModalBottomSheet(
      context: context,
      builder: (context) => const _FilterPanel(),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(placesControllerProvider.notifier).search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final placesState = ref.watch(filteredPlacesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final maxDistance = ref.watch(maxDistanceProvider);
    final isFilterActive = maxDistance != kDefaultMaxDistanceMeters;

    return Scaffold(
      floatingActionButton: const SavedLocationsFab(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'explore.title'.tr(),
                          style: Theme.of(context).textTheme.displayLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          _FilterButton(
                            isActive: isFilterActive,
                            onPressed: _showFilterPanel,
                          ),
                          const SizedBox(width: 8),
                          _RefreshButton(
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(placesControllerProvider.notifier)
                                  .refresh();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                      ref.read(placesControllerProvider.notifier).search(value);
                    },
                    onClear: _searchController.text.isNotEmpty
                        ? _clearSearch
                        : null,
                  ),
                ],
              ),
            ),
            Expanded(
              child: placesState.when(
                loading: () => const Center(child: AdaptiveProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('${'common.error_prefix'.tr()}: $error'),
                ),
                data: (places) {
                  if (places.isEmpty) {
                    return Center(
                      child: Text(
                        'explore.empty'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
                    itemCount: places.length,
                    itemBuilder: (context, index) =>
                        PlaceCard(place: places[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular 40×40 icon button on a sunken-paper surface, matching the
/// design's `.iconbtn` on `--paper-sunk`.
class _FilterButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _FilterButton({required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _CircleButton(
          icon: Icons.tune,
          iconColor: colorScheme.onSurface,
          background: colorScheme.surfaceContainerHighest,
          iconSize: 22,
          onPressed: onPressed,
        ),
        if (isActive) const Positioned(top: 2, right: 2, child: _ActiveDot()),
      ],
    );
  }
}

/// Circular 40×40 clay action button, matching the design's clay `.iconbtn`.
class _RefreshButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RefreshButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _CircleButton(
      icon: Icons.refresh,
      iconColor: colorScheme.onPrimary,
      background: colorScheme.primary,
      iconSize: 20,
      onPressed: onPressed,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.iconSize,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onPressed,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Pill-shaped search field on a sunken-paper surface, matching `.search`.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final hintColor = tokens?.ink3 ?? colorScheme.onSurfaceVariant;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: hintColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyLarge,
              cursorColor: colorScheme.primary,
              // The field carries its own pill container, so it must fully
              // opt out of the global outlined+filled inputDecorationTheme —
              // `collapsed` still inherits enabledBorder/focusedBorder/fill.
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'explore.search_hint'.tr(),
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: hintColor),
              ),
            ),
          ),
          if (onClear != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.clear, size: 20, color: hintColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPanel extends ConsumerStatefulWidget {
  const _FilterPanel();

  @override
  ConsumerState<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<_FilterPanel> {
  late double _sliderValue;

  /// 滑桿的刻度值（公尺）：500, 1000, 2000, 5000, 10000, 20000, 30000
  static const List<double> _steps = [
    500,
    1000,
    2000,
    5000,
    10000,
    20000,
    30000,
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(maxDistanceProvider);
    _sliderValue = _valueToSlider(current);
  }

  /// 將距離值對應到滑桿位置（0.0 ~ 1.0）
  double _valueToSlider(double value) {
    for (int i = 0; i < _steps.length; i++) {
      if (value <= _steps[i]) return i / (_steps.length - 1);
    }
    return 1.0;
  }

  /// 將滑桿位置轉換為距離值
  double _sliderToValue(double slider) {
    final index = (slider * (_steps.length - 1)).round().clamp(
      0,
      _steps.length - 1,
    );
    return _steps[index];
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return km == km.roundToDouble() ? '${km.toInt()} km' : '$km km';
    }
    return '${meters.toInt()} m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValue = _sliderToValue(_sliderValue);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.outline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'explore.filter.title'.tr(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'explore.filter.max_distance'.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AdaptiveSlider(
                  value: _sliderValue,
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    final newDistance = _sliderToValue(value);
                    ref.read(maxDistanceProvider.notifier).state = newDistance;
                    if (ref.read(searchQueryProvider).isEmpty) {
                      ref
                          .read(placesControllerProvider.notifier)
                          .refresh(radius: newDistance);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  _formatDistance(currentValue),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('500 m', style: Theme.of(context).textTheme.bodySmall),
                Text('30 km', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'explore.filter.description'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(maxDistanceProvider.notifier).state =
                    kDefaultMaxDistanceMeters;
                setState(() {
                  _sliderValue = _valueToSlider(kDefaultMaxDistanceMeters);
                });
                if (ref.read(searchQueryProvider).isEmpty) {
                  ref
                      .read(placesControllerProvider.notifier)
                      .refresh(radius: kDefaultMaxDistanceMeters);
                }
              },
              child: Text('explore.filter.reset'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

/// A place row card in the Field Journal style: raised paper surface with a
/// thumbnail, name and category tag.
class PlaceCard extends ConsumerWidget {
  final Place place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final radius = tokens?.rLg ?? 16;
    final savedLocations = ref.watch(savedLocationsProvider);
    final isSaved =
        savedLocations.valueOrNull?.any((e) => e.placeId == place.id) ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(radius),
          border: Border.fromBorderSide(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          boxShadow: tokens?.e1 ?? _kCardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: () => context.pushNamed('config', extra: place),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _PlaceThumb(place: place),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                                height: 1.15,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        CategoryTag(category: place.category.journalCategory),
                      ],
                    ),
                  ),
                  _BookmarkButton(
                    isSaved: isSaved,
                    onTap: () {
                      ref
                          .read(savedLocationsProvider.notifier)
                          .togglePlace(place);
                    },
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

/// 64×64 thumbnail: the place photo when available, otherwise a category
/// glyph placeholder.
class _PlaceThumb extends StatelessWidget {
  const _PlaceThumb({required this.place});

  final Place place;

  static const _size = 64.0;
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

class _BookmarkButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;

  const _BookmarkButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final restColor = tokens?.ink3 ?? colorScheme.onSurfaceVariant;

    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            key: ValueKey(isSaved),
            color: isSaved ? colorScheme.primary : restColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
