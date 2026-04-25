import 'package:context_app/app/config/app_colors.dart';
import 'package:flutter/material.dart';

/// A passport-style stamp badge with an icon and short label.
///
/// Used to decorate PDF cover and section headers, matching the aesthetic
/// of [JourneySharingCard].
class PdfStampDecoration extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? background;

  const PdfStampDecoration({
    super.key,
    required this.label,
    this.icon = Icons.verified,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (background ?? AppColors.primary).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40137fec),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
