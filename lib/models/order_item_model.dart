class OrderItemModel {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? notes;
  final String? imageUrl;

  OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
    this.imageUrl,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
      'imageUrl': imageUrl,
    };
  }

  double get totalPrice => price * quantity;

  OrderItemModel copyWith({
    String? menuItemId,
    String? name,
    double? price,
    int? quantity,
    String? notes,
    String? imageUrl,
  }) {
    return OrderItemModel(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

