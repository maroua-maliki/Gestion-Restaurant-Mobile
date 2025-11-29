
import 'package:flutter/material.dart';

class ChefScreen extends StatelessWidget {
  const ChefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Chef'),
      ),
      body: const Center(
        child: Text('Bienvenue, Chef !'),
      ),
    );
  }
}
