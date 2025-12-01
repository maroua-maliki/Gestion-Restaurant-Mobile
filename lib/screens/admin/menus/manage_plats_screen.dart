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
  String? _selectedCategoryId; // null signifie "Toutes les catégories"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Gérer les Plats'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildPlatsView()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un Plat'),
      ),
    );
  }

  Widget _buildFilterChips() {
    return StreamBuilder<QuerySnapshot>(
      stream: _menuService.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ));
        }

        final categories = snapshot.data!.docs;
         final sortedCategories = List<DocumentSnapshot>.from(categories)..sort((a,b) {
           final aName = ((a.data() as Map<String, dynamic>)?['name'] ?? '').toLowerCase();
           final bName = ((b.data() as Map<String, dynamic>)?['name'] ?? '').toLowerCase();
           final order = {'entrée': 1, 'plat': 2, 'dessert': 3, 'boisson': 4};
           return (order[aName] ?? 5).compareTo(order[bName] ?? 5);
        });


        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          color: Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChoiceChip(context, 'Tout', null),
                const SizedBox(width: 8),
                ...sortedCategories.map((doc) {
                  final categoryName = (doc.data() as Map<String, dynamic>)['name'] ?? 'Inconnue';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildChoiceChip(context, categoryName, doc.id),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoiceChip(BuildContext context, String label, String? categoryId) {
    final bool isSelected = _selectedCategoryId == categoryId;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedCategoryId = categoryId;
          });
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
      ),
      avatar: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary, size: 16) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent),
      ),
    );
  }

  Widget _buildPlatsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _menuService.getCategories(),
      builder: (context, categorySnapshot) {
        if (!categorySnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final categoriesMap = <String, Map<String, dynamic>>{
          for (var doc in categorySnapshot.data!.docs) doc.id: doc.data() as Map<String, dynamic>
        };

        int getCategoryOrder(String? categoryId) {
            final categoryName = categoriesMap[categoryId]?['name']?.toLowerCase() ?? '';
            if (categoryName.contains('entrée')) return 1;
            if (categoryName.contains('plat')) return 2;
            if (categoryName.contains('dessert')) return 3;
            if (categoryName.contains('boisson')) return 4;
            return 5;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _menuService.getMenuItems(_selectedCategoryId),
          builder: (context, itemSnapshot) {
            if (itemSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!itemSnapshot.hasData || itemSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucun plat à afficher.", style: TextStyle(fontSize: 16)));
            }

            final items = itemSnapshot.data!.docs;

            // --- Si on AFFICHE TOUT, on groupe par catégorie ---
            if (_selectedCategoryId == null) {
              final groupedItems = <String, List<DocumentSnapshot>>{};
              for (final item in items) {
                final categoryId = (item.data() as Map<String, dynamic>)['categoryId'] as String?;
                if (categoryId != null) {
                  (groupedItems[categoryId] ??= []).add(item);
                }
              }

              final sortedCategoryIds = groupedItems.keys.toList()
                ..sort((a, b) => getCategoryOrder(a).compareTo(getCategoryOrder(b)));

              return CustomScrollView(
                slivers: sortedCategoryIds.expand((categoryId) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Text(
                        categoriesMap[categoryId]?['name'] ?? 'Inconnue',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.8, mainAxisSpacing: 12, crossAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildPlatCard(groupedItems[categoryId]![index]),
                        childCount: groupedItems[categoryId]!.length,
                      ),
                    ),
                  ),
                ]).toList(),
              );
            }
            // --- Si une CATÉGORIE EST SÉLECTIONNÉE, on affiche une grille simple ---
            else {
              items.sort((a,b) {
                  final aName = (a.data() as Map<String, dynamic>)?['name'] ?? '';
                  final bName = (b.data() as Map<String, dynamic>)?['name'] ?? '';
                  return aName.toLowerCase().compareTo(bName.toLowerCase());
                });
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.8, mainAxisSpacing: 12, crossAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildPlatCard(items[index]),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildPlatCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isAvailable = data['isAvailable'] ?? true;
    final imageUrl = data['imageUrl'];

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2.0,
      child: InkWell(
        onTap: () => _showMenuItemDialog(menuItem: doc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Opacity(
                opacity: isAvailable ? 1.0 : 0.5,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.error))
                    : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8,8,8,0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${data['price']} DH', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
             SwitchListTile(
                    title: const Text('Dispo.', style: TextStyle(fontSize: 12)),
                    value: isAvailable,
                    onChanged: (val) => _menuService.updateMenuItem(doc.id, {'isAvailable': val}),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
             ),
          ],
        ),
      ),
    );
  }

 void _showMenuItemDialog({DocumentSnapshot? menuItem}) {
    final _formKey = GlobalKey<FormState>();
    final isEditing = menuItem != null;
    var data = isEditing ? menuItem!.data() as Map<String, dynamic> : <String, dynamic>{};

    final _nameController = TextEditingController(text: data['name']);
    final _priceController = TextEditingController(text: data['price']?.toString());
    final _descriptionController = TextEditingController(text: data['description']);
    String? _dialogSelectedCategoryId = data['categoryId'];
    File? _imageFile;
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Modifier le plat' : 'Ajouter un plat'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nom du plat', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Veuillez entrer un nom' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Prix (DH)', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value!.isEmpty ? 'Veuillez entrer un prix' : null,
                      ),
                       const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description (optionnel)', border: OutlineInputBorder()),
                         maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: _menuService.getCategories(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final categories = snapshot.data!.docs;
                          if (_dialogSelectedCategoryId != null && !categories.any((doc) => doc.id == _dialogSelectedCategoryId)) {
                            _dialogSelectedCategoryId = null; 
                          }
                          
                          return DropdownButtonFormField<String>(
                            value: _dialogSelectedCategoryId,
                            hint: const Text('Choisir une catégorie'),
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: categories.map((DocumentSnapshot doc) {
                              final catData = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(catData['name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _dialogSelectedCategoryId = newValue;
                              });
                            },
                            validator: (value) => value == null ? 'Veuillez choisir une catégorie' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- Sélecteur d'Image ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                                child: _imageFile != null
                                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                                    : (data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                                        ? Image.network(data['imageUrl'], fit: BoxFit.cover)
                                        : const Icon(Icons.image, color: Colors.grey)),
                              ),
                              if(isEditing && data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                                Positioned(
                                  top: -10, right: -10,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.red,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_forever, color: Colors.white, size: 12),
                                      onPressed: () async {
                                        final confirm = await _showImageDeleteConfirmationDialog();
                                        if (confirm ?? false) {
                                          setState(() => _isLoading = true);
                                          await _menuService.deleteMenuItemImage(menuItem.id, data['imageUrl']);
                                          setState(() {
                                            data['imageUrl'] = null;
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    ),
                                  ), 
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final pickedFile = await _menuService.pickImage();
                              if (pickedFile != null) {
                                setState(() { _imageFile = pickedFile; });
                              }
                            },                            icon: const Icon(Icons.photo_library),
                            label: const Text('Choisir'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                 if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
                if (!_isLoading) ...[
                  if(isEditing) 
                    TextButton(
                      child: const Text('Supprimer Plat', style: TextStyle(color: Colors.red)),
                      onPressed: (){
                         Navigator.of(context).pop();
                         _showDeleteConfirmationDialog(menuItem.id);
                      }
                    ),
                  const Spacer(),
                  TextButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ElevatedButton(
                    child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() { _isLoading = true; });

                        String? imageUrl = data['imageUrl'];
                        if (_imageFile != null) {
                          imageUrl = await _menuService.uploadImage(_imageFile!, _nameController.text);
                        }

                        final menuItemData = {
                          'name': _nameController.text,
                          'price': double.tryParse(_priceController.text) ?? 0.0,
                          'description': _descriptionController.text,
                          'categoryId': _dialogSelectedCategoryId,
                          'imageUrl': imageUrl ?? data['imageUrl'],
                          if(isEditing) 'isAvailable': data['isAvailable'] ?? true,
                          if(!isEditing) 'isAvailable': true,
                        };

                        try {
                          if (isEditing) {
                            await _menuService.updateMenuItem(menuItem.id, menuItemData);
                          } else {
                            await _menuService.addMenuItem(menuItemData);
                          }
                          Navigator.of(context).pop();
                        } catch (e) {
                           setState(() { _isLoading = false; });
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                        }
                      }
                    },
                  )
                ]
              ],
            );
          },
        );
      },
    );
  }
  
  Future<bool?> _showImageDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Supprimer l'image ?"),
          content: const Text("Voulez-vous vraiment supprimer l'image de ce plat ? Le plat lui-même ne sera pas supprimé."),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text("Supprimer l'image"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String menuItemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce plat ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer le Plat'),
              onPressed: () async {
                try {
                  await _menuService.deleteMenuItem(menuItemId);
                   Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plat supprimé avec succès'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la suppression : $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}