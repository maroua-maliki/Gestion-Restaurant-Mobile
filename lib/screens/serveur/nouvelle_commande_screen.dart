import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';
import 'package:restaurantapp/models/order_item_model.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/services/menu_service.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/services/table_service.dart';
import 'package:restaurantapp/widgets/serveur_drawer.dart';

// Enum pour gérer les étapes du flux
enum OrderStep { selectType, selectTable, selectItems }

// Theme colors (same as admin)
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

class NouvelleCommandeScreen extends StatefulWidget {
  final String? preselectedTableId;
  final String? preselectedTableNumber;

  const NouvelleCommandeScreen({
    super.key,
    this.preselectedTableId,
    this.preselectedTableNumber,
  });

  @override
  State<NouvelleCommandeScreen> createState() => _NouvelleCommandeScreenState();
}

class _NouvelleCommandeScreenState extends State<NouvelleCommandeScreen> {
  final MenuService _menuService = MenuService();
  final OrderService _orderService = OrderService();
  final TableService _tableService = TableService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // État du flux
  OrderStep _currentStep = OrderStep.selectType;
  OrderType? _orderType;
  String? _selectedTableId;
  String? _selectedTableNumber;
  String? _selectedCategoryId;
  final List<OrderItemModel> _cartItems = [];
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si une table est présélectionnée, aller directement aux items
    if (widget.preselectedTableId != null) {
      _selectedTableId = widget.preselectedTableId;
      _selectedTableNumber = widget.preselectedTableNumber;
      _orderType = OrderType.dineIn;
      _currentStep = OrderStep.selectItems;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  String get _appBarTitle {
    switch (_currentStep) {
      case OrderStep.selectType:
        return 'Nouvelle Commande';
      case OrderStep.selectTable:
        return 'Sélectionner une table';
      case OrderStep.selectItems:
        return _orderType == OrderType.takeaway
            ? 'Commande à emporter'
            : 'Table ${_selectedTableNumber ?? ""}';
    }
  }

  void _goBack() {
    setState(() {
      switch (_currentStep) {
        case OrderStep.selectType:
          break;
        case OrderStep.selectTable:
          _currentStep = OrderStep.selectType;
          _orderType = null;
          break;
        case OrderStep.selectItems:
          if (widget.preselectedTableId != null) {
            Navigator.pop(context);
            return;
          }
          if (_orderType == OrderType.takeaway) {
            _currentStep = OrderStep.selectType;
            _orderType = null;
          } else {
            _currentStep = OrderStep.selectTable;
            _selectedTableId = null;
            _selectedTableNumber = null;
          }
          _cartItems.clear();
          break;
      }
    });
  }

  void _selectOrderType(OrderType type) {
    setState(() {
      _orderType = type;
      if (type == OrderType.takeaway) {
        _currentStep = OrderStep.selectItems;
      } else {
        _currentStep = OrderStep.selectTable;
      }
    });
  }

  void _selectTable(String tableId, String tableNumber) {
    setState(() {
      _selectedTableId = tableId;
      _selectedTableNumber = tableNumber;
      _currentStep = OrderStep.selectItems;
    });
  }

  void _addToCart(Map<String, dynamic> menuItem, String menuItemId) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.menuItemId == menuItemId);
      if (existingIndex != -1) {
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
          quantity: _cartItems[existingIndex].quantity + 1,
        );
      } else {
        _cartItems.add(OrderItemModel(
          menuItemId: menuItemId,
          name: menuItem['name'] ?? '',
          price: (menuItem['price'] ?? 0).toDouble(),
          quantity: 1,
          imageUrl: menuItem['imageUrl'],
        ));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index] = _cartItems[index].copyWith(
          quantity: _cartItems[index].quantity - 1,
        );
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un article')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _orderService.createOrder(
        tableId: _orderType == OrderType.dineIn ? _selectedTableId : null,
        tableNumber: _orderType == OrderType.dineIn ? _selectedTableNumber : null,
        serverId: currentUser!.uid,
        serverName: currentUser!.displayName ?? 'Serveur',
        items: _cartItems,
        type: _orderType!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande créée avec succès!'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = _currentStep == OrderStep.selectType;

    return Scaffold(
      backgroundColor: _cream,
      drawer: isFirstStep ? const ServeurDrawer() : null,
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: _cream,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _deepBrown,
        foregroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        leading: isFirstStep
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: _warmOrange),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _warmOrange),
                onPressed: _goBack,
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case OrderStep.selectType:
        return _buildOrderTypeSelection();
      case OrderStep.selectTable:
        return _buildTableSelection();
      case OrderStep.selectItems:
        return _buildItemsSelection();
    }
  }

  // ========== STEP 1: Select Order Type ==========
  Widget _buildOrderTypeSelection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Type de Commande',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _deepBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par choisir une option',
              style: GoogleFonts.inter(fontSize: 16, color: _deepBrown.withOpacity(0.7)),
            ),
            const SizedBox(height: 40),
            _buildOrderTypeCard(
              icon: Icons.restaurant,
              title: 'Sur place',
              subtitle: 'Commande pour une table',
              color: _warmOrange,
              onTap: () => _selectOrderType(OrderType.dineIn),
            ),
            const SizedBox(height: 20),
            _buildOrderTypeCard(
              icon: Icons.takeout_dining,
              title: 'À emporter',
              subtitle: 'Préparer pour emporter',
              color: _deepBrown,
              onTap: () => _selectOrderType(OrderType.takeaway),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 14, color: _deepBrown.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }

  // ========== STEP 2: Select Table ==========
  Widget _buildTableSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _tableService.getTablesForServer(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _warmOrange));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Une erreur est survenue: ${snapshot.error}", style: GoogleFonts.inter(color: _deepBrown)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Aucune table ne vous est assignée.", style: GoogleFonts.inter(color: _deepBrown)));
        }
        final tables = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return _buildTableCard(table);
          },
        );
      },
    );
  }

  Widget _buildTableCard(DocumentSnapshot tableDoc) {
    final tableData = tableDoc.data() as Map<String, dynamic>;
    final bool isAvailable = tableData['isAvailable'] ?? true;

    return Card(
      elevation: 0,
      color: _cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isAvailable ? _warmOrange : AppColors.error.withOpacity(0.5), width: 1.5),
      ),
      child: InkWell(
        onTap: isAvailable ? () => _selectTable(tableDoc.id, tableData['number']?.toString() ?? '') : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 36,
                    color: isAvailable ? _warmOrange : AppColors.error,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAvailable ? 'Libre' : 'Occupée',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: isAvailable ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Table ${tableData['number'] ?? 'N/A'}',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: _deepBrown),
              ),
              Text('${tableData['capacity']} places', style: GoogleFonts.inter(color: _deepBrown.withOpacity(0.7), fontSize: 12)),
              const Spacer(),
              if (isAvailable)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectTable(tableDoc.id, tableData['number']?.toString() ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _warmOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('Sélectionner', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== STEP 3: Select Items ==========
  Widget _buildItemsSelection() {
    return Stack(
      children: [
        Column(
          children: [
            _buildFilterChips(),
            Expanded(child: _buildPlatsView()),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: _buildCartFloatingButton(),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return StreamBuilder<QuerySnapshot>(
      stream: _menuService.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 70);
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
                color: _deepBrown.withOpacity(0.05),
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
            color: isSelected ? Colors.transparent : _gold.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _warmOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
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
              return Center(child: Text("Aucun plat à afficher."));
            }

            final items = itemSnapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isAvailable'] == true;
            }).toList();

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
                slivers: [
                  ...sortedCategoryIds.expand((categoryId) => [
                        SliverToBoxAdapter(
                          child: _buildCategoryHeader(
                              categoriesMap[categoryId]?['name'] ?? 'Inconnue'),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75, 
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildMenuItemCard(groupedItems[categoryId]![index]),
                              childCount: groupedItems[categoryId]!.length,
                            ),
                          ),
                        ),
                      ]),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 120), // Padding for the floating button
                  ),
                ],
              );
            } else {
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, 
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildMenuItemCard(items[index]),
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

Widget _buildMenuItemCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'];
    final quantity = _cartItems.where((cartItem) => cartItem.menuItemId == doc.id).fold(0, (sum, item) => sum + item.quantity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _deepBrown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addToCart(data, doc.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (imageUrl != null && imageUrl.isNotEmpty)
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
                            child: Icon(Icons.restaurant_rounded, size: 40, color: _gold.withOpacity(0.5)),
                          ),
                    if (quantity > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Badge(
                          label: Text('$quantity'),
                          backgroundColor: _warmOrange,
                          textColor: Colors.white,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data['name'] ?? '',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _deepBrown,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['price']} DH',
                        style: GoogleFonts.inter(
                          color: _warmOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
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

  Widget _buildCartFloatingButton() {
    final itemCount = _cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    if (itemCount == 0) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _showCartBottomSheet,
      backgroundColor: _warmOrange,
      icon: Badge(
        label: Text('$itemCount'),
        isLabelVisible: true,
        backgroundColor: _deepBrown,
        textColor: Colors.white,
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      label: Text(
        'Voir Panier • ${_totalAmount.toStringAsFixed(2)} DH',
        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return _buildCartBottomSheetContent(scrollController, setSheetState);
            },
          );
        },
      ),
    );
  }

  Widget _buildCartBottomSheetContent(ScrollController scrollController, StateSetter setSheetState) {
    return Container(
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _deepBrown.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, size: 28, color: _deepBrown),
                const SizedBox(width: 12),
                Text(
                  'Panier (${_cartItems.length} articles)',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: _deepBrown),
                ),
                const Spacer(),
                if (_cartItems.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _cartItems.clear());
                      setSheetState(() {});
                    },
                    child: Text('Vider', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const Divider(color: _deepBrown, indent: 16, endIndent: 16, thickness: 0.2),
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_basket_outlined, size: 64, color: _deepBrown),
                        const SizedBox(height: 16),
                        Text('Votre panier est vide', style: GoogleFonts.inter(color: _deepBrown, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) => _buildCartItemSheet(index, setSheetState),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes pour la cuisine (optionnel)',
                    labelStyle: GoogleFonts.inter(color: _deepBrown),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _warmOrange)),
                  ),
                  style: GoogleFonts.inter(color: _deepBrown),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitOrder,
                    icon: _isLoading
                        ? Container(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isLoading ? 'Envoi...' : 'Envoyer la commande', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _warmOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemSheet(int index, StateSetter setSheetState) {
    final item = _cartItems[index];
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(item.imageUrl ?? '', width: 50, height: 50, fit: BoxFit.cover),
      ),
      title: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _deepBrown)),
      subtitle: Text('${item.price.toStringAsFixed(2)} DH', style: GoogleFonts.inter(color: _deepBrown.withOpacity(0.7))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: _deepBrown),
            onPressed: () {
              setState(() => _removeFromCart(index));
              setSheetState(() {});
            },
          ),
          Text('${item.quantity}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _deepBrown)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: _warmOrange),
            onPressed: () {
              setState(() => _addToCart({'name': item.name, 'price': item.price, 'imageUrl': item.imageUrl}, item.menuItemId));
              setSheetState(() {});
            },
          ),
        ],
      ),
    );
  }
}
