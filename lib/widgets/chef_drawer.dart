import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/main_screen.dart';
import 'package:restaurantapp/widgets/app_drawer_header.dart';
import 'package:restaurantapp/widgets/logout_list_tile.dart';

class ChefDrawer extends StatelessWidget {
  const ChefDrawer({super.key});

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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen(userRole: 'Chef')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Commandes en cuisine'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen(userRole: 'Chef')),
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
