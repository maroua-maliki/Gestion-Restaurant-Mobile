import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/screens/main_screen.dart';
import 'package:restaurantapp/screens/serveur/mes_commandes_screen.dart';
import 'package:restaurantapp/screens/serveur/mes_tables_screen.dart';
import 'package:restaurantapp/screens/serveur/nouvelle_commande_screen.dart';
import 'package:restaurantapp/screens/serveur/paiement_screen.dart';
import 'package:restaurantapp/widgets/app_drawer_header.dart';
import 'package:restaurantapp/widgets/logout_list_tile.dart';

// Restaurant theme colors (same as admin)
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

class ServeurDrawer extends StatelessWidget {
  const ServeurDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _cream,
      child: Column(
        children: [
          const AppDrawerHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildSectionHeader('Navigation'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_rounded,
                    title: 'Accueil',
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen(userRole: 'Serveur'))),
                  ),
                  const Divider(color: _gold, indent: 20, endIndent: 20, thickness: 0.5),

                  _buildSectionHeader('Actions'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.add_circle_rounded,
                    title: 'Nouvelle Commande',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NouvelleCommandeScreen())),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    title: 'Mes Commandes',
                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MesCommandesScreen())),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.table_restaurant_rounded,
                    title: 'Mes Tables',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MesTablesScreen())),
                  ),
                   _buildDrawerItem(
                    context: context,
                    icon: Icons.payment_rounded,
                    title: 'Paiement',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaiementScreen())),
                  ),
                  const SizedBox(height: 16),
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
            color: _deepBrown.withAlpha(128),
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
      hoverColor: _warmOrange.withAlpha(13),
    );
  }
}