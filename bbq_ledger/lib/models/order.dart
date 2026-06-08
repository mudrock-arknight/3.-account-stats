// lib/models/order.dart
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
    return Order(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String,
      customerName: (json['customer_name'] as String?) ?? '',
      createdBy: json['created_by'] as String,
      createdByName: (json['created_by_name'] as String?) ?? '',
      claimedBy: json['claimed_by'] as String?,
      claimedByName: (json['claimed_by_name'] as String?) ?? '',
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
}