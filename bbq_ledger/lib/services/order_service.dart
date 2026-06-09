// lib/services/order_service.dart
import 'dart:convert';
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
      customers:customer_id(name, address, notes),
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
      customers:customer_id(name, address, notes),
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
      final notes = (row['customers']?['notes'] as String?) ?? '';
      final (lat, lng) = _parseCoords(notes);
      return Order(
        id: row['id'],
        customerId: row['customer_id'],
        customerName: row['customers']?['name'] ?? '',
        customerAddress: row['customers']?['address'] ?? '',
        customerLatitude: lat,
        customerLongitude: lng,
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

  Future<List<Order>> searchHistory(String query) async {
    final customerResponse = await _client
        .from('customers')
        .select('id')
        .ilike('name', '%$query%');
    final customerIds = (customerResponse as List).map((c) => c['id'] as String).toList();

    var orderQuery = _client.from('orders').select('''
      *,
      customers:customer_id(name, address, notes),
      created_by_user:created_by(name),
      claimed_by_user:claimed_by(name)
    ''').eq('status', 'completed');

    if (customerIds.isNotEmpty) {
      orderQuery = orderQuery.inFilter('customer_id', customerIds);
    }

    final response = await orderQuery.order('created_at', ascending: false);
    final orders = (response as List).map((row) {
      return Order(
        id: row['id'],
        customerId: row['customer_id'],
        customerName: row['customers']?['name'] ?? '',
        customerAddress: row['customers']?['address'] ?? '',
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

    if (query.isNotEmpty && customerIds.length < orders.length) {
      final itemResponse = await _client
          .from('order_items')
          .select('order_id, products:product_id(name)')
          .inFilter('order_id', orders.map((o) => o.id!).toList());

      final matchedOrderIds = (itemResponse as List)
          .where((item) {
            final productName = (item['products']?['name'] ?? '').toString().toLowerCase();
            return productName.contains(query.toLowerCase());
          })
          .map((item) => item['order_id'] as String)
          .toSet();

      if (customerIds.isEmpty) {
        orders.retainWhere((o) => matchedOrderIds.contains(o.id));
      } else {
        orders.retainWhere((o) => customerIds.contains(o.customerId) || matchedOrderIds.contains(o.id));
      }
    }

    return orders;
  }
}

/// Helper to parse lat/lng from notes JSON
(double?, double?) _parseCoords(String notes) {
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