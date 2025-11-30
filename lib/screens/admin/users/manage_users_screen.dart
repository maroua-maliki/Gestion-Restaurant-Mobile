import 'package:flutter/material.dart';
import 'package:restaurantapp/models/user_model.dart';
import 'package:restaurantapp/services/user_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

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
      appBar: AppBar(
        title: const Text('Gestion du Personnel'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _userService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Une erreur est survenue: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun utilisateur trouvé."));
          }

          // --- FILTRAGE ET TRI CÔTÉ CLIENT ---
          final allUsers = snapshot.data!;
          // 1. Filtrer pour ne garder que les non-supprimés
          final activeUsers = allUsers.where((user) => user.deletedAt == null).toList();

          // 2. Trier la liste filtrée
          activeUsers.sort((a, b) {
            if (a.role == 'Admin') return -1;
            if (b.role == 'Admin') return 1;
            return a.displayName.compareTo(b.displayName);
          });
          // --- FIN DE LA SECTION ---

          if (activeUsers.isEmpty) {
            return const Center(child: Text("Aucun utilisateur à afficher."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: activeUsers.length,
            itemBuilder: (context, index) => _buildUserCard(context, activeUsers[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
      ),
    );
  }

  // ... (le reste du code est inchangé et correct) ...
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
          title: Text(user == null ? 'Nouvel Utilisateur' : 'Modifier Utilisateur'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: displayNameController, decoration: const InputDecoration(labelText: 'Nom complet'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Requis' : null),
                  const SizedBox(height: 16),
                  if (user == null) ...[
                    TextFormField(controller: passwordController, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true, validator: (v) => v!.length < 6 ? '6 caractères min.' : null),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: ['Chef', 'Serveur'].map((String role) => DropdownMenuItem<String>(value: role, child: Text(role))).toList(),
                    onChanged: (newValue) => setState(() => selectedRole = newValue!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
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
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(user == null ? 'Créer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${user.displayName} ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AppUser user) {
    final roleColor = _getRoleColor(user.role);
    final roleIcon = _getRoleIcon(user.role);
    final bool isActive = user.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: isActive ? 2.0 : 0.5,
      color: isActive ? Colors.white : Colors.grey[200],
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(backgroundColor: roleColor.withOpacity(0.15), child: Icon(roleIcon, color: roleColor)),
        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email ?? 'Email non fourni'),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(user.role, style: const TextStyle(color: Colors.white)), backgroundColor: roleColor, padding: const EdgeInsets.symmetric(horizontal: 4.0), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                const SizedBox(width: 8),
                Chip(
                  label: Text(isActive ? 'Actif' : 'Inactif'),
                  backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100, 
                  labelStyle: TextStyle(color: isActive ? Colors.green.shade900 : Colors.red.shade900),
                  padding: const EdgeInsets.symmetric(horizontal: 4.0), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
        trailing: user.role == 'Admin' ? null : PopupMenuButton<String>(
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
            const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Modifier'))),
            PopupMenuItem<String>(
                value: 'toggleStatus',
                child: ListTile(leading: Icon(isActive ? Icons.block : Icons.check_circle_outline), title: Text(isActive ? 'Désactiver' : 'Activer'))
            ),
            const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Supprimer', style: TextStyle(color: Colors.red)))),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.purple;
      case 'chef': return Colors.orange;
      case 'serveur': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings;
      case 'chef': return Icons.restaurant;
      case 'serveur': return Icons.room_service;
      default: return Icons.person;
    }
  }
}
