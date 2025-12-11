import 'package:flutter/material.dart';
import 'package:context_app/features/player/screens/config_screen.dart';

class NearbyPlacesScreen extends StatelessWidget {
  const NearbyPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101922),
        title: const Text(
          'Nearby History',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Found 4 sites nearby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.my_location, color: Color(0xFF137fec), size: 16),
                SizedBox(width: 8),
                Text(
                  'High GPS Accuracy',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: const [
                  PlaceCard(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuD0Ee3ed27oJYTmj6oAD_IbpK68WPR67cgDq714sB1hEM7t0zWqRpGd8HoTQINfy_AwSLqsEuGgxiRwRjV2WS3ThZg4HoNTzpAQnHLaJtxQjnSdpByJG7YWDDRgYKtcDUta7z25Qjh2NXOpn6NPANrLy_YZ4ggBOqsxQiaReGQF9vkjE_ISA4H2uYO_vy8Wl3BtnS5JiIM7J_0vZaFMukuQcYpPX_WQqH6dCM0UpclcCK_z8eSaDvi_fdM9QGAt0AjTzkxcxbs5',
                    title: 'St. Mary\'s Cathedral',
                    hook: '"Gothic architecture hidden in plain sight."',
                    distance: '0.1 mi',
                  ),
                  PlaceCard(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAgHwT48dj-Q7EDxU1IhsV1jWETHp38QRIWgRLIVm4zXG_oG9OGnlnTKtJCP9GFpzf9_XPwEM3e2Lz7HwtwkS0T9gn31JY4ywTFvUvvFkI97PForYL_diNLedcBBJgJx8AZNwxuam2ik-bGuUCVT3Bi4x4S_hS3MIMMBQItUtlW5RhwSmy2Q5-Pw9S38W9v3USQ-uU6PfIJQZQf46x5GdG5vm_-qE9k5N4tHIlwejXGYMUiSjvOkX3PY7tWdPtBxqbeTK6HAzZw',
                    title: 'Old Port Market',
                    hook: '"The trading hub of the 18th century."',
                    distance: '0.3 mi',
                  ),
                  PlaceCard(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuB-y2dmLjPzSXQoiZFIIclWWM1TWnIxxUDIO6L8tbrzfxFZOPJH4IHMGq1uDP3F1_X3eYLSc5HzZivC9HtGe6rnoXErIBNXCktYgkmsCX6u0BNtPLlrb8foLvdG8gFgxI8c4Cja2CNMLiagtEA_br3ohiNkGBaUprnrHcunB93ErPPxJHj-q9UUYH_DhIGomkol7-0V_3LHCV8e5rVBPv0KqJ5rrbmUdlXa5GHKvWLjII59wo26ks9yVkAU_-4r_ahpkDWJne_j',
                    title: 'The Whispering Arch',
                    hook: '"An acoustic marvel and mystery."',
                    distance: '0.8 mi',
                  ),
                  PlaceCard(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDIzJfUmtcWIrpg3tryIzlrabZK8ONQqSX1Qq87vki6yEQLs7ar22MSnz5bjoRsZmhiirj6s0EspW-0xASjfRaUQpFsBvcv2IApvgK0fE1KFyBwtqy4BT_WgNRwnzcA8nNZ0ENFRFVqOAY2ZT7E4dy3-yjgqyMvYiXYYiz5sj0sEA8bW97m3QgHNCtsK-urfEIi2tTKrfSfhVuhz95ju9fxnU4HEQJQRRTueDYZP9WV3uKCnqHaK62TE2Jo5uAc20eqaYw6wbdr',
                    title: 'General\'s Plaza',
                    hook: '"Commemorating the great victory of 1812."',
                    distance: '1.2 mi',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String hook;
  final String distance;

  const PlaceCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.hook,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C2732),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(0x1A)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const ConfigScreen()));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hook,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me,
                          color: Color(0xFF137fec),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: Color(0xFF137fec),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
