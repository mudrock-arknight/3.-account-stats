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
      'unit': item.productUnit,
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
      products:product_id(name)
    ''').eq('order_id', orderId);

    return (response as List).map((row) {
      return OrderItem(
        id: row['id'],
        productId: row['product_id'],
        productName: row['products']?['name'] ?? '',
        productUnit: (row['unit'] as String?) ?? '包',
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

  Future<void> transfer(String orderId, String toUserId) async {
    await _client.from('orders').update({
      'claimed_by': toUserId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<List<Order>> searchHistory(
    String query, {
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    // Split query by spaces to support "王老板 鸡柳" combined search
    final keywords = query.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    // Find matching customers
    Set<String> customerIds = {};
    for (final kw in keywords) {
      final customerResponse = await _client
          .from('customers')
          .select('id')
          .ilike('name', '%$kw%');
      customerIds.addAll(
        (customerResponse as List).map((c) => c['id'] as String),
      );
    }

    var orderQuery = _client.from('orders').select('''
      *,
      customers:customer_id(name, address, notes),
      created_by_user:created_by(name),
      claimed_by_user:claimed_by(name)
    ''').eq('status', 'completed');

    if (customerIds.isNotEmpty) {
      orderQuery = orderQuery.inFilter('customer_id', customerIds.toList());
    }

    // Date range filter
    if (dateFrom != null) {
      orderQuery = orderQuery.gte('created_at', dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      // Include the whole end day
      final endDay = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
      orderQuery = orderQuery.lte('created_at', endDay.toIso8601String());
    }

    final response = await orderQuery.order('created_at', ascending: false);
    var orders = (response as List).map((row) {
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

    // Product keyword filtering — also fetch items for matched orders
    final productKeywords = keywords.where((kw) {
      // A keyword is a product keyword if it doesn't match any customer name
      return !orders.any((o) => o.customerName.toLowerCase().contains(kw.toLowerCase()));
    }).toList();

    if (productKeywords.isNotEmpty && orders.isNotEmpty) {
      final orderIds = orders.map((o) => o.id!).toList();
      final itemResponse = await _client
          .from('order_items')
          .select('order_id, products:product_id(name)')
          .inFilter('order_id', orderIds);

      // For each product keyword, find matching orders
      for (final kw in productKeywords) {
        final matchedOrderIds = (itemResponse as List)
            .where((item) {
              final productName = (item['products']?['name'] ?? '').toString().toLowerCase();
              return productName.contains(kw.toLowerCase());
            })
            .map((item) => item['order_id'] as String)
            .toSet();

        orders.retainWhere((o) => matchedOrderIds.contains(o.id));
      }
    }

    // Load items for each order (needed for summary)
    for (final order in orders) {
      final items = await getOrderItems(order.id!);
      // Replace the empty items list with real items
      final orderWithItems = Order(
        id: order.id,
        customerId: order.customerId,
        customerName: order.customerName,
        customerAddress: order.customerAddress,
        customerLatitude: order.customerLatitude,
        customerLongitude: order.customerLongitude,
        createdBy: order.createdBy,
        createdByName: order.createdByName,
        claimedBy: order.claimedBy,
        claimedByName: order.claimedByName,
        status: order.status,
        deliveryDeadline: order.deliveryDeadline,
        totalAmount: order.totalAmount,
        isPaid: order.isPaid,
        paidAt: order.paidAt,
        deliveredAt: order.deliveredAt,
        createdAt: order.createdAt,
        items: items,
      );
      final idx = orders.indexOf(order);
      orders[idx] = orderWithItems;
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