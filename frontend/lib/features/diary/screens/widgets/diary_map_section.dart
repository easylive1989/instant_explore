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
    if (entry.latitude == null || entry.longitude == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '位置',
          style: theme.textTheme.titleSmall?.copyWith(
            color: ThemeConfig.neutralText.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
      ],
    );
  }
}
