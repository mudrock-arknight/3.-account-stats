import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRecord {
  final String id;
  final String productId;
  final String productName;
  final String productUnit;
  final String type; // 'in' or 'out'
  final double quantity;
  final String note;
  final String? relatedOrderId;
  final DateTime createdAt;

  const InventoryRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productUnit,
    required this.type,
    required this.quantity,
    required this.note,
    this.relatedOrderId,
    required this.createdAt,
  });
}

class ProductStock {
  final String productId;
  final String productName;
  final String productUnit;
  final double totalIn;
  final double totalOut;
  double get current => totalIn - totalOut;

  const ProductStock({
    required this.productId,
    required this.productName,
    required this.productUnit,
    required this.totalIn,
    required this.totalOut,
  });
}

class InventoryService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get all inventory records (history)
  Future<List<InventoryRecord>> getRecords({
    String? productId,
    String? type,
  }) async {
    var query = _client.from('inventory_records').select('''
      *,
      products:product_id(name, unit)
    ''');

    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    if (type != null) {
      query = query.eq('type', type);
    }

    final response = await query.order('created_at', ascending: false).limit(200);
    return (response as List).map((row) {
      return InventoryRecord(
        id: row['id'],
        productId: row['product_id'],
        productName: row['products']?['name'] ?? '',
        productUnit: row['products']?['unit'] ?? '',
        type: row['type'],
        quantity: (row['quantity'] as num).toDouble(),
        note: (row['note'] as String?) ?? '',
        relatedOrderId: row['related_order_id'],
        createdAt: DateTime.parse(row['created_at']),
      );
    }).toList();
  }

  /// Get current stock for all products
  Future<List<ProductStock>> getStocks() async {
    final response = await _client.rpc('get_inventory_stock');
    // Fallback: compute in Dart if RPC not available
    if (response == null || (response is List && response.isEmpty)) {
      return await _computeStocks();
    }

    return (response as List).map((row) {
      return ProductStock(
        productId: row['product_id'],
        productName: row['product_name'] ?? '',
        productUnit: row['product_unit'] ?? '',
        totalIn: (row['total_in'] as num?)?.toDouble() ?? 0,
        totalOut: (row['total_out'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  /// Fallback: compute stocks manually
  Future<List<ProductStock>> _computeStocks() async {
    // Get all records
    final response = await _client.from('inventory_records').select('''
      product_id,
      type,
      quantity,
      products:product_id(name, unit)
    ''');

    final records = response as List;
    final Map<String, ProductStock> map = {};

    for (final r in records) {
      final pid = r['product_id'] as String;
      final type = r['type'] as String;
      final qty = (r['quantity'] as num).toDouble();
      final pName = r['products']?['name'] ?? '';
      final pUnit = r['products']?['unit'] ?? '';

      if (!map.containsKey(pid)) {
        map[pid] = ProductStock(
          productId: pid,
          productName: pName,
          productUnit: pUnit,
          totalIn: 0,
          totalOut: 0,
        );
      }

      if (type == 'in') {
        map[pid] = ProductStock(
          productId: pid, productName: pName, productUnit: pUnit,
          totalIn: map[pid]!.totalIn + qty,
          totalOut: map[pid]!.totalOut,
        );
      } else {
        map[pid] = ProductStock(
          productId: pid, productName: pName, productUnit: pUnit,
          totalIn: map[pid]!.totalIn,
          totalOut: map[pid]!.totalOut + qty,
        );
      }
    }

    return map.values.toList()
      ..sort((a, b) => b.current.compareTo(a.current));
  }

  /// Add a stock-in record
  Future<void> addStockIn({
    required String productId,
    required double quantity,
    String note = '',
  }) async {
    await _client.from('inventory_records').insert({
      'product_id': productId,
      'type': 'in',
      'quantity': quantity,
      'note': note,
    });
  }

  /// Add a stock-out record
  Future<void> addStockOut({
    required String productId,
    required double quantity,
    String note = '',
    String? relatedOrderId,
  }) async {
    await _client.from('inventory_records').insert({
      'product_id': productId,
      'type': 'out',
      'quantity': quantity,
      'note': note,
      'related_order_id': relatedOrderId,
    });
  }
}