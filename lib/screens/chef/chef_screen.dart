import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';
import 'package:restaurantapp/core/widgets/empty_state.dart';
import 'package:restaurantapp/core/widgets/status_badge.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/services/order_service.dart';

class ChefScreen extends StatefulWidget {
  const ChefScreen({super.key});

  @override
  State<ChefScreen> createState() => _ChefScreenState();
}

class _ChefScreenState extends State<ChefScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom Tab Bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.primary, // Changed to primary
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
            tabs: [
              _buildTab('En attente', Icons.schedule_rounded),
              _buildTab('En cours', Icons.restaurant_rounded),
              _buildTab('Terminées', Icons.check_circle_rounded),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList([OrderStatus.pending]),
              _buildOrderList([OrderStatus.inProgress]),
              _buildOrderList([OrderStatus.ready, OrderStatus.served, OrderStatus.paid]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, IconData icon) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderStatus> statuses) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersByStatus(statuses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Erreur: ${snapshot.error}", style: TextStyle(color: AppColors.error)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.restaurant_menu_rounded,
            title: 'Aucune commande',
            subtitle: _getEmptyMessage(statuses),
            iconColor: AppColors.primary,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildOrderCard(snapshot.data![index]),
        );
      },
    );
  }

  String _getEmptyMessage(List<OrderStatus> statuses) {
    if (statuses.contains(OrderStatus.pending)) return 'Les nouvelles commandes apparaîtront ici';
    if (statuses.contains(OrderStatus.inProgress)) return 'Aucune commande en préparation';
    return 'Les commandes terminées apparaîtront ici';
  }

  Widget _buildOrderCard(OrderModel order) {
    final bool isNew = order.status == OrderStatus.pending;
    final bool isInProgress = order.status == OrderStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isNew
            ? Border.all(color: AppColors.primary, width: 2) // Warning -> Primary for stronger emphasis in warm theme? Or Keep warning? Let's use Primary (Orange) for new
            : isInProgress
                ? Border.all(color: AppColors.secondary.withOpacity(0.3), width: 1)
                : null,
        boxShadow: [
          BoxShadow(
            color: isNew
                ? AppColors.primary.withOpacity(0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isNew ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(order, isNew),
                const SizedBox(height: 12),
                _buildOrderItems(order),
                if (order.notes != null && order.notes!.isNotEmpty) _buildNotesSection(order),
                const SizedBox(height: 12),
                _buildActionButtons(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order, bool isNew) {
    return Row(
      children: [
        // Order type icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            order.type == OrderType.dineIn ? Icons.restaurant_rounded : Icons.takeout_dining_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Order info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.type == OrderType.dineIn ? 'Table ${order.tableNumber ?? "N/A"}' : 'À emporter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    StatusBadge.pending(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(order.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Items count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${order.items.length} plat${order.items.length > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: order.items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildNotesSection(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sticky_note_2_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              order.notes!,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.warning, // Fixed text color visibility
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    if (order.status == OrderStatus.pending) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(order, OrderStatus.inProgress),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Commencer la préparation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // Info -> Primary (Orange is action color)
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(order, OrderStatus.ready),
          icon: const Icon(Icons.check_circle_rounded, size: 20),
          label: const Text('Marquer comme prête'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      if (mounted) {
        String message = newStatus == OrderStatus.inProgress
            ? 'Préparation commencée!'
            : 'Commande prête!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == OrderStatus.inProgress ? Icons.restaurant_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(message),
              ],
            ),
            backgroundColor: newStatus == OrderStatus.inProgress ? AppColors.primary : AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      order.type == OrderType.dineIn ? Icons.restaurant_rounded : Icons.takeout_dining_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.type == OrderType.dineIn ? 'Table ${order.tableNumber ?? "N/A"}' : 'À emporter',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Serveur: ${order.serverName}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
            ),
            // Info bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(Icons.access_time_rounded, _formatTime(order.createdAt)),
                  Container(width: 1, height: 24, color: AppColors.border),
                  _buildInfoItem(Icons.restaurant_menu_rounded, '${order.items.length} plat(s)'),
                  Container(width: 1, height: 24, color: AppColors.border),
                  _buildInfoItem(Icons.euro_rounded, '${order.totalAmount.toStringAsFixed(2)} €'),
                ],
              ),
            ),
            // Notes
            if (order.notes != null && order.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildNotesSection(order),
              ),
            const SizedBox(height: 16),
            // Items list header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Plats à préparer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.sticky_note_2_rounded, size: 14, color: AppColors.warning),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.notes!,
                                          style: const TextStyle(fontSize: 12, color: AppColors.warning),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildDetailActionButton(order),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return StatusBadge.pending();
      case OrderStatus.inProgress:
        return StatusBadge.inProgress();
      case OrderStatus.ready:
        return StatusBadge.ready();
      case OrderStatus.served:
        return StatusBadge.served();
      case OrderStatus.paid:
        return StatusBadge.paid();
      case OrderStatus.cancelled:
        return StatusBadge.cancelled();
    }
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDetailActionButton(OrderModel order) {
    if (order.status == OrderStatus.pending) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () async {
            await _updateOrderStatus(order, OrderStatus.inProgress);
            if (mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Commencer la préparation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // Info -> Primary
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () async {
            await _updateOrderStatus(order, OrderStatus.ready);
            if (mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Confirmer la fin de préparation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            'Commande ${order.statusLabel}',
            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
