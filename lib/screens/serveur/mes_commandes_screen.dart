import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/widgets/serveur_drawer.dart';

class MesCommandesScreen extends StatefulWidget {
  const MesCommandesScreen({super.key});

  @override
  State<MesCommandesScreen> createState() => _MesCommandesScreenState();
}

enum PaymentMethod { cash, card, mobile }

class _MesCommandesScreenState extends State<MesCommandesScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En cours', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Historique', icon: Icon(Icons.history)),
          ],
        ),
      ),
      drawer: const ServeurDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrdersList(),
          _buildOrderHistory(),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList() {
    if (currentUser == null) {
      return const Center(child: Text('Utilisateur non connecté'));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getActiveOrdersForServer(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune commande en cours'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildOrderCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildOrderHistory() {
    if (currentUser == null) {
      return const Center(child: Text('Utilisateur non connecté'));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersForServer(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune commande'));
        }

        final completedOrders = snapshot.data!
            .where((o) => o.status == OrderStatus.paid || o.status == OrderStatus.cancelled)
            .toList();

        if (completedOrders.isEmpty) {
          return const Center(child: Text('Aucune commande dans l\'historique'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: completedOrders.length,
          itemBuilder: (context, index) => _buildOrderCard(completedOrders[index]),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final colorScheme = Theme.of(context).colorScheme;
    Color statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(order.type == OrderType.dineIn ? Icons.restaurant : Icons.takeout_dining,
                          color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        order.type == OrderType.dineIn 
                            ? 'Table ${order.tableNumber ?? "N/A"}'
                            : 'À emporter',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(order.statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(),
              Text('${order.items.length} article(s) • ${order.totalAmount.toStringAsFixed(2)} DH',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(order.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (order.status == OrderStatus.ready) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsServed(order),
                    icon: const Icon(Icons.check),
                    label: const Text('Marquer comme servie'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _cancelOrder(order),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler la commande'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.served:
        return Colors.purple;
      case OrderStatus.paid:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markAsServed(OrderModel order) async {
    try {
      await _orderService.updateOrderStatus(order.id, OrderStatus.served);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande marquée comme servie'), backgroundColor: Colors.green),
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

  Future<void> _cancelOrder(OrderModel order) async {
    try {
      await _orderService.updateOrderStatus(order.id, OrderStatus.cancelled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande annulée'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'annulation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.type == OrderType.dineIn
                        ? 'Table ${order.tableNumber ?? "N/A"}'
                        : 'À emporter',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(order.statusLabel, style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Commandé le ${_formatDateTime(order.createdAt)}', style: TextStyle(color: Colors.grey[600])),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes: ${order.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              const Divider(height: 24),
              const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return ListTile(
                      leading: item.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.restaurant),
                      title: Text(item.name),
                      subtitle: Text('${item.price.toStringAsFixed(2)} DH x ${item.quantity}'),
                      trailing: Text('${item.totalPrice.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${order.totalAmount.toStringAsFixed(2)} DH',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 16),
              if (order.status == OrderStatus.served)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showPaymentDialog(order);
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Procéder au paiement'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
              if (order.status == OrderStatus.pending)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _cancelOrder(order);
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler la Commande'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
            ],
          ),
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
}
