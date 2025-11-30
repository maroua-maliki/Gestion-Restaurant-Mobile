import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/admin/menus/manage_plats_screen.dart';
import 'package:restaurantapp/screens/admin/tables/manage_tables_screen.dart';
import 'package:restaurantapp/screens/admin/users/manage_users_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On ne retourne plus de Scaffold, juste le contenu
    return GridView.count(
      padding: const EdgeInsets.all(16.0),
      crossAxisCount: 2, 
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _buildDashboardCard(context, icon: Icons.restaurant_menu, label: 'Gérer les Menus', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePlatsScreen()))),
        _buildDashboardCard(context, icon: Icons.people, label: 'Gérer le Personnel', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUsersScreen()))),
        _buildDashboardCard(context, icon: Icons.table_restaurant, label: 'Gérer les Tables', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageTablesScreen()))),
        _buildDashboardCard(context, icon: Icons.bar_chart, label: 'Statistiques', onTap: () {}),
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16.0),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
