import 'package:flutter/material.dart';
import 'package:restaurantapp/widgets/chef_drawer.dart';

class ChefScreen extends StatelessWidget {
  const ChefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ChefDrawer(),
      appBar: AppBar(
        title: const Text('Espace Chef'),
      ),
      body: const Center(
        child: Text('Bienvenue, Chef !'),
      ),
    );
  }
}
