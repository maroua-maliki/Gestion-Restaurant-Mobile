import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/main_screen.dart';
import 'package:restaurantapp/screens/serveur/mes_tables_screen.dart';
import 'package:restaurantapp/widgets/app_drawer_header.dart';
import 'package:restaurantapp/widgets/logout_list_tile.dart';

class ServeurDrawer extends StatelessWidget {
  const ServeurDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const AppDrawerHeader(),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () {
              // Naviguer vers l'écran principal pour le serveur
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen(userRole: 'Serveur')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_restaurant),
            title: const Text('Mes Tables'),
            onTap: () {
              // Naviguer vers l'écran des tables du serveur
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MesTablesScreen()),
              );
            },
          ),
          const Spacer(),
          const LogoutListTile(),
        ],
      ),
    );
  }
}
