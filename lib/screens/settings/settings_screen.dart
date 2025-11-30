import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/login/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On ne retourne plus de Scaffold
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Changer le mot de passe'),
          onTap: () {
            // TODO: Logique pour changer le mot de passe
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            }
          },
        ),
      ],
    );
  }
}
