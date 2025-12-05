import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/screens/admin/menus/manage_plats_screen.dart';
import 'package:restaurantapp/screens/admin/orders/admin_orders_screen.dart';
import 'package:restaurantapp/screens/admin/statistics/statistics_screen.dart';
import 'package:restaurantapp/screens/admin/tables/manage_tables_screen.dart';
import 'package:restaurantapp/screens/admin/users/manage_users_screen.dart';

// Restaurant theme colors
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);
const Color _lightBrown = Color(0xFF8B6914);

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cream, Color(0xFFFFF5E6)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with restaurant branding
            _buildHeader(context),
            const SizedBox(height: 24),

            // Quick stats
            _buildStatsSection(),

            const SizedBox(height: 28),

            // Management section
            _buildSectionTitle(context, 'Gestion', Icons.settings_rounded),
            const SizedBox(height: 16),

            // Dashboard cards grid
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth > 400 ? 1.0 : 0.95,
                  children: [
                    _RestaurantDashboardCard(
                      title: 'Commandes',
                      subtitle: 'Suivi',
                      icon: Icons.receipt_long_rounded,
                      color: _warmOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                      ),
                    ),
                    _RestaurantDashboardCard(
                      title: 'Plats',
                      subtitle: 'Menu',
                      icon: Icons.restaurant_menu_rounded,
                      color: _lightBrown,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManagePlatsScreen()),
                      ),
                    ),
                    _RestaurantDashboardCard(
                      title: 'Personnel',
                      subtitle: 'Équipe',
                      icon: Icons.people_rounded,
                      color: _deepBrown,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ManageUsersScreen()),
                      ),
                    ),
                    _RestaurantDashboardCard(
                      title: 'Tables',
                      subtitle: 'Salle',
                      icon: Icons.table_restaurant_rounded,
                      color: _gold,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageTablesScreen()),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Analytics section
            _buildSectionTitle(context, 'Statistiques', Icons.bar_chart_rounded),
            const SizedBox(height: 16),
            _buildStatisticsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepBrown, Color(0xFF5D3A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _deepBrown.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _warmOrange,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _warmOrange.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administration',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez votre restaurant',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _gold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant, color: _gold, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _warmOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _warmOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _deepBrown,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gold.withOpacity(0.5), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _deepBrown.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_warmOrange, _warmOrange.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _warmOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voir les statistiques',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _deepBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Commandes, revenus, performances...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, color: _warmOrange, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tables').snapshots(),
          builder: (context, tableSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('plats').snapshots(),
              builder: (context, platSnapshot) {
                final userCount = userSnapshot.data?.docs.length ?? 0;
                final tableCount = tableSnapshot.data?.docs.length ?? 0;
                final platCount = platSnapshot.data?.docs.length ?? 0;

                return Row(
                  children: [
                    Expanded(
                      child: _RestaurantStatCard(
                        icon: Icons.people_rounded,
                        value: userCount.toString(),
                        label: 'Personnel',
                        color: _deepBrown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RestaurantStatCard(
                        icon: Icons.table_restaurant_rounded,
                        value: tableCount.toString(),
                        label: 'Tables',
                        color: _gold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RestaurantStatCard(
                        icon: Icons.restaurant_menu_rounded,
                        value: platCount.toString(),
                        label: 'Plats',
                        color: _warmOrange,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RestaurantStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _RestaurantStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RestaurantDashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.75)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _deepBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
