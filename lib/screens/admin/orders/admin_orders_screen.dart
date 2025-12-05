import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

// Theme colors from the server screen
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

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
      backgroundColor: _cream, // Apply background color
      appBar: AppBar(
        title: Text(
          'Suivi des Commandes',
          style: GoogleFonts.playfairDisplay( // Style title
            fontWeight: FontWeight.bold,
            color: _cream,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _deepBrown, // Style AppBar
        foregroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: _warmOrange),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _warmOrange,
          labelColor: _warmOrange,
          unselectedLabelColor: _cream.withOpacity(0.7),
          tabs: const [
            Tab(text: 'En cours', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Historique', icon: Icon(Icons.history)),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(isActive: true),
          _buildOrdersList(isActive: false),
        ],
      ),
    );
  }

  Widget _buildOrdersList({required bool isActive}) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _warmOrange));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(
            'Aucune commande à afficher',
            style: GoogleFonts.inter(color: _deepBrown, fontSize: 16)
          ));
        }

        final orders = isActive
            ? snapshot.data!.where((o) => o.status != OrderStatus.paid && o.status != OrderStatus.cancelled).toList()
            : snapshot.data!.where((o) => o.status == OrderStatus.paid || o.status == OrderStatus.cancelled).toList();

        if (orders.isEmpty) {
          return Center(child: Text(
            isActive ? 'Aucune commande en cours' : "Aucune commande dans l'historique",
            style: GoogleFonts.inter(color: _deepBrown, fontSize: 16)
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: orders.length,
          itemBuilder: (context, index) => _buildOrderCard(orders[index]),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final colorScheme = Theme.of(context).colorScheme;
    Color statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
                'Serveur: ${order.serverName}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
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
        return _deepBrown.withOpacity(0.7);
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
      backgroundColor: Colors.transparent, // Make it transparent
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _deepBrown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.type == OrderType.dineIn
                              ? 'Table ${order.tableNumber ?? "N/A"}'
                              : 'À emporter',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 22, fontWeight: FontWeight.bold, color: _deepBrown),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(order.statusLabel,
                              style: GoogleFonts.inter(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Serveur: ${order.serverName}',
                        style: GoogleFonts.inter(color: _deepBrown, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Commandé le: ${_formatDateTime(order.createdAt)}',
                        style: GoogleFonts.inter(color: Colors.grey[600])),
                    if (order.preparationDate != null) ...[
                      const SizedBox(height: 4),
                      Text('Préparé le: ${_formatDateTime(order.preparationDate!)}',
                          style: GoogleFonts.inter(color: Colors.grey[600])),
                    ],
                    if (order.serviceDate != null) ...[
                      const SizedBox(height: 4),
                      Text('Servi le: ${_formatDateTime(order.serviceDate!)}',
                          style: GoogleFonts.inter(color: Colors.grey[600])),
                    ],
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Notes: ${order.notes}',
                          style: GoogleFonts.inter(fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
              const Divider(height: 24, thickness: 0.2, color: _gold),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Articles:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: _deepBrown)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return ListTile(
                      leading: item.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(item.imageUrl!,
                                  width: 50, height: 50, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.restaurant, color: _gold),
                      title: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _deepBrown)),
                      subtitle: Text(
                          '${item.price.toStringAsFixed(2)} DH x ${item.quantity}', style: GoogleFonts.inter(color: _deepBrown.withOpacity(0.8))),
                      trailing: Text('${item.totalPrice.toStringAsFixed(2)} DH',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _deepBrown)),
                    );
                  },
                ),
              ),
              const Divider(thickness: 0.2, color: _gold),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:',
                        style:
                            GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _deepBrown)),
                    Text('${order.totalAmount.toStringAsFixed(2)} DH',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 22, fontWeight: FontWeight.bold, color: _warmOrange)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
