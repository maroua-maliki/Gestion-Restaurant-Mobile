import 'package:flutter/material.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

class ManageMenusScreen extends StatelessWidget {
  const ManageMenusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(), // Ajout de la barre latérale
      appBar: AppBar(
        title: const Text('Gestion des Menus'),
      ),
      body: const Center(
        child: Text('Liste des plats...'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
