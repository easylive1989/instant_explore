import 'package:flutter/material.dart';
import 'package:context_app/features/player/screens/qa_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Audio Guide',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Transcript
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ListView(
                  children: const [
                    SizedBox(height: 100),
                    Text(
                      'Ancient Romans walked these same stones, marveling at the scale of the structure before them.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 22,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'As you stand before the massive granite columns, notice the inscription above the portico.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'It reads \'M. AGRIPPA L.F. COS TERTIUM FECIT\', referring to the original builder, Marcus Agrippa.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 22,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Though the current building was actually constructed by Emperor Hadrian over a century later.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 22,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 200),
                  ],
                ),
              ),
            ),
            // Bottom Controls
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF101922).withOpacity(0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Stop 3',
                    style: TextStyle(
                      color: Color(0xFF137fec),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The Pantheon - Exterior',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: 0.35,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF137fec)),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('04:12', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('12:30', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.pause_circle_filled, color: Color(0xFF137fec), size: 64),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // AI Guide Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QAScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF192633),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Ask AI Guide',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
