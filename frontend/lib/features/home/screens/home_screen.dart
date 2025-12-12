import 'package:context_app/core/config/api_config.dart';
import 'package:context_app/features/player/screens/config_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/places/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyPlaces = ref.watch(nearbyPlacesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF101922),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAVquA33CmpY8z_jSAhTaWCpD7_N9E1YheF1AMZemrva1YGHu-BWyECtoKx7y4fT7lbYD-kfqtvI2x6OHu0beZ2wnVEHjEZXhVhhMBj_UoGip60sjAuGyw_cnw98oSRIl8XL6Ino-uTdOJJ6cHlhJHiV-6Dn8AEh6eYA-T_iJp1LGYJxxbDorHRciFevGtjt9QlLHGPcod0QIB1RrZdYtfY9QGFofoKK3v4Lcwt-KYu6iZpcWxDgy8_v3ZV9jDeJb4K7DgyrhfQ',
                      fit: BoxFit.cover,
                      color: const Color(0x99000000),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
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
                  Positioned(
                    top: MediaQuery.of(context).size.height / 3,
                    left: MediaQuery.of(context).size.width / 2 - 150,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: const Color(0xFF137fec).withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF137fec,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(nearbyPlacesProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF137fec),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: nearbyPlaces.when(
                    data: (places) => ListView.builder(
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
                        'Error: $error',
                        style: const TextStyle(color: Colors.white),
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
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const ConfigScreen()));
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
                              color: Colors.white,
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
                          : 'PLACE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.formattedAddress,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
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
