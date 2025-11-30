import 'package:flutter/material.dart';
import 'package:restaurantapp/widgets/serveur_drawer.dart';

class ServeurScreen extends StatelessWidget {
  const ServeurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ServeurDrawer(),
      appBar: AppBar(
        title: const Text('Espace Serveur'),
      ),
      body: const Center(
        child: Text('Bienvenue, Serveur !'),
      ),
    );
  }
}
