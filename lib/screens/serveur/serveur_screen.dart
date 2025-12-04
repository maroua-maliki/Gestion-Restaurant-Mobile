import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';
import 'package:restaurantapp/core/widgets/app_card.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/services/table_service.dart';
import 'package:restaurantapp/screens/serveur/mes_commandes_screen.dart';
import 'package:restaurantapp/screens/serveur/mes_tables_screen.dart';
import 'package:restaurantapp/screens/serveur/nouvelle_commande_screen.dart';
import 'package:restaurantapp/screens/serveur/paiement_screen.dart';

class ServeurScreen extends StatelessWidget {
  const ServeurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final orderService = OrderService();
    final tableService = TableService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Text(
            'Bienvenue ! 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Voici votre tableau de bord',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Quick stats
          if (currentUser != null)
            StreamBuilder<List<OrderModel>>(
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
                    final occupiedTables = tableDocs
                        .where((doc) => doc['isAvailable'] == false)
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long_rounded,
                            value: activeOrders.toString(),
                            label: 'Commandes actives',
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.table_restaurant_rounded,
                            value: '$occupiedTables/${tableDocs.length}',
                            label: 'Tables occupées',
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.payment_rounded,
                            value: pendingPayments.toString(),
                            label: 'À encaisser',
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

          const SizedBox(height: 32),

          // Actions section
          Text(
            'Actions rapides',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Dashboard cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              DashboardCard(
                title: 'Nouvelle\nCommande',
                icon: Icons.add_circle_rounded,
                color: AppColors.serveurAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NouvelleCommandeScreen()),
                ),
              ),
              DashboardCard(
                title: 'Mes\nCommandes',
                icon: Icons.receipt_long_rounded,
                color: AppColors.chefAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MesCommandesScreen()),
                ),
              ),
              DashboardCard(
                title: 'Mes\nTables',
                icon: Icons.table_restaurant_rounded,
                color: AppColors.adminAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MesTablesScreen()),
                ),
              ),
              DashboardCard(
                title: 'Paiement',
                icon: Icons.payment_rounded,
                color: AppColors.success,
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
