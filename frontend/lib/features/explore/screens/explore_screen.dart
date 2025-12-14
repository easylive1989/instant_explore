import 'package:context_app/core/config/api_config.dart';
import 'package:context_app/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/explore/models/place.dart';
import 'package:context_app/features/explore/providers.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesState = ref.watch(placesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.backgroundDark,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xE6101922),
                            Color(0x33101922),
                            Color(0xE6101922),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
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
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              final languageCode =
                                  EasyLocalization.of(
                                    context,
                                  )?.locale.toLanguageTag() ??
                                  'zh-TW';
                              ref
                                  .read(placesControllerProvider.notifier)
                                  .refresh(languageCode: languageCode);
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search for places...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    final languageCode =
                                        EasyLocalization.of(
                                          context,
                                        )?.locale.toLanguageTag() ??
                                        'zh-TW';
                                    ref
                                        .read(placesControllerProvider.notifier)
                                        .search('', languageCode: languageCode);
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (value) {
                          final languageCode =
                              EasyLocalization.of(
                                context,
                              )?.locale.toLanguageTag() ??
                              'zh-TW';
                          ref
                              .read(placesControllerProvider.notifier)
                              .search(value, languageCode: languageCode);
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
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: places.length,
                            itemBuilder: (context, index) {
                              final place = places[index];
                              return PlaceCard(place: place);
                            },
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text(
                        '${'common.error_prefix'.tr()}: $error',
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
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

class PlaceCard extends ConsumerWidget {
  final Place place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiConfig = ref.watch(apiConfigProvider);

    final photoUrl = place.primaryPhoto?.getPhotoUrl(
      maxWidth: 400,
      apiKey: apiConfig.googleMapsApiKey,
    );

    return Card(
      color: Colors.white.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          context.pushNamed('config', extra: place);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 96,
                        height: 96,
                        color: Colors.grey[800],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              color: AppColors.textPrimaryDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.types.isNotEmpty
                          ? place.types.first.replaceAll('_', ' ').toUpperCase()
                          : 'common.place_label'.tr(),
                      style: TextStyle(
                        color: AppColors.textPrimaryDark.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.formattedAddress,
                      style: TextStyle(
                        color: AppColors.textPrimaryDark.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
