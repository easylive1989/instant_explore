import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/places/screens/nearby_places_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Immersive Background Layer
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
                ],
              ),
            ),
          ),
          // 2. Main Content Container (Glass Layer)
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section: Context & Status
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusIndicator(
                            icon: Icons.signal_cellular_alt,
                            label: 'GPS Strong',
                          ),
                          StatusIndicator(
                            icon: Icons.headphones,
                            label: 'Audio Ready',
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      HeaderCard(),
                    ],
                  ),
                  // Bottom Section: Primary Action & Helper
                  Column(
                    children: [
                      ExploreButton(),
                      SizedBox(height: 16),
                      HelperText(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;

  const StatusIndicator({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(0x0D),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: Colors.white.withAlpha(0x0D)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF137fec), size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderCard extends StatelessWidget {
  const HeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(0x1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(0x1A)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Location',
                style: TextStyle(
                  color: Color(0xFF137fec),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(Icons.info, color: Colors.white54, size: 20),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Gion District',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '12 historical sites nearby. Did you know Gion was built to accommodate the needs of travelers to the Yasaka Shrine?',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ExploreButton extends StatelessWidget {
  const ExploreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NearbyPlacesScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF137fec),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shadowColor: const Color(0x66137fec),
        elevation: 10,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            '探索周邊',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class HelperText extends StatelessWidget {
  const HelperText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app, color: Colors.white54, size: 14),
        SizedBox(width: 8),
        Text(
          'Tap to start AI audio guide',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
