
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/core/widgets/app_card.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/services/table_service.dart';
import 'package:restaurantapp/screens/serveur/mes_commandes_screen.dart';
import 'package:restaurantapp/screens/serveur/mes_tables_screen.dart';
import 'package:restaurantapp/screens/serveur/nouvelle_commande_screen.dart';
import 'package:restaurantapp/screens/serveur/paiement_screen.dart';

// Theme colors
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

class ServeurScreen extends StatelessWidget {
  const ServeurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final orderService = OrderService();
    final tableService = TableService();

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
            // Welcome section
            _buildHeader(context, currentUser),
            const SizedBox(height: 24),

            // Quick stats
            if (currentUser != null)
              _buildStatsSection(orderService, tableService, currentUser),

            const SizedBox(height: 32),

            // Actions section
            _buildSectionTitle(context, 'Actions rapides', Icons.bolt_rounded),
            const SizedBox(height: 16),

            // Dashboard cards grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                DashboardCard(
                  title: 'Nouvelle\nCommande',
                  icon: Icons.add_circle_rounded,
                  color: _warmOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NouvelleCommandeScreen()),
                  ),
                ),
                DashboardCard(
                  title: 'Mes\nCommandes',
                  icon: Icons.receipt_long_rounded,
                  color: _deepBrown,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MesCommandesScreen()),
                  ),
                ),
                DashboardCard(
                  title: 'Mes\nTables',
                  icon: Icons.table_restaurant_rounded,
                  color: _gold,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MesTablesScreen()),
                  ),
                ),
                DashboardCard(
                  title: 'Paiement',
                  icon: Icons.payment_rounded,
                  color: const Color(0xFF2E7D32),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaiementScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
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
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, ${user?.displayName?.split(' ').first ?? 'Serveur'} !',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voici votre tableau de bord',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _gold,
                  ),
                ),
              ],
            ),
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
      ],
    );
  }

  Widget _buildStatsSection(
      OrderService orderService, TableService tableService, User currentUser) {
    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getActiveOrdersForServer(currentUser.uid),
      builder: (context, orderSnapshot) {
        final activeOrders = orderSnapshot.data?.length ?? 0;
        final pendingPayments = orderSnapshot.data
                ?.where((o) => o.status == OrderStatus.served)
                .length ??
            0;

        return StreamBuilder<QuerySnapshot>(
          stream: tableService.getTablesForServer(currentUser.uid),
          builder: (context, tableSnapshot) {
            final tableDocs = tableSnapshot.data?.docs ?? [];
            final occupiedTables =
                tableDocs.where((doc) => doc['isAvailable'] == false).length;

            return Row(
              children: [
                Expanded(
                  child: _ServeurStatCard(
                    icon: Icons.receipt_long_rounded,
                    value: activeOrders.toString(),
                    label: 'Actives',
                    color: const Color(0xFF1E88E5), // Blue
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServeurStatCard(
                    icon: Icons.table_restaurant_rounded,
                    value: '$occupiedTables/${tableDocs.length}',
                    label: 'Occupées',
                    color: const Color(0xFFFDD835), // Yellow
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServeurStatCard(
                    icon: Icons.payment_rounded,
                    value: pendingPayments.toString(),
                    label: 'À Payer',
                    color: const Color(0xFF43A047), // Green
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ServeurStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ServeurStatCard({
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

