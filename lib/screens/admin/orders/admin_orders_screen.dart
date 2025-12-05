import 'package:flutter/material.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Toutes les commandes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'En cours'),
            Tab(text: 'Prêtes'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(OrderStatus.pending),
          _buildOrdersList(OrderStatus.inProgress),
          _buildOrdersList(OrderStatus.ready),
          _buildOrderHistory(),
        ],
      ),
    );
  }

  Widget _buildOrdersList(OrderStatus status) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersByStatus([status]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucune commande avec le statut ${status.name}'));
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
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune commande dans l\'historique'));
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
            ],
          ),
        ),
      ),
    );
  }
}
