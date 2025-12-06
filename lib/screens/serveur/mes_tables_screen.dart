import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/screens/serveur/nouvelle_commande_screen.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/services/table_service.dart';
import 'package:restaurantapp/widgets/serveur_drawer.dart';

class MesTablesScreen extends StatefulWidget {
  const MesTablesScreen({super.key});

  @override
  State<MesTablesScreen> createState() => _MesTablesScreenState();
}

enum PaymentMethod { cash, card, mobile }

class _MesTablesScreenState extends State<MesTablesScreen> {
  final TableService _tableService = TableService();
  final OrderService _orderService = OrderService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tables'),
      ),
      drawer: const ServeurDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (currentUser == null) {
      return Center(
        child: Text(
          "Utilisateur non connecté.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _tableService.getTablesForServer(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Affichage de l'erreur pour le débogage
          return Center(
            child: Text(
              "Une erreur est survenue: ${snapshot.error}",
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_restaurant_outlined, size: 64, color: AppColors.textTertiary),
                SizedBox(height: 16),
                Text(
                  "Aucune table ne vous est assignée.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final tables = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            // Ajustement du ratio pour des cartes plus hautes
            childAspectRatio: 1.25, // Smaller ratio -> taller cards
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

    final statusColor = isAvailable ? AppColors.success : AppColors.error;

    return Card(
      // Elevation handled by theme (0) or override here if needed
      elevation: 2,
      shadowColor: AppColors.textPrimary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _handleTableTap(tableDoc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.table_restaurant,
                      size: 24,
                      color: statusColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAvailable ? 'Libre' : 'Occupée',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Table ${tableData['number'] ?? 'N/A'}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${tableData['capacity']} places',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTableTap(DocumentSnapshot tableDoc) {
    final tableData = tableDoc.data() as Map<String, dynamic>;
    final bool isAvailable = tableData['isAvailable'] ?? true;

    if (isAvailable) {
      _showTableOptions(tableDoc);
    } else {
      _viewCurrentOrder(tableData['currentOrderId']);
    }
  }

  void _showTableOptions(DocumentSnapshot tableDoc) {
    final tableData = tableDoc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Table ${tableData['number']}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
              title: Text('Nouvelle commande', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _createOrderForTable(tableDoc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
              title: Text('Capacité: ${tableData['capacity']} personnes', style: TextStyle(color: AppColors.textSecondary)),
              enabled: false,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _createOrderForTable(DocumentSnapshot tableDoc) {
    final tableData = tableDoc.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NouvelleCommandeScreen(
          preselectedTableId: tableDoc.id,
          preselectedTableNumber: tableData['number'],
        ),
      ),
    );
  }

  void _viewCurrentOrder(String? orderId) {
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune commande trouvée pour cette table')),
      );
      return;
    }

    // Afficher les détails de la commande dans un BottomSheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<OrderModel?>(
        stream: _orderService.getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Container(
              height: 200,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(child: Text('Commande non trouvée')),
            );
          }

          final order = snapshot.data!;
          return _buildOrderDetailsSheet(order);
        },
      ),
    );
  }

  Widget _buildOrderDetailsSheet(OrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        order.type == OrderType.dineIn ? Icons.restaurant : Icons.takeout_dining,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.type == OrderType.dineIn
                              ? 'Table ${order.tableNumber ?? "N/A"}'
                              : 'À emporter',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDateTime(order.createdAt),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),

            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_outlined, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(order.notes!, style: TextStyle(color: AppColors.textPrimary))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: order.items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.surfaceVariant,
                            image: item.imageUrl != null
                                ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: item.imageUrl == null
                              ? const Icon(Icons.restaurant, color: AppColors.textTertiary)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              Text(
                                '${item.price.toStringAsFixed(2)} DH x ${item.quantity}',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.totalPrice.toStringAsFixed(2)} DH',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} DH',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Boutons d'action selon le statut
            if (order.status == OrderStatus.ready)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _orderService.updateOrderStatus(order.id, OrderStatus.served);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Marquer comme servi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            if (order.status == OrderStatus.served)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                     Navigator.pop(context);
                    _showPaymentDialog(order);
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Encaisser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(OrderModel order) {
    PaymentMethod selectedMethod = PaymentMethod.cash;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Titre
              const Text(
                '💳 Encaisser la commande',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                order.type == OrderType.dineIn
                    ? 'Table ${order.tableNumber}'
                    : 'À emporter',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              // Montant total
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total à payer',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${order.totalAmount.toStringAsFixed(2)} DH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Mode de paiement
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mode de paiement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              // Options de paiement
              Row(
                children: [
                  _buildPaymentOption(
                    icon: Icons.money,
                    label: 'Espèces',
                    method: PaymentMethod.cash,
                    selectedMethod: selectedMethod,
                    onTap: () => setSheetState(() => selectedMethod = PaymentMethod.cash),
                  ),
                  const SizedBox(width: 12),
                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    label: 'Carte',
                    method: PaymentMethod.card,
                    selectedMethod: selectedMethod,
                    onTap: () => setSheetState(() => selectedMethod = PaymentMethod.card),
                  ),
                  const SizedBox(width: 12),
                  _buildPaymentOption(
                    icon: Icons.phone_android,
                    label: 'Mobile',
                    method: PaymentMethod.mobile,
                    selectedMethod: selectedMethod,
                    onTap: () => setSheetState(() => selectedMethod = PaymentMethod.mobile),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Bouton confirmer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _processPayment(order, selectedMethod);
                  },
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text(
                    'Confirmer le paiement',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Bouton annuler
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required PaymentMethod method,
    required PaymentMethod selectedMethod,
    required VoidCallback onTap,
  }) {
    final bool isSelected = method == selectedMethod;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey[100],
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: isSelected ? Colors.green : Colors.grey[700]),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(OrderModel order, PaymentMethod method) async {
    try {
      await _orderService.updateOrderStatus(order.id, OrderStatus.paid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement enregistré!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.inProgress:
        return AppColors.info;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.served:
        return AppColors.adminAccent;
      case OrderStatus.paid:
        return AppColors.textSecondary;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
