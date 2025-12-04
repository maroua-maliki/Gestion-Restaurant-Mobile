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

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final MenuService _menuService = MenuService();

  IconData _getIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('boisson')) return Icons.local_bar_rounded;
    if (name.contains('dessert')) return Icons.cake_rounded;
    if (name.contains('entrée')) return Icons.restaurant_rounded;
    if (name.contains('plat')) return Icons.restaurant_menu_rounded;
    return Icons.category_rounded;
  }

  Color _getColorForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('boisson')) return const Color(0xFF5C6BC0);
    if (name.contains('dessert')) return const Color(0xFFEC407A);
    if (name.contains('entrée')) return _gold;
    if (name.contains('plat')) return _warmOrange;
    return _deepBrown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(
          'Gestion des Catégories',
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
        child: StreamBuilder<QuerySnapshot>(
          stream: _menuService.getCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _warmOrange));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final categoryName = data['name'] ?? 'Sans nom';
                final icon = _getIconForCategory(categoryName);
                final color = _getColorForCategory(categoryName);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showCategoryDialog(category: doc),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [color, color.withValues(alpha: 0.7)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                categoryName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: _deepBrown,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _cream,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.chevron_right_rounded, color: color, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
            onTap: () => _showCategoryDialog(),
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
            child: Icon(Icons.category_rounded, size: 64, color: _gold),
          ),
          const SizedBox(height: 20),
          Text(
            "Aucune catégorie",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _deepBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ajoutez votre première catégorie",
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
        ],
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
                  isEditing ? Icons.edit_rounded : Icons.category_rounded,
                  color: _warmOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEditing ? 'Modifier la Catégorie' : 'Nouvelle Catégorie',
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withValues(alpha: 0.3)),
              ),
              child: TextFormField(
                controller: nameController,
                style: GoogleFonts.inter(color: _deepBrown),
                decoration: InputDecoration(
                  labelText: 'Nom de la catégorie',
                  labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.label_outline_rounded, color: _warmOrange),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
            ),
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDelete(category);
                },
                child: Text('Supprimer', style: GoogleFonts.inter(color: Colors.red)),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                  onTap: () async {
                    if (formKey.currentState!.validate()) {
                      final categoryData = {'name': nameController.text};
                      if (isEditing) {
                        await _menuService.updateCategory(category.id, categoryData);
                      } else {
                        await _menuService.addCategory(categoryData);
                      }
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'Enregistrer',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
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
          'Supprimer cette catégorie supprimera aussi tous les plats associés. Êtes-vous sûr ?',
          style: GoogleFonts.inter(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              await _menuService.deleteCategory(category.id);
              if (mounted) Navigator.pop(context);
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
}
