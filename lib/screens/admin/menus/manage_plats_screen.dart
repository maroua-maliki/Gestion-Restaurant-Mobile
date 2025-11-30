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
  String? _selectedCategoryName;

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
      appBar: AppBar(
        title: _selectedCategoryName == null
            ? const Text('Gestion des Plats')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIconForCategory(_selectedCategoryName!)),
                  const SizedBox(width: 8),
                  Text(_selectedCategoryName!),
                ],
              ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _menuService.getCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final categories = snapshot.data!.docs;
              return PopupMenuButton<Map<String, String?>>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() {
                    _selectedCategoryId = value['id'];
                    _selectedCategoryName = value['name'];
                  });
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem<Map<String, String?>>(value: {'id': null, 'name': null}, child: Text('Toutes les catégories')),
                    ...categories.map((doc) {
                      final categoryName = (doc.data() as Map)['name'] as String;
                      return PopupMenuItem<Map<String, String?>>(value: {'id': doc.id, 'name': categoryName}, child: Text(categoryName));
                    })
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
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.8, // Ratio ajusté pour le switch
              mainAxisSpacing: 12, 
              crossAxisSpacing: 12
            ),
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${data['price']} DH', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                  // --- RETOUR DE L'INTERRUPTEUR --- 
                  SwitchListTile(
                    title: const Text('Dispo.', style: TextStyle(fontSize: 12)),
                    value: isAvailable,
                    onChanged: (val) => _menuService.updateMenuItem(doc.id, {'isAvailable': val}),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuItemDialog({DocumentSnapshot? menuItem}) { 
    // Le code de la boîte de dialogue reste identique.
    // ...
  }
}
