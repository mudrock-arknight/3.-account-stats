import 'dart:convert';
import 'order_item.dart';

enum OrderStatus { pending, claimed, delivered, completed }

class Order {
  final String? id;
  final String customerId;
  final String customerName;
  final String createdBy;
  final String createdByName;
  final String? claimedBy;
  final String? claimedByName;
  final double? customerLatitude;
  final double? customerLongitude;
  final String customerAddress;
  final OrderStatus status;
  final DateTime? deliveryDeadline;
  final double totalAmount;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;
  final List<OrderItem> items;

  const Order({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.createdBy,
    required this.createdByName,
    this.claimedBy,
    this.claimedByName,
    this.customerLatitude,
    this.customerLongitude,
    this.customerAddress = '',
    required this.status,
    this.deliveryDeadline,
    this.totalAmount = 0,
    this.isPaid = false,
    this.paidAt,
    this.deliveredAt,
    this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem> items = const []}) {
    // Handle both flat keys (customer_name) and nested (customers.name)
    final customersJson = json['customers'] as Map<String, dynamic>?;
    final createdByJson = json['created_by_user'] as Map<String, dynamic>?;
    final claimedByJson = json['claimed_by_user'] as Map<String, dynamic>?;

    final customerName = (customersJson?['name'] as String?) ?? (json['customer_name'] as String?) ?? '';
    final customerAddress = (customersJson?['address'] as String?) ?? (json['customer_address'] as String?) ?? '';
    final notes = (customersJson?['notes'] as String?) ?? (json['customer_notes'] as String?) ?? '';
    final createdByName = (createdByJson?['name'] as String?) ?? (json['created_by_name'] as String?) ?? '';
    final claimedByName = (claimedByJson?['name'] as String?) ?? (json['claimed_by_name'] as String?) ?? '';

    final (lat, lng) = _parseCoords(notes);
    return Order(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String,
      customerName: customerName,
      customerAddress: customerAddress,
      customerLatitude: lat,
      customerLongitude: lng,
      createdBy: json['created_by'] as String,
      createdByName: createdByName,
      claimedBy: json['claimed_by'] as String?,
      claimedByName: claimedByName,
      status: parseStatus(json['status'] as String),
      deliveryDeadline: json['delivery_deadline'] != null
          ? DateTime.parse(json['delivery_deadline'] as String)
          : null,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      isPaid: (json['is_paid'] as bool?) ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      items: items,
    );
  }

  static OrderStatus parseStatus(String s) {
    switch (s) {
      case 'pending': return OrderStatus.pending;
      case 'claimed': return OrderStatus.claimed;
      case 'delivered': return OrderStatus.delivered;
      case 'completed': return OrderStatus.completed;
      default: return OrderStatus.pending;
    }
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending: return '待认领';
      case OrderStatus.claimed: return '送货中';
      case OrderStatus.delivered: return '未收款';
      case OrderStatus.completed: return '已完成';
    }
  }

  String get statusDbValue {
    switch (status) {
      case OrderStatus.pending: return 'pending';
      case OrderStatus.claimed: return 'claimed';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.completed: return 'completed';
    }
  }

  static (double?, double?) _parseCoords(String notes) {
    if (notes.isEmpty) return (null, null);
    try {
      final map = jsonDecode(notes) as Map<String, dynamic>;
      final lat = map['lat'];
      final lng = map['lng'];
      return (
        lat is num ? lat.toDouble() : null,
        lng is num ? lng.toDouble() : null,
      );
    } catch (_) {
      return (null, null);
    }
  }
}