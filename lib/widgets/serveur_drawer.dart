import 'package:flutter/material.dart';
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
          // TODO: Ajouter ici les options de menu spécifiques au Serveur
          // Exemple:
          // ListTile(leading: Icon(Icons.room_service), title: Text('Prendre une Commande'), onTap: () {}),
          const Spacer(),
          const LogoutListTile(),
        ],
      ),
    );
  }
}
