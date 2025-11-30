import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/services/menu_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final MenuService _menuService = MenuService();

  IconData _getIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('boisson')) return Icons.local_bar;
    if (name.contains('dessert')) return Icons.cake;
    if (name.contains('entrée')) return Icons.restaurant;
    if (name.contains('plat')) return Icons.restaurant_menu;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Gestion des Catégories')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _menuService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune catégorie."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final categoryName = data['name'] ?? 'Sans nom';
              final icon = _getIconForCategory(categoryName);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => _showCategoryDialog(category: doc),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _showCategoryDialog({DocumentSnapshot? category}) {
    final isEditing = category != null;
    final data = isEditing ? category!.data() as Map<String, dynamic> : {};
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifier la Catégorie' : 'Nouvelle Catégorie'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom de la catégorie', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
          ),
          actions: [
            if(isEditing)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDelete(category);
                },
                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final categoryData = {
                    'name': nameController.text,
                  };
                  if (isEditing) {
                    await _menuService.updateCategory(category.id, categoryData);
                  } else {
                    // LA LIGNE QUI POSAIT PROBLÈME A ÉTÉ COMPLÈTEMENT SUPPRIMÉE
                    await _menuService.addCategory(categoryData);
                  }
                  if(mounted) Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(DocumentSnapshot category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Supprimer cette catégorie supprimera aussi tous les plats associés. Êtes-vous sûr ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await _menuService.deleteCategory(category.id);
              if(mounted) Navigator.pop(context);
            },
             style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Supprimer'),
          )
        ]
      )
    );
  }
}
