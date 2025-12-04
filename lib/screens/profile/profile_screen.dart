import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';
import 'package:restaurantapp/core/widgets/empty_state.dart';

// Couleurs du thème restaurant
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    }
  }

  Color _getRoleColor(String? role) {
    if (role == 'Admin') return _warmOrange;
    switch (role) {
      case 'Chef':
        return AppColors.chefAccent;
      case 'Serveur':
        return AppColors.serveurAccent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const EmptyState(
        icon: Icons.person_off_rounded,
        title: 'Non connecté',
        subtitle: 'Aucun utilisateur connecté',
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Chargement du profil...');
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const ErrorState(message: 'Impossible de charger les données');
        }

        final userData = snapshot.data!.data()!;
        final isAdmin = userData['role'] == 'Admin';
        final roleColor = _getRoleColor(userData['role']);

        // Déterminer les couleurs en fonction du rôle
        final Color backgroundColor = isAdmin ? _cream : AppColors.background;
        final Color textColor = isAdmin ? _deepBrown : AppColors.textPrimary;
        final Color cardColor = isAdmin ? Colors.white : AppColors.surface;
        final Color accentColor = isAdmin ? _gold : AppColors.primary;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileHeader(userData, roleColor, cardColor, textColor),
                const SizedBox(height: 24),
                _buildInfoSection(userData, cardColor, textColor, accentColor),
                const SizedBox(height: 24),
                _buildActionsSection(cardColor, textColor, accentColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData, Color roleColor, Color cardColor, Color textColor) {
    final displayName = userData['displayName'] ?? 'Utilisateur';
    final role = userData['role'] ?? 'Rôle non défini';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [roleColor, roleColor.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            displayName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: GoogleFonts.inter(
                color: roleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> userData, Color cardColor, Color textColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.email_rounded,
            'Email',
            userData['email'] ?? 'Non disponible',
            accentColor,
            textColor,
          ),
          Divider(height: 24, color: accentColor.withValues(alpha: 0.2)),
          _buildInfoRow(
            Icons.badge_rounded,
            'Identifiant',
            currentUser?.uid.substring(0, 8) ?? 'N/A',
            accentColor,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color accentColor, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(Color cardColor, Color textColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            Icons.lock_outline_rounded,
            'Changer le mot de passe',
            accentColor,
            textColor,
            () {
              // TODO: Implement password change
            },
          ),
          _buildActionTile(
            Icons.help_outline_rounded,
            'Aide et support',
            accentColor,
            textColor,
            () {
              // TODO: Implement help
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color accentColor, Color textColor, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accentColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.4)),
      onTap: onTap,
    );
  }
}
