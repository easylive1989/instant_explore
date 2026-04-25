import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_fab.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/shared/extensions/place_category_extension.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final placesState = ref.watch(filteredPlacesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final maxDistance = ref.watch(maxDistanceProvider);
    final isFilterActive = maxDistance < 30000.0;

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
                          PillIconButton(
                            icon: Icons.refresh,
                            size: 40,
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
                  AdaptiveTextField(
                    controller: _searchController,
                    hintText: 'Search for places...',
                    prefixIcon: const Icon(Icons.search),
                    suffix: _searchController.text.isNotEmpty
                        ? AdaptiveIconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(placesControllerProvider.notifier)
                                  .search('');
                            },
                          )
                        : null,
                    onSubmitted: (value) {
                      ref.read(placesControllerProvider.notifier).search(value);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: placesState.when(
                data: (places) => places.isEmpty
                    ? Center(
                        child: Text(
                          'No places found',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          return PlaceCard(place: places[index]);
                        },
                      ),
                loading: () => const Center(child: AdaptiveProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('${'common.error_prefix'.tr()}: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _FilterButton({required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PillIconButton(
          icon: Icons.tune,
          size: 40,
          variant: isActive
              ? PillIconButtonVariant.filled
              : PillIconButtonVariant.ghost,
          onPressed: onPressed,
        ),
        if (isActive) const Positioned(top: 2, right: 2, child: _ActiveDot()),
      ],
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
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
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
                    ref.read(maxDistanceProvider.notifier).state =
                        _sliderToValue(value);
                  },
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  _formatDistance(currentValue),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: colorScheme.primary),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('500 m', style: Theme.of(context).textTheme.labelSmall),
                Text('30 km', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'explore.filter.description'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          PillButton(
            label: 'explore.filter.reset'.tr(),
            variant: PillButtonVariant.ghost,
            fullWidth: true,
            onPressed: () {
              ref.read(maxDistanceProvider.notifier).state = 30000.0;
              setState(() {
                _sliderValue = _valueToSlider(30000.0);
              });
            },
          ),
        ],
      ),
    );
  }
}

class PlaceCard extends ConsumerWidget {
  final Place place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final savedLocations = ref.watch(savedLocationsProvider);
    final isSaved =
        savedLocations.valueOrNull?.any((e) => e.placeId == place.id) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassCard(
        onTap: () => context.pushNamed('config', extra: place),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                place.category.getImageAssetPath(context),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _CategoryChip(category: place.category),
                  const SizedBox(height: 8),
                  Text(
                    place.formattedAddress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _BookmarkButton(
              isSaved: isSaved,
              onTap: () {
                ref.read(savedLocationsProvider.notifier).togglePlace(place);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final PlaceCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              category.translationKey.tr().toUpperCase(),
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
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;

  const _BookmarkButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          key: ValueKey(isSaved),
          color: isSaved ? AppColors.primary : colorScheme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
