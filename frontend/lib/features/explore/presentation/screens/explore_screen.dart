import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/shared/extensions/place_category_extension.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_fab.dart';

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _FilterPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placesState = ref.watch(filteredPlacesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final minReviewCount = ref.watch(minReviewCountProvider);
    final isFilterActive = minReviewCount != 100;

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
                      Text(
                        'explore.title'.tr(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          _FilterButton(
                            isActive: isFilterActive,
                            onPressed: _showFilterPanel,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(placesControllerProvider.notifier)
                                  .refresh();
                            },
                            icon: const Icon(Icons.refresh),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for places...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(placesControllerProvider.notifier)
                                    .search('');
                              },
                            )
                          : null,
                    ),
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
                loading: () => const Center(child: CircularProgressIndicator()),
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
    return IconButton(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: isActive,
        smallSize: 8,
        child: const Icon(Icons.tune),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isActive ? AppColors.amber : AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  /// 滑桿的刻度值：0, 10, 50, 100, 200, 500, 1000
  static const List<int> _steps = [0, 10, 50, 100, 200, 500, 1000];

  @override
  void initState() {
    super.initState();
    final current = ref.read(minReviewCountProvider);
    _sliderValue = _valueToSlider(current);
  }

  /// 將評論數對應到滑桿位置（0.0 ~ 1.0）
  double _valueToSlider(int value) {
    for (int i = 0; i < _steps.length; i++) {
      if (value <= _steps[i]) {
        if (i == 0) return 0.0;
        final prev = _steps[i - 1];
        final curr = _steps[i];
        final fraction = (value - prev) / (curr - prev);
        return (i - 1 + fraction) / (_steps.length - 1);
      }
    }
    return 1.0;
  }

  /// 將滑桿位置轉換為評論數
  int _sliderToValue(double slider) {
    final pos = slider * (_steps.length - 1);
    final lower = pos.floor().clamp(0, _steps.length - 2);
    final fraction = pos - lower;
    final value =
        _steps[lower] + ((_steps[lower + 1] - _steps[lower]) * fraction);
    return value.round();
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'explore.filter.min_reviews'.tr(),
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _sliderValue,
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    ref.read(minReviewCountProvider.notifier).state =
                        _sliderToValue(value);
                  },
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '$currentValue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                Text(
                  '0',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '1000',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'explore.filter.description'.tr(),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(minReviewCountProvider.notifier).state = 100;
                setState(() {
                  _sliderValue = _valueToSlider(100);
                });
              },
              child: Text('explore.filter.reset'.tr()),
            ),
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => context.pushNamed('config', extra: place),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  place.category.imageAssetPath,
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
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: place.category.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: place.category.color.withValues(
                                alpha: 0.5,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                place.category.icon,
                                size: 14,
                                color: place.category.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place.category.translationKey.tr(),
                                style: TextStyle(
                                  color: place.category.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.formattedAddress,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          key: ValueKey(isSaved),
          color: isSaved
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
