import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/screens/admin/menus/manage_categories_screen.dart';
import 'package:restaurantapp/screens/admin/menus/manage_plats_screen.dart';
import 'package:restaurantapp/screens/admin/statistics/statistics_screen.dart';
import 'package:restaurantapp/screens/admin/tables/manage_tables_screen.dart';
import 'package:restaurantapp/screens/admin/users/manage_users_screen.dart';
import 'package:restaurantapp/screens/main_screen.dart';
import 'package:restaurantapp/widgets/app_drawer_header.dart';
import 'package:restaurantapp/widgets/logout_list_tile.dart';

// Restaurant theme colors
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _cream,
      child: Column(
        children: [
          const AppDrawerHeader(), // Updated header
          Expanded( // Wrap the scrollable content in Expanded
            child: SingleChildScrollView( // Add scrolling capability
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildSectionHeader('Navigation'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_rounded,
                    title: 'Accueil',
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen(userRole: 'Admin'))),
                  ),
                  const Divider(color: _gold, indent: 20, endIndent: 20, thickness: 0.5),
                  
                  _buildSectionHeader('Menu'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.category_rounded,
                    title: 'Catégories',
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen())),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Plats',
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagePlatsScreen())),
                  ),
                  
                  const Divider(color: _gold, indent: 20, endIndent: 20, thickness: 0.5),
                  
                  _buildSectionHeader('Gestion'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.people_rounded,
                    title: 'Personnel',
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageUsersScreen())),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.table_restaurant_rounded,
                    title: 'Tables',
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageTablesScreen())),
                  ),
                  
                  const Divider(color: _gold, indent: 20, endIndent: 20, thickness: 0.5),
                  
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    title: 'Statistiques',
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                    ),
                  ),
                  const SizedBox(height: 16), // Extra space at bottom
                ],
              ),
            ),
          ),
          const LogoutListTile(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _deepBrown.withValues(alpha: 0.5),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        icon, 
        color: isHighlight ? _warmOrange : _deepBrown,
        size: 24
      ),
      title: Text(
        title, 
        style: GoogleFonts.inter(
          fontSize: 15, 
          fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
          color: isHighlight ? _warmOrange : _deepBrown,
        )
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: _warmOrange.withValues(alpha: 0.05),
    );
  }
}
