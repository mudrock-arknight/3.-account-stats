// lib/models/order_item.dart
class OrderItem {
  final String? id;
  final String productId;
  final String productName;
  final String productUnit;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.productUnit,
    required this.quantity,
    required this.unitPrice,
    this.subtotal = 0,
  });

  double get calculatedSubtotal => quantity * unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String?,
      productId: json['product_id'] as String,
      productName: (json['product_name'] as String?) ?? '',
      productUnit: (json['product_unit'] as String?) ?? '包',
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}