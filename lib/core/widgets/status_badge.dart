import 'package:flutter/material.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';

/// A status badge widget for displaying order status, table status, etc.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool outlined;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.outlined = false,
    this.fontSize,
  });

  // Predefined status badges
  factory StatusBadge.pending() => const StatusBadge(
        label: 'En attente',
        color: AppColors.warning,
        icon: Icons.schedule_rounded,
      );

  factory StatusBadge.inProgress() => const StatusBadge(
        label: 'En préparation',
        color: AppColors.info,
        icon: Icons.restaurant_rounded,
      );

  factory StatusBadge.ready() => const StatusBadge(
        label: 'Prête',
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );

  factory StatusBadge.served() => const StatusBadge(
        label: 'Servie',
        color: AppColors.primary,
        icon: Icons.room_service_rounded,
      );

  factory StatusBadge.paid() => const StatusBadge(
        label: 'Payée',
        color: AppColors.success,
        icon: Icons.paid_rounded,
      );

  factory StatusBadge.cancelled() => const StatusBadge(
        label: 'Annulée',
        color: AppColors.error,
        icon: Icons.cancel_rounded,
      );

  factory StatusBadge.available() => const StatusBadge(
        label: 'Libre',
        color: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
      );

  factory StatusBadge.occupied() => const StatusBadge(
        label: 'Occupée',
        color: AppColors.error,
        icon: Icons.block_rounded,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: (fontSize ?? 12) + 2, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill-shaped badge for displaying counts or small values
class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final double size;

  const CountBadge({
    super.key,
    required this.count,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color ?? AppColors.error,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.55,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

