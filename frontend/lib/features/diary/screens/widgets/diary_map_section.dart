import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';

class DiaryMapSection extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryMapSection({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    // 如果沒有地點資訊，不顯示整個區塊
    if (entry.placeName == null &&
        (entry.latitude == null || entry.longitude == null)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 地點資訊
        if (entry.placeName != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: ThemeConfig.accentColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.placeName!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ThemeConfig.neutralText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.placeAddress != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.placeAddress!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.neutralText.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 地圖
        if (entry.latitude != null && entry.longitude != null) ...[
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ThemeConfig.neutralBorder, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(entry.latitude!, entry.longitude!),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId(entry.id),
                    position: LatLng(entry.latitude!, entry.longitude!),
                    infoWindow: InfoWindow(title: entry.placeName),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
