import 'package:context_app/app/config/app_colors.dart';
import 'package:context_app/features/export/presentation/widgets/pdf_stamp_decoration.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Passport-style cover page for a Trip PDF export.
///
/// Intended to be rendered off-screen via `RepaintBoundary` and captured
/// as a PNG, then embedded as the first page of the PDF document.
class PdfCoverWidget extends StatelessWidget {
  final String tripName;
  final DateTime startDate;
  final DateTime endDate;
  final int entryCount;
  final String appName;
  final String tagline;
  final String stampLabel;
  final String entryCountLabel;

  const PdfCoverWidget({
    super.key,
    required this.tripName,
    required this.startDate,
    required this.endDate,
    required this.entryCount,
    required this.appName,
    required this.tagline,
    required this.stampLabel,
    required this.entryCountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final sameDay =
        startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;
    final dateLabel = sameDay
        ? dateFormat.format(startDate)
        : '${dateFormat.format(startDate)} – ${dateFormat.format(endDate)}';

    return Container(
      width: 800,
      height: 1131,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1923), Color(0xFF1A2B3D)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -80,
            child: Icon(
              Icons.explore,
              size: 440,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Positioned(
            top: 64,
            right: 64,
            child: PdfStampDecoration(label: stampLabel),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(80, 0, 80, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  tripName,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  entryCountLabel.replaceAll('{count}', '$entryCount'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 20,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 56),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.explore,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tagline,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
