import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/services/menu_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

// Restaurant theme colors
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

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
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(
          'Gérer les Plats',
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
        child: Column(
          children: [
            _buildFilterChips(),
            Expanded(child: _buildPlatsView()),
          ],
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
            onTap: () => _showMenuItemDialog(),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
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

  Widget _buildFilterChips() {
    return StreamBuilder<QuerySnapshot>(
      stream: _menuService.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: _warmOrange),
            ),
          );
        }

        final categories = snapshot.data!.docs;
        final sortedCategories = List<DocumentSnapshot>.from(categories)..sort((a, b) {
          final aName = ((a.data() as Map<String, dynamic>)?['name'] ?? '').toLowerCase();
          final bName = ((b.data() as Map<String, dynamic>)?['name'] ?? '').toLowerCase();
          final order = {'entrée': 1, 'plat': 2, 'dessert': 3, 'boisson': 4};
          return (order[aName] ?? 5).compareTo(order[bName] ?? 5);
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _deepBrown.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChoiceChip(context, 'Tout', null),
                const SizedBox(width: 10),
                ...sortedCategories.map((doc) {
                  final categoryName = (doc.data() as Map<String, dynamic>)['name'] ?? 'Inconnue';
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = categoryId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_warmOrange, Color(0xFFD4500A)])
              : null,
          color: isSelected ? null : _cream,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : _gold.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _warmOrange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : _deepBrown,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _menuService.getCategories(),
      builder: (context, categorySnapshot) {
        if (!categorySnapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: _warmOrange));
        }

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
              return Center(child: CircularProgressIndicator(color: _warmOrange));
            }
            if (!itemSnapshot.hasData || itemSnapshot.data!.docs.isEmpty) {
              return _buildEmptyPlatsState();
            }

            final items = itemSnapshot.data!.docs;

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
                    child: _buildCategoryHeader(categoriesMap[categoryId]?['name'] ?? 'Inconnue'),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65, // Further reduced aspect ratio to prevent overflow
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildPlatCard(groupedItems[categoryId]![index]),
                        childCount: groupedItems[categoryId]!.length,
                      ),
                    ),
                  ),
                ]).toList(),
              );
            } else {
              items.sort((a, b) {
                final aName = (a.data() as Map<String, dynamic>)?['name'] ?? '';
                final bName = (b.data() as Map<String, dynamic>)?['name'] ?? '';
                return aName.toLowerCase().compareTo(bName.toLowerCase());
              });
              return GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65, // Further reduced aspect ratio to prevent overflow
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
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

  Widget _buildCategoryHeader(String categoryName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_warmOrange, _gold],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            categoryName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _deepBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlatsState() {
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
            child: Icon(Icons.restaurant_menu_rounded, size: 64, color: _gold),
          ),
          const SizedBox(height: 20),
          Text(
            "Aucun plat",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _deepBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ajoutez votre premier plat",
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isAvailable = data['isAvailable'] ?? true;
    final imageUrl = data['imageUrl'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _deepBrown.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMenuItemDialog(menuItem: doc),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: isAvailable ? 1.0 : 0.4,
                      child: (imageUrl != null && imageUrl.isNotEmpty)
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: _cream,
                                child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey[400]),
                              ),
                            )
                          : Container(
                              color: _cream,
                              child: Icon(Icons.restaurant_rounded, size: 40, color: _gold.withValues(alpha: 0.5)),
                            ),
                    ),
                    if (!isAvailable)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Indisponible',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isAvailable ? _deepBrown : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['price']} DH',
                        style: GoogleFonts.inter(
                          color: isAvailable ? _warmOrange : Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'Dispo.',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: isAvailable,
                              onChanged: (val) => _menuService.updateMenuItem(doc.id, {'isAvailable': val}),
                              activeColor: _warmOrange,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
              backgroundColor: _cream,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? 'Modifier le plat' : 'Ajouter un plat',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  color: _deepBrown,
                ),
              ),
              content: SizedBox( // Added SizedBox to constrain width
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom du plat',
                            labelStyle: GoogleFonts.inter(color: _deepBrown.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _warmOrange, width: 1.5),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Veuillez entrer un nom' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Prix (DH)',
                            labelStyle: GoogleFonts.inter(color: _deepBrown.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _warmOrange, width: 1.5),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => value!.isEmpty ? 'Veuillez entrer un prix' : null,
                        ),
                         const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description (optionnel)',
                            labelStyle: GoogleFonts.inter(color: _deepBrown.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _warmOrange, width: 1.5),
                            ),
                          ),
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
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _warmOrange, width: 1.5),
                                ),
                              ),
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
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: _gold.withValues(alpha: 0.3)), 
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: _imageFile != null
                                      ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_imageFile!, fit: BoxFit.cover))
                                      : (data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                                          ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.network(data['imageUrl'], fit: BoxFit.cover))
                                          : Icon(Icons.image_rounded, color: _deepBrown.withValues(alpha: 0.3), size: 32)),
                                ),
                                if(isEditing && data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                                  Positioned(
                                    top: -8, right: -8,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final confirm = await _showImageDeleteConfirmationDialog();
                                        if (confirm ?? false) {
                                          setState(() => _isLoading = true);
                                          await _menuService.deleteMenuItemImage(menuItem.id, data['imageUrl']);
                                          setState(() {
                                            data['imageUrl'] = null;
                                            _isLoading = false;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 12),
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
                              },                            
                              icon: const Icon(Icons.add_photo_alternate_rounded),
                              label: const Text('Choisir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _warmOrange,
                                elevation: 0,
                                side: const BorderSide(color: _warmOrange),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                 if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
                if (!_isLoading) ...[
                  if(isEditing) 
                    TextButton(
                      child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      onPressed: (){
                         Navigator.of(context).pop();
                         _showDeleteConfirmationDialog(menuItem.id);
                      }
                    ),
                  if(!isEditing) const Spacer(),
                  TextButton(
                    child: Text('Annuler', style: TextStyle(color: _deepBrown.withValues(alpha: 0.7))),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _warmOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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