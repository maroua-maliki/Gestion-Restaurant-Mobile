import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/login/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Changer le mot de passe'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                      validator: (v) => (v?.length ?? 0) < 6 ? '6 caractères minimum' : null,
                    ),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                      validator: (v) => v != newPasswordController.text ? 'Les mots de passe ne correspondent pas' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      try {
                        // Re-authentification de l'utilisateur
                        final cred = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentPasswordController.text,
                        );
                        await user.reauthenticateWithCredential(cred);

                        // Si la ré-authentification réussit, changer le mot de passe
                        await user.updatePassword(newPasswordController.text);

                        if(context.mounted) {
                           Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe changé avec succès !'), backgroundColor: Colors.green));
                        }

                      } on FirebaseAuthException catch (e) {
                        if(context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.code == 'wrong-password' ? 'Le mot de passe actuel est incorrect.' : 'Une erreur est survenue.'), backgroundColor: Colors.red));
                        }
                      } finally {
                         if(context.mounted) {
                           setState(() => isLoading = false);
                         }
                      }
                    }
                  },
                  child: isLoading ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Changer le mot de passe'),
          onTap: () => _showChangePasswordDialog(context),
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
