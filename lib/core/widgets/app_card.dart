import 'package:flutter/material.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';

/// A modern card widget with optional gradient, icon, and tap functionality
class AppCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? child;
  final EdgeInsets? padding;
  final double? elevation;
  final bool showShadow;

  const AppCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.gradient,
    this.onTap,
    this.trailing,
    this.child,
    this.padding,
    this.elevation,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child ??
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: gradient != null ? Colors.white : AppColors.textPrimary,
                                ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: gradient != null ? Colors.white70 : AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                    if (onTap != null && trailing == null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: gradient != null ? Colors.white70 : AppColors.textTertiary,
                      ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard card for main screens
class DashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const DashboardCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    if (badge != null && badge! > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: Text(
                            badge! > 99 ? '99+' : badge.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
