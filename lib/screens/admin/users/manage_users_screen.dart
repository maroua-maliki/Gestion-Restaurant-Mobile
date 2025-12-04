import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/models/user_model.dart';
import 'package:restaurantapp/services/user_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

// Restaurant theme colors
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(
          'Gestion du Personnel',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _deepBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _warmOrange), // Changed menu icon color here
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cream, Color(0xFFFFF5E6)],
          ),
        ),
        child: StreamBuilder<List<AppUser>>(
          stream: _userService.getUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _warmOrange));
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text("Une erreur est survenue", style: GoogleFonts.inter(color: _deepBrown)),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final allUsers = snapshot.data!;
            final activeUsers = allUsers.where((user) => user.deletedAt == null).toList();

            activeUsers.sort((a, b) {
              if (a.role == 'Admin') return -1;
              if (b.role == 'Admin') return 1;
              return a.displayName.compareTo(b.displayName);
            });

            if (activeUsers.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: activeUsers.length,
              itemBuilder: (context, index) => _buildUserCard(context, activeUsers[index]),
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_warmOrange, Color(0xFFD4500A)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _warmOrange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showUserDialog(),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Ajouter',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, size: 64, color: _gold),
          ),
          const SizedBox(height: 20),
          Text(
            "Aucun utilisateur",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _deepBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ajoutez votre premier membre d'équipe",
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showUserDialog({AppUser? user}) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    final displayNameController = TextEditingController(text: user?.displayName ?? '');
    String selectedRole = user?.role ?? 'Serveur';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _warmOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  user == null ? Icons.person_add_rounded : Icons.edit_rounded,
                  color: _warmOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user == null ? 'Nouvel Utilisateur' : 'Modifier Utilisateur',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    color: _deepBrown,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(displayNameController, 'Nom complet', Icons.person_outline, (v) => v!.isEmpty ? 'Requis' : null),
                  const SizedBox(height: 16),
                  _buildTextField(emailController, 'Email', Icons.email_outlined, (v) => v!.isEmpty ? 'Requis' : null, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  if (user == null) ...[
                    _buildTextField(passwordController, 'Mot de passe', Icons.lock_outline, (v) => v!.length < 6 ? '6 caractères min.' : null, obscureText: true),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Rôle',
                        labelStyle: GoogleFonts.inter(color: _deepBrown),
                        prefixIcon: Icon(Icons.badge_outlined, color: _warmOrange),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: _cream,
                      items: ['Chef', 'Serveur'].map((String role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(role, style: GoogleFonts.inter(color: _deepBrown)),
                      )).toList(),
                      onChanged: (newValue) => setState(() => selectedRole = newValue!),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_warmOrange, Color(0xFFD4500A)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      String? error;
                      if (user == null) {
                        error = await _userService.createUser(emailController.text, passwordController.text, displayNameController.text, selectedRole);
                      } else {
                        error = await _userService.updateUser(user.uid, emailController.text, displayNameController.text, selectedRole);
                      }
                      if (!mounted) return;
                      setState(() => isLoading = false);
                      Navigator.pop(context);
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(user == null ? 'Utilisateur créé' : 'Utilisateur mis à jour'), backgroundColor: Colors.green));
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(user == null ? 'Créer' : 'Enregistrer', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String? Function(String?) validator, {bool obscureText = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: _deepBrown),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: _warmOrange),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  void _confirmDelete(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirmer la suppression',
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: _deepBrown, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer ${user.displayName} ? Cette action est irréversible.',
          style: GoogleFonts.inter(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              final error = await _userService.deleteUser(user.uid);
              if (!mounted) return;
              Navigator.pop(context);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur supprimé'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Supprimer', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AppUser user) {
    final roleColor = _getRoleColor(user.role);
    final roleIcon = _getRoleIcon(user.role);
    final bool isActive = user.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? roleColor.withValues(alpha: 0.2) : Colors.grey[300]!),
        boxShadow: isActive ? [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: user.role == 'Admin' ? null : () => _showUserDialog(user: user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isActive ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [roleColor, roleColor.withValues(alpha: 0.7)],
                    ) : null,
                    color: isActive ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(roleIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isActive ? _deepBrown : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'Email non fourni',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: isActive ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.role,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? roleColor : Colors.grey[500],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'Actif' : 'Inactif',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isActive ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (user.role != 'Admin')
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: _cream,
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showUserDialog(user: user);
                      } else if (value == 'delete') {
                        _confirmDelete(user);
                      } else if (value == 'toggleStatus') {
                        final error = await _userService.toggleUserStatus(user.uid, !user.isActive);
                        if (mounted && error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, color: _warmOrange, size: 20),
                            const SizedBox(width: 12),
                            Text('Modifier', style: GoogleFonts.inter(color: _deepBrown)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggleStatus',
                        child: Row(
                          children: [
                            Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, color: isActive ? Colors.orange : Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Text(isActive ? 'Désactiver' : 'Activer', style: GoogleFonts.inter(color: _deepBrown)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Text('Supprimer', style: GoogleFonts.inter(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return _deepBrown;
      case 'chef': return _warmOrange;
      case 'serveur': return _gold;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings_rounded;
      case 'chef': return Icons.restaurant_rounded;
      case 'serveur': return Icons.room_service_rounded;
      default: return Icons.person_rounded;
    }
  }
}
