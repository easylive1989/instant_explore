import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/player/models/narration_style.dart';

class PlayerScreen extends StatelessWidget {
  final Place place;
  final NarrationStyle narrationStyle;

  const PlayerScreen({
    super.key,
    required this.place,
    required this.narrationStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Colors from design
    const primaryColor = Color(0xFF137fec);
    const backgroundColor = Color(0xFF101922);
    const surfaceColor = Color(0xFF182430);
    // 0.3 alpha of primaryColor (0xFF137FEC) -> 0x4D137FEC
    const primaryColorShadow = Color(0x4D137FEC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'AUDIO GUIDE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Transcript Area
                Expanded(
                  child: Stack(
                    children: [
                      // Transcript List
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        children: [
                          const SizedBox(
                            height: 24,
                          ), // Spacing for top gradient
                          const Text(
                            'Ancient Romans walked these same stones, marveling at the scale of the structure before them.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8), // slate-400
                              fontSize: 20,
                              height: 1.6,
                              fontFamily:
                                  'Inter', // Fallback to system if not available
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Active Text
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: -20,
                                top: 6,
                                bottom: 6,
                                width: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const Text(
                                'As you stand before the massive granite columns, notice the inscription above the portico.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'It reads \'M. AGRIPPA L.F. COS TERTIUM FECIT\', referring to the original builder, Marcus Agrippa.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8), // slate-400
                              fontSize: 20,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Though the current building was actually constructed by Emperor Hadrian over a century later.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8), // slate-400
                              fontSize: 20,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(
                            height: 200,
                          ), // Bottom spacing for panel
                        ],
                      ),
                      // Top Gradient Fade
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: IgnorePointer(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [backgroundColor, Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom Gradient Fade (just above the panel)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: IgnorePointer(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [backgroundColor, Colors.transparent],
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
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101922).withValues(alpha: 0.85),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stop Info
                        const Text(
                          'STOP 3',
                          style: TextStyle(
                            color: primaryColor,
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
                        const SizedBox(height: 24),

                        // Progress Bar
                        SizedBox(
                          height: 6,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF334155), // slate-700
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: 0.35,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '04:12',
                              style: TextStyle(
                                color: Color(0xFF94A3B8), // slate-400
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '12:30',
                              style: TextStyle(
                                color: Color(0xFF94A3B8), // slate-400
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.replay_10, size: 32),
                              color: const Color(0xFF94A3B8),
                              onPressed: () {},
                            ),
                            Container(
                              height: 64,
                              width: 64,
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColorShadow,
                                    blurRadius: 16,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.pause,
                                  size: 32,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10, size: 32),
                              color: const Color(0xFF94A3B8),
                              onPressed: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Save action placeholder
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: surfaceColor, // #182430
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(
                                        alpha: 0.1,
                                      ), // Amber with opacity
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.bookmark_add,
                                      color: Color(0xFFF59E0B), // Amber-500
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Save to Knowledge Passport',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
