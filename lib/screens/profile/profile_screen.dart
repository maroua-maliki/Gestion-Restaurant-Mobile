import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Future pour récupérer les données une seule fois
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("Aucun utilisateur connecté."));
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Impossible de charger les données de l'utilisateur."));
        }

        final userData = snapshot.data!.data()!;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileCard(context, userData),
            const SizedBox(height: 20),
            // Vous pouvez ajouter d'autres sections ici plus tard
          ],
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, Map<String, dynamic> userData) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                userData['displayName']?[0].toUpperCase() ?? 'U',
                style: TextStyle(fontSize: 48, color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userData['displayName'] ?? 'Nom non disponible',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(userData['role'] ?? 'Rôle non défini'),
              backgroundColor: colorScheme.primary,
              labelStyle: TextStyle(color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, userData['email'] ?? 'Email non disponible'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
