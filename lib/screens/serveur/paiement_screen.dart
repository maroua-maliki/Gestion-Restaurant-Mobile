import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/widgets/serveur_drawer.dart';

class PaiementScreen extends StatefulWidget {
  const PaiementScreen({super.key});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  final OrderService _orderService = OrderService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        centerTitle: true,
      ),
      drawer: const ServeurDrawer(),
      body: currentUser == null
          ? const Center(child: Text('Utilisateur non connecté'))
          : StreamBuilder<List<OrderModel>>(
              stream: _orderService.getOrdersReadyForPayment(currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => _buildOrderCard(snapshot.data![index]),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune commande à encaisser',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Les commandes servies apparaîtront ici',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showPaymentDialog(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: order.type == OrderType.dineIn
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          order.type == OrderType.dineIn ? Icons.restaurant : Icons.takeout_dining,
                          color: order.type == OrderType.dineIn ? Colors.blue : Colors.orange,
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
                            '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Servie',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Liste des articles (aperçu)
              ...order.items.take(3).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.quantity}x ${item.name}'),
                    Text('${item.totalPrice.toStringAsFixed(2)} DH'),
                  ],
                ),
              )),
              if (order.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... et ${order.items.length - 3} autre(s)',
                    style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                ),
              const Divider(height: 24),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total à payer', style: TextStyle(fontSize: 16)),
                  Text(
                    '${order.totalAmount.toStringAsFixed(2)} DH',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
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
    final isSelected = method == selectedMethod;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.green : Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.green : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(OrderModel order, PaymentMethod method) async {
    try {
      await _orderService.processPayment(order.id, method);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paiement de ${order.totalAmount.toStringAsFixed(2)} DH enregistré (${_getMethodLabel(method)})',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.mobile:
        return 'Mobile';
    }
  }
}
