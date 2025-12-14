import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/features/explore/models/place.dart';

class SaveSuccessScreen extends StatelessWidget {
  final Place place;
  final VoidCallback? onViewPassport;
  final VoidCallback? onContinueTour;

  const SaveSuccessScreen({
    super.key,
    required this.place,
    this.onViewPassport,
    this.onContinueTour,
  });

  @override
  Widget build(BuildContext context) {
    // Colors from design
    const backgroundColor = Color(0xFF101922);
    const successColor = Color(0xFF10b981);
    const primaryColor = Color(0xFF137fec);
    const cardColor = Color(0xFF1E293B); // Dark slate for card
    const textColor = Colors.white;
    const textSecondaryColor = Color(0xFF94A3B8); // slate-400

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'passport.title_uppercase'.tr(),
          style: const TextStyle(
            color: textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.close, color: textSecondaryColor, size: 24),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Pulse Animation / Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: successColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: successColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: successColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x4D10b981), // success/30
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bookmark_added,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'passport.item_saved'.tr(),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '"${place.name}" ${'passport.added_to_passport'.tr()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondaryColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // Place Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor, // slate-800
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    // Image Placeholder
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155), // slate-700
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: place.photos.isNotEmpty
                          ? Image.network(
                              'https://places.googleapis.com/v1/${place.photos.first.name}/media?maxHeightPx=400&maxWidthPx=400&key=${const String.fromEnvironment("GOOGLE_PLACES_API_KEY")}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.stadium,
                                  color: textSecondaryColor,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.stadium,
                                color: textSecondaryColor,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place.formattedAddress,
                            style: const TextStyle(
                              color: textSecondaryColor,
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

              const Spacer(flex: 3),

              // Buttons
              Column(
                children: [
                  ElevatedButton(
                    onPressed: onViewPassport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'passport.view_button'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onContinueTour ?? () => context.go('/'),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B), // slate-800
                      foregroundColor: const Color(0xFFE2E8F0), // slate-200
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'passport.continue_tour'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
