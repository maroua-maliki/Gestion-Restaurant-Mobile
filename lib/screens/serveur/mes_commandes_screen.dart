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
                      color: statusColor.withValues(alpha: 0.2),
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
                      color: _getStatusColor(order.status).withValues(alpha: 0.2),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total à payer: ${order.totalAmount.toStringAsFixed(2)} DH',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Méthode de paiement:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Espèces'), selected: true, onSelected: (_) {}),
                ChoiceChip(label: const Text('Carte'), selected: false, onSelected: (_) {}),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _orderService.updateOrderStatus(order.id, OrderStatus.paid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paiement enregistré! Table libérée.'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

