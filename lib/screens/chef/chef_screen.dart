import 'package:flutter/material.dart';

class ChefScreen extends StatelessWidget {
  const ChefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On ne retourne plus de Scaffold, juste le contenu de la page.
    return const Center(
      child: Text('Écran d\'accueil du Chef...'),
    );
  }
}
