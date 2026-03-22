import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/plan/domain/models/plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Plan 卡片，支援左滑刪除
class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.place_outlined,
                    label: 'plan.stops'.tr(
                      namedArgs: {'count': plan.stops.length.toString()},
                    ),
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    label: 'plan.duration'.tr(
                      namedArgs: {
                        'minutes': plan.estimatedDuration.round().toString(),
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.straighten_outlined,
                    label: _formatDistance(plan.totalDistance),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('yyyy/MM/dd').format(plan.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
    );
  }
}
