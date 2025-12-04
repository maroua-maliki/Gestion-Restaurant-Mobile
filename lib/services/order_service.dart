import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/models/order_item_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _ordersRef => _firestore.collection('orders');

  // --- CRÉER UNE COMMANDE ---
  Future<String> createOrder({
    required String? tableId,
    required String? tableNumber,
    required String serverId,
    required String serverName,
    required List<OrderItemModel> items,
    required OrderType type,
    String? notes,
  }) async {
    final double totalAmount = items.fold(0, (sum, item) => sum + item.totalPrice);
    
    final docRef = await _ordersRef.add({
      'tableId': tableId,
      'tableNumber': tableNumber,
      'serverId': serverId,
      'serverName': serverName,
      'items': items.map((item) => item.toMap()).toList(),
      'status': OrderStatus.pending.name,
      'type': type.name,
      'totalAmount': totalAmount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
      'notes': notes,
    });

    // Marquer la table comme occupée si c'est une commande sur place
    if (type == OrderType.dineIn && tableId != null) {
      await _firestore.collection('tables').doc(tableId).update({
        'isAvailable': false,
        'currentOrderId': docRef.id,
      });
    }

    return docRef.id;
  }

  // --- RÉCUPÉRER TOUTES LES COMMANDES (temps réel) ---
  Stream<List<OrderModel>> getAllOrders() {
    return _ordersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // --- RÉCUPÉRER LES COMMANDES PAR STATUT (pour le chef) ---
  Stream<List<OrderModel>> getOrdersByStatus(List<OrderStatus> statuses) {
    return _ordersRef
        .where('status', whereIn: statuses.map((s) => s.name).toList())
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          // Tri côté client pour éviter l'index composite
          orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return orders;
        });
  }

  // --- RÉCUPÉRER LES COMMANDES D'UN SERVEUR ---
  Stream<List<OrderModel>> getOrdersForServer(String serverId) {
    return _ordersRef
        .where('serverId', isEqualTo: serverId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          // Tri côté client pour éviter l'index composite
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  // --- RÉCUPÉRER LES COMMANDES ACTIVES D'UN SERVEUR (non payées/annulées) ---
  Stream<List<OrderModel>> getActiveOrdersForServer(String serverId) {
    // Requête simplifiée pour éviter l'index composite
    // Le filtrage des statuts est fait côté client
    // Suppression de orderBy dans la requête pour éviter l'erreur d'index
    return _ordersRef
        .where('serverId', isEqualTo: serverId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .where((order) =>
                  order.status != OrderStatus.paid &&
                  order.status != OrderStatus.cancelled)
              .toList();
          // Tri côté client
          orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return orders;
        });
  }

  // --- RÉCUPÉRER UNE COMMANDE PAR ID ---
  Stream<OrderModel?> getOrderById(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // --- METTRE À JOUR LE STATUT D'UNE COMMANDE ---
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _ordersRef.doc(orderId).update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Si la commande est payée, libérer la table
    if (newStatus == OrderStatus.paid) {
      final orderDoc = await _ordersRef.doc(orderId).get();
      final data = orderDoc.data() as Map<String, dynamic>?;
      if (data != null && data['tableId'] != null) {
        await _firestore.collection('tables').doc(data['tableId']).update({
          'isAvailable': true,
          'currentOrderId': null,
        });
      }
    }
  }

  // --- EFFECTUER UN PAIEMENT ---
  Future<void> processPayment(String orderId, PaymentMethod paymentMethod) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.paid.name,
      'paymentMethod': paymentMethod.name,
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Libérer la table si c'est une commande sur place
    final orderDoc = await _ordersRef.doc(orderId).get();
    final data = orderDoc.data() as Map<String, dynamic>?;
    if (data != null && data['tableId'] != null) {
      await _firestore.collection('tables').doc(data['tableId']).update({
        'isAvailable': true,
        'currentOrderId': null,
      });
    }
  }

  // --- RÉCUPÉRER LES COMMANDES À PAYER (servies mais non payées) ---
  Stream<List<OrderModel>> getOrdersReadyForPayment(String serverId) {
    return _ordersRef
        .where('serverId', isEqualTo: serverId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .where((order) => order.status == OrderStatus.served)
              .toList();
          orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return orders;
        });
  }

  // --- AJOUTER DES ITEMS À UNE COMMANDE EXISTANTE ---
  Future<void> addItemsToOrder(String orderId, List<OrderItemModel> newItems) async {
    final orderDoc = await _ordersRef.doc(orderId).get();
    final data = orderDoc.data() as Map<String, dynamic>;
    
    List<Map<String, dynamic>> existingItems = 
        List<Map<String, dynamic>>.from(data['items'] ?? []);
    existingItems.addAll(newItems.map((item) => item.toMap()));

    final double newTotal = existingItems.fold(0.0, 
        (sum, item) => sum + (item['price'] * item['quantity']));

    await _ordersRef.doc(orderId).update({
      'items': existingItems,
      'totalAmount': newTotal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- SUPPRIMER UNE COMMANDE ---
  Future<void> deleteOrder(String orderId) async {
    final orderDoc = await _ordersRef.doc(orderId).get();
    final data = orderDoc.data() as Map<String, dynamic>?;
    
    // Libérer la table si nécessaire
    if (data != null && data['tableId'] != null) {
      await _firestore.collection('tables').doc(data['tableId']).update({
        'isAvailable': true,
        'currentOrderId': null,
      });
    }
    
    await _ordersRef.doc(orderId).delete();
  }
}
