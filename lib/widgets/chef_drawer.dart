import 'package:flutter/material.dart';
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
          // TODO: Ajouter ici les options de menu spécifiques au Chef
          // Exemple:
          // ListTile(leading: Icon(Icons.kitchen), title: Text('Voir les Commandes'), onTap: () {}),
          const Spacer(),
          const LogoutListTile(),
        ],
      ),
    );
  }
}
