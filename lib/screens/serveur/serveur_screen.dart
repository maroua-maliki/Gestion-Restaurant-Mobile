
import 'package:flutter/material.dart';

class ServeurScreen extends StatelessWidget {
  const ServeurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Serveur'),
      ),
      body: const Center(
        child: Text('Bienvenue, Serveur !'),
      ),
    );
  }
}
