import 'package:flutter/material.dart';

class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101922),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Knowledge Passport',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('知識護照', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          TimelineEntry(
            date: 'Today',
            time: '14:30 PM',
            title: 'Taipei Confucius Temple',
            location: 'Dalongdong, Taipei',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBm5_u-3C6swZe5P_gCEBwFTUssW4fUg3WFicrwiQJ7b7GLyWDvSpDqQDWtGSv3_hToP0SguL12LMrjc3MPSQVQf_Kjqlcj_SWagoT3HTrrY3Ine72NWmUbXHWiRSn3KnJzl5IwBFekCi2y3AA2qg0HVPHKm-L2P91Os1hB9K3fpDSNzFrgo8d5_uAq8rpLHio6LSUnpV1Dkpg2C7urU531UM7NPHni-eCwVOPKJss41ycQfckH41TiuJqOB-qb9VeUF3LTP2qx',
            question: 'Why are there no images of deities here?',
            answer:
                'Unlike Taoist temples, Confucian temples focus on "spirit tablets" rather than idols. This reflects Confucius\'s emphasis on honoring ancestors and sages through respectful rituals rather than worshiping divine figures. The absence of imagery encourages focus on his teachings.',
          ),
          TimelineEntry(
            date: 'Yesterday',
            time: '10:15 AM',
            title: 'Longshan Temple',
            location: 'Wanhua District, Taipei',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuA2yHSCuvyRzTW_dJpuOi1hoAfS6HaD2MonBFuRKnpPoNbvKUTiLIQQJW0hj_nW0YPW7p-8_MF4uPOOtb7z88hHbccikZ0xu--t56-63Du79yol2c97X5nlAeEwmfuLjRH1dNg4wLaJzbBZwDQMevge4iUwZsaK7V8lmE6Ey_aINL-rKedZh5jCYJ8ajGSgFLNkLeMVLQ1Kfw-xPLRBqhnlzHpPcNpyGMB40lLhei_DHuZGqbBuivFDugSMnbR1nGvzM1lQe-ii',
            question: 'What is the significance of the dragon pillars?',
            answer:
                'These pillars, known as "Dragon Columns," represent the balance of power and spiritual protection. The dragon is a symbol of imperial power and auspiciousness. In Longshan Temple, the unique pair of bronze dragon pillars in the main hall date back to 1920 and are considered masterpieces of Taiwanese craftsmanship.',
          ),
        ],
      ),
    );
  }
}

class TimelineEntry extends StatelessWidget {
  final String date;
  final String time;
  final String title;
  final String location;
  final String imageUrl;
  final String question;
  final String answer;

  const TimelineEntry({
    super.key,
    required this.date,
    required this.time,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Color(0xFF137fec),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF137fec),
                  ),
                  Container(width: 2, height: 260, color: Colors.white24),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2732),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            answer,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
