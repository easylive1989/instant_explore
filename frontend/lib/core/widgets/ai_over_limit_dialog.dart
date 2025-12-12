import 'package:flutter/material.dart';

class AiOverLimitDialog extends StatelessWidget {
  const AiOverLimitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors from design
    const surfaceColor = Color(0xFF182430);
    const errorBgColor = Color(0x1AF44336); // Red-500/10
    const errorIconColor = Color(0xFFEF5350); // Red-400
    const textColor = Colors.white;
    const textSecondaryColor = Color(0xFF94A3B8); // slate-400
    const buttonColor = Colors.white;
    const buttonTextColor = Color(0xFF0F172A); // slate-900

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: errorBgColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error, color: errorIconColor, size: 28),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Usage Limit Reached',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            const Text(
              "You've reached your daily AI usage limit. Please try again in 15 minutes.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Dismiss Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
