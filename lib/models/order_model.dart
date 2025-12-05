import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurantapp/models/order_item_model.dart';

enum OrderStatus {
  pending,      // En attente
  inProgress,   // En préparation
  ready,        // Prête
  served,       // Servie
  paid,         // Payée
  cancelled     // Annulée
}

enum OrderType {
  dineIn,       // Sur place (à table)
  takeaway      // À emporter
}

enum PaymentMethod {
  cash,         // Espèces
  card,         // Carte bancaire
  mobile,       // Paiement mobile
}

class OrderModel {
  final String id;
  final String? tableId;
  final String? tableNumber;
  final String serverId;
  final String serverName;
  final List<OrderItemModel> items;
  final OrderStatus status;
  final OrderType type;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? preparationDate;
  final DateTime? serviceDate;
  final DateTime? paidAt;
  final String? notes;
  final PaymentMethod? paymentMethod;

  OrderModel({
    required this.id,
    this.tableId,
    this.tableNumber,
    required this.serverId,
    required this.serverName,
    required this.items,
    required this.status,
    required this.type,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
    this.preparationDate,
    this.serviceDate,
    this.paidAt,
    this.notes,
    this.paymentMethod,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<OrderItemModel> items = [];
    if (data['items'] != null) {
      items = (data['items'] as List)
          .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: doc.id,
      tableId: data['tableId'],
      tableNumber: data['tableNumber'],
      serverId: data['serverId'] ?? '',
      serverName: data['serverName'] ?? 'Inconnu',
      items: items,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      type: OrderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => OrderType.dineIn,
      ),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      preparationDate: (data['preparationDate'] as Timestamp?)?.toDate(),
      serviceDate: (data['serviceDate'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      paymentMethod: data['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == data['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'tableNumber': tableNumber,
      'serverId': serverId,
      'serverName': serverName,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.name,
      'type': type.name,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'preparationDate': preparationDate != null ? Timestamp.fromDate(preparationDate!) : null,
      'serviceDate': serviceDate != null ? Timestamp.fromDate(serviceDate!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'notes': notes,
      'paymentMethod': paymentMethod?.name,
    };
  }

  OrderModel copyWith({
    String? id,
    String? tableId,
    String? tableNumber,
    String? serverId,
    String? serverName,
    List<OrderItemModel>? items,
    OrderStatus? status,
    OrderType? type,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? preparationDate,
    DateTime? serviceDate,
    DateTime? paidAt,
    String? notes,
    PaymentMethod? paymentMethod,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      items: items ?? this.items,
      status: status ?? this.status,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preparationDate: preparationDate ?? this.preparationDate,
      serviceDate: serviceDate ?? this.serviceDate,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.inProgress:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.served:
        return 'Servie';
      case OrderStatus.paid:
        return 'Payée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  String get typeLabel {
    switch (type) {
      case OrderType.dineIn:
        return 'Sur place';
      case OrderType.takeaway:
        return 'À emporter';
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.card:
        return 'Carte bancaire';
      case PaymentMethod.mobile:
        return 'Paiement mobile';
      case null:
        return 'Non payé';
    }
  }
}
