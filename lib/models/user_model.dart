import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String role;
  final String displayName;
  final bool isActive;
  final Timestamp? deletedAt; // Champ pour la suppression logique

  AppUser({
    required this.uid,
    this.email,
    required this.role,
    required this.displayName,
    this.isActive = true,
    this.deletedAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      email: data['email'],
      role: data['role'] ?? 'Serveur',
      displayName: data['displayName'] ?? data['email'] ?? 'Utilisateur inconnu',
      isActive: data['isActive'] ?? true,
      deletedAt: data['deleted_at'], // Lecture du nouveau champ
    );
  }
}
