import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Changer le mot de passe'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe actuel',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                      validator: (v) => (v?.length ?? 0) < 6 ? '6 caractères minimum' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                      validator: (v) => v != newPasswordController.text ? 'Les mots de passe ne correspondent pas' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            try {
                              final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: currentPasswordController.text,
                              );
                              await user.reauthenticateWithCredential(cred);
                              await user.updatePassword(newPasswordController.text);

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Mot de passe changé avec succès !'),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.code == 'wrong-password'
                                        ? 'Le mot de passe actuel est incorrect.'
                                        : 'Une erreur est survenue.'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account section
          _buildSectionTitle(context, 'Compte'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Changer le mot de passe',
              subtitle: 'Modifier votre mot de passe',
              onTap: () => _showChangePasswordDialog(context),
            ),
          ]),

          const SizedBox(height: 24),

          // App section
          _buildSectionTitle(context, 'Application'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Gérer les notifications',
              onTap: () {
                // TODO: Implement notifications settings
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.language_rounded,
              title: 'Langue',
              subtitle: 'Français',
              onTap: () {
                // TODO: Implement language settings
              },
            ),
          ]),

          const SizedBox(height: 24),

          // About section
          _buildSectionTitle(context, 'À propos'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Version',
              subtitle: '1.0.0',
              showArrow: false,
              onTap: () {},
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Conditions d\'utilisation',
              onTap: () {
                // TODO: Show terms
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Logout button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutConfirmation(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text(
                'Déconnexion',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: showArrow
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary)
          : null,
      onTap: onTap,
    );
  }
}
