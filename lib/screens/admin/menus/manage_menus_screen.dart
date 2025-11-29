import 'package:flutter/material.dart';

class ManageMenusScreen extends StatelessWidget {
  const ManageMenusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
