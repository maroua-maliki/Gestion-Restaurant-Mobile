import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/services/menu_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

class ManagePlatsScreen extends StatefulWidget {
  const ManagePlatsScreen({super.key});

  @override
  State<ManagePlatsScreen> createState() => _ManagePlatsScreenState();
}

class _ManagePlatsScreenState extends State<ManagePlatsScreen> {
  final MenuService _menuService = MenuService();
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Gestion des Plats'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _menuService.getCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final categories = snapshot.data!.docs;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() {
                    _selectedCategoryId = (value == '') ? null : value;
                  });
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem<String>(value: '', child: Text('Toutes les catégories')),
                    ...categories.map((doc) => PopupMenuItem<String>(value: doc.id, child: Text((doc.data() as Map)['name'])))
                  ];
                },
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _menuService.getMenuItems(_selectedCategoryId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Aucun plat à afficher."));
          
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) => _buildPlatCard(snapshot.data!.docs[index]),
          );
        },
      ),
       floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un Plat'),
      ),
    );
  }

  Widget _buildPlatCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isAvailable = data['isAvailable'] ?? true;
    final imageUrl = data['imageUrl'];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMenuItemDialog(menuItem: doc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.error))
                  : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${data['price']} DH', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  SwitchListTile(
                    title: const Text('Dispo.', style: TextStyle(fontSize: 12)),
                    value: isAvailable,
                    onChanged: (val) => _menuService.updateMenuItem(doc.id, {'isAvailable': val}),
                    dense: true,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showMenuItemDialog({DocumentSnapshot? menuItem}) { 
    final isEditing = menuItem != null;
    final data = isEditing ? menuItem!.data() as Map<String, dynamic> : {};

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name']);
    final descriptionController = TextEditingController(text: data['description']);
    final priceController = TextEditingController(text: data['price']?.toString());
    String? selectedCategoryId = data['categoryId'];
    File? _imageFile;
    String? currentImageUrl = data['imageUrl'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Modifier le Plat' : 'Nouveau Plat'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: _menuService.getCategories(),
                        builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();
                             return DropdownButtonFormField<String>(
                                value: selectedCategoryId,
                                hint: const Text('Catégorie'),
                                items: snapshot.data!.docs.map((doc) {
                                  return DropdownMenuItem<String>(value: doc.id, child: Text((doc.data() as Map<String, dynamic>)['name']));
                                }).toList(),
                                onChanged: (val) => setState(() => selectedCategoryId = val),
                                validator: (v) => v == null ? 'Requis' : null,
                              );
                        }
                      ),
                      TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom du plat'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                      TextFormField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                      TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Prix (en DH)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.bottomRight, 
                        children: [
                          Container(
                            width: double.infinity,
                            height: 150,
                            color: Colors.grey[200],
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : (currentImageUrl?.isNotEmpty ?? false)
                                    ? Image.network(currentImageUrl!, fit: BoxFit.cover) 
                                    : const Center(child: Icon(Icons.camera_alt, color: Colors.grey)),
                          ),
                          if (_imageFile != null || (currentImageUrl?.isNotEmpty ?? false))
                            // On retire le Container noir pour ne garder que l'icône
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4.0)]), // Ombre pour la visibilité
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                  currentImageUrl = null;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: () async {
                          final file = await _menuService.pickImage();
                          if (file != null) setState(() => _imageFile = file);
                      }, child: const Text('Choisir une image')),
                    ],
                  ),
                ),
              ),
              actions: [
                if(isEditing) TextButton(onPressed: () async { await _menuService.deleteMenuItem(menuItem.id); if(mounted) Navigator.pop(context); }, child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      String? finalImageUrl = currentImageUrl;
                      if (_imageFile != null) {
                        finalImageUrl = await _menuService.uploadImage(_imageFile!, nameController.text);
                      }

                      final menuItemData = {
                        'name': nameController.text,
                        'description': descriptionController.text,
                        'price': double.parse(priceController.text),
                        'categoryId': selectedCategoryId,
                        'imageUrl': finalImageUrl,
                        'isAvailable': data['isAvailable'] ?? true,
                      };

                      if (isEditing) {
                        await _menuService.updateMenuItem(menuItem.id, menuItemData);
                      } else {
                        await _menuService.addMenuItem(menuItemData);
                      }
                      if(context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
