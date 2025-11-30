import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/admin/menus/manage_menus_screen.dart';
import 'package:restaurantapp/screens/admin/tables/manage_tables_screen.dart';
import 'package:restaurantapp/screens/admin/users/manage_users_screen.dart';
import 'package:restaurantapp/widgets/app_drawer_header.dart';
import 'package:restaurantapp/widgets/logout_list_tile.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const AppDrawerHeader(), // En-tête partagé
          _buildDrawerItem(
            icon: Icons.menu_book,
            title: 'Gérer les Menus',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageMenusScreen())),
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Gérer le Personnel',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageUsersScreen())),
          ),
          _buildDrawerItem(
            icon: Icons.table_restaurant,
            title: 'Gérer les Tables',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageTablesScreen())),
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart,
            title: 'Statistiques',
            onTap: () { /* TODO: Naviguer vers les statistiques */ },
          ),
          const Spacer(), // Pousse le bouton de déconnexion en bas
          const LogoutListTile(), // Bouton de déconnexion partagé
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}
