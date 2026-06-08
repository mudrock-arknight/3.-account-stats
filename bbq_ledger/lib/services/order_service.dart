// lib/services/order_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Order> create({
    required String customerId,
    required String createdBy,
    DateTime? deliveryDeadline,
    required List<OrderItem> items,
  }) async {
    final orderResponse = await _client.from('orders').insert({
      'customer_id': customerId,
      'created_by': createdBy,
      'delivery_deadline': deliveryDeadline?.toIso8601String(),
      'status': 'pending',
    }).select('''
      *,
      customers:customer_id(name),
      created_by_user:created_by(name)
    ''').single();

    final orderId = orderResponse['id'] as String;

    final itemRows = items.map((item) => {
      'order_id': orderId,
      'product_id': item.productId,
      'quantity': item.quantity,
      'unit_price': item.unitPrice,
    }).toList();

    await _client.from('order_items').insert(itemRows);
    await _updateTotalAmount(orderId);

    return Order.fromJson(orderResponse);
  }

  Future<void> _updateTotalAmount(String orderId) async {
    final result = await _client
        .from('order_items')
        .select('subtotal')
        .eq('order_id', orderId);

    final total = (result as List).fold<double>(
      0, (sum, item) => sum + ((item['subtotal'] as num?)?.toDouble() ?? 0),
    );

    await _client.from('orders').update({
      'total_amount': total,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<List<Order>> getOrders({
    List<String>? statuses,
    String? claimedBy,
  }) async {
    var query = _client.from('orders').select('''
      *,
      customers:customer_id(name),
      created_by_user:created_by(name),
      claimed_by_user:claimed_by(name)
    ''');

    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter('status', statuses);
    }
    if (claimedBy != null) {
      query = query.eq('claimed_by', claimedBy);
    }

    final response = await query.order('created_at', ascending: false);
    final orders = (response as List).map((row) {
      return Order(
        id: row['id'],
        customerId: row['customer_id'],
        customerName: row['customers']?['name'] ?? '',
        createdBy: row['created_by'],
        createdByName: row['created_by_user']?['name'] ?? '',
        claimedBy: row['claimed_by'],
        claimedByName: row['claimed_by_user']?['name'] ?? '',
        status: Order.parseStatus(row['status']),
        deliveryDeadline: row['delivery_deadline'] != null
            ? DateTime.parse(row['delivery_deadline'])
            : null,
        totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0,
        isPaid: row['is_paid'] ?? false,
        paidAt: row['paid_at'] != null ? DateTime.parse(row['paid_at']) : null,
        deliveredAt: row['delivered_at'] != null ? DateTime.parse(row['delivered_at']) : null,
        createdAt: DateTime.parse(row['created_at']),
      );
    }).toList();

    return orders;
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final response = await _client.from('order_items').select('''
      *,
      products:product_id(name, unit)
    ''').eq('order_id', orderId);

    return (response as List).map((row) {
      return OrderItem(
        id: row['id'],
        productId: row['product_id'],
        productName: row['products']?['name'] ?? '',
        productUnit: row['products']?['unit'] ?? '包',
        quantity: (row['quantity'] as num).toDouble(),
        unitPrice: (row['unit_price'] as num).toDouble(),
        subtotal: (row['subtotal'] as num).toDouble(),
      );
    }).toList();
  }

  Future<void> claim(String orderId, String userId) async {
    await _client.from('orders').update({
      'claimed_by': userId,
      'status': 'claimed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<void> markDelivered(String orderId) async {
    await _client.from('orders').update({
      'status': 'delivered',
      'delivered_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<void> markPaid(String orderId) async {
    await _client.from('orders').update({
      'status': 'completed',
      'is_paid': true,
      'paid_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }
}