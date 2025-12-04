import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';
import 'package:restaurantapp/screens/login/login_screen.dart';

/// A unified, modern drawer widget for all user roles
class AppDrawer extends StatelessWidget {
  final String userRole;
  final String userName;
  final String userEmail;
  final List<DrawerMenuItem> menuItems;
  final int? selectedIndex;

  const AppDrawer({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userEmail,
    required this.menuItems,
    this.selectedIndex,
  });

  Color get _roleColor {
    switch (userRole) {
      case 'Admin':
        return AppColors.adminAccent;
      case 'Chef':
        return AppColors.chefAccent;
      case 'Serveur':
        return AppColors.serveurAccent;
      default:
        return AppColors.primary;
    }
  }

  LinearGradient get _roleGradient {
    switch (userRole) {
      case 'Admin':
        return AppColors.adminGradient;
      case 'Chef':
        return AppColors.chefGradient;
      case 'Serveur':
        return AppColors.serveurGradient;
      default:
        return AppColors.primaryGradient;
    }
  }

  IconData get _roleIcon {
    switch (userRole) {
      case 'Admin':
        return Icons.admin_panel_settings_rounded;
      case 'Chef':
        return Icons.restaurant_rounded;
      case 'Serveur':
        return Icons.room_service_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: _roleGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_roleIcon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(userEmail, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(userRole, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  if (item.isDivider) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(),
                    );
                  }
                  final isSelected = selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Material(
                      color: isSelected ? _roleColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: Icon(item.icon, color: isSelected ? _roleColor : AppColors.textSecondary),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: isSelected ? _roleColor : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: item.badge != null && item.badge! > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                                child: Text(item.badge.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: item.onTap,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Logout button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final int? badge;
  final bool isDivider;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.badge,
    this.isDivider = false,
  });

  const DrawerMenuItem.divider()
      : icon = Icons.remove,
        title = '',
        onTap = null,
        badge = null,
        isDivider = true;
}

