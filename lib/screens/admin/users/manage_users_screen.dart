import 'package:flutter/material.dart';
import 'package:restaurantapp/models/user_model.dart';
import 'package:restaurantapp/services/user_service.dart';

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

          final users = snapshot.data!;

          // --- LOGIQUE DE TRI ---
          users.sort((a, b) {
            if (a.role == 'Admin' && b.role != 'Admin') {
              return -1; // a (Admin) vient avant b
            }
            if (b.role == 'Admin' && a.role != 'Admin') {
              return 1; // b (Admin) vient avant a
            }
            // Sinon, tri par ordre alphabétique du nom
            return a.displayName.compareTo(b.displayName);
          });
          // --- FIN DE LA LOGIQUE DE TRI ---

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(context, user);
            },
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
                  TextFormField(
                    controller: displayNameController,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                    validator: (value) => value!.isEmpty ? 'Le nom est requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? 'L\'email est requis' : null,
                  ),
                  const SizedBox(height: 16),
                  if (user == null) ...[
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                      obscureText: true,
                      validator: (value) => value!.length < 6 ? '6 caractères min.' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: ['Chef', 'Serveur'].map((String role) {
                      return DropdownMenuItem<String>(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (newValue) => setState(() => selectedRole = newValue!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.15),
          child: Icon(roleIcon, color: roleColor),
        ),
        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email ?? 'Email non fourni'),
            const SizedBox(height: 8),
            Chip(
              label: Text(user.role, style: const TextStyle(color: Colors.white)),
              backgroundColor: roleColor,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: user.role == 'Admin' ? null : PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showUserDialog(user: user);
            } else if (value == 'delete') {
              _confirmDelete(user);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('Modifier')),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Supprimer', style: TextStyle(color: Colors.red))),
            ),
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
