class AppUser {
  final String uid;
  final String? email;
  final String role;
  final String displayName;
  final bool isActive;

  AppUser({
    required this.uid,
    this.email,
    required this.role,
    required this.displayName,
    this.isActive = true,
  });

  // Crée un AppUser depuis un document Firestore
  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      email: data['email'],
      // Fournit un rôle par défaut si non spécifié
      role: data['role'] ?? 'Serveur',
      // Crée un nom d'affichage à partir de l'email si non disponible
      displayName: data['displayName'] ?? data['email'] ?? 'Utilisateur inconnu',
      isActive: data['isActive'] ?? true,
    );
  }
}
