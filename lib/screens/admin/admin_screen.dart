import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/admin/menus/manage_menus_screen.dart';
import 'package:restaurantapp/screens/admin/tables/manage_tables_screen.dart';
import 'package:restaurantapp/screens/admin/users/manage_users_screen.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(), // La barre latérale est toujours là
      appBar: AppBar(
        title: const Text('Tableau de Bord Admin'),
      ),
      // On remet la grille de cartes ici
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2, 
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.restaurant_menu,
            label: 'Gérer les Menus',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ManageMenusScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.people,
            label: 'Gérer le Personnel',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUsersScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.table_restaurant,
            label: 'Gérer les Tables',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageTablesScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.bar_chart,
            label: 'Statistiques',
            onTap: () {
              // TODO: Naviguer vers l'écran des statistiques
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16.0),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
