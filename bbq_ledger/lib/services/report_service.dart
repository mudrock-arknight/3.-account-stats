// lib/services/report_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyReport {
  final int year;
  final int month;
  final List<ProductSalesSummary> productSummaries;
  final double totalRevenue;
  final int orderCount;

  const MonthlyReport({
    required this.year,
    required this.month,
    required this.productSummaries,
    required this.totalRevenue,
    required this.orderCount,
  });
}

class ProductSalesSummary {
  final String productId;
  final String productName;
  final String productUnit;
  final double totalQuantity;
  final double totalAmount;

  const ProductSalesSummary({
    required this.productId,
    required this.productName,
    required this.productUnit,
    required this.totalQuantity,
    required this.totalAmount,
  });
}

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final orderResponse = await _client
        .from('orders')
        .select('id, total_amount')
        .eq('status', 'completed')
        .gte('paid_at', startDate.toIso8601String())
        .lt('paid_at', endDate.toIso8601String());

    final orders = orderResponse as List;
    final orderIds = orders.map((o) => o['id'] as String).toList();

    if (orderIds.isEmpty) {
      return MonthlyReport(
        year: year, month: month,
        productSummaries: [], totalRevenue: 0, orderCount: 0,
      );
    }

    final itemResponse = await _client
        .from('order_items')
        .select('''
          product_id,
          quantity,
          unit_price,
          subtotal,
          products:product_id(name, unit)
        ''')
        .inFilter('order_id', orderIds);

    final items = itemResponse as List;

    final Map<String, ProductSalesSummary> summaryMap = {};
    for (final item in items) {
      final pid = item['product_id'] as String;
      final name = item['products']?['name'] ?? '';
      final unit = item['products']?['unit'] ?? '';
      final qty = (item['quantity'] as num).toDouble();
      final subtotalAmount = (item['subtotal'] as num).toDouble();

      if (summaryMap.containsKey(pid)) {
        final existing = summaryMap[pid]!;
        summaryMap[pid] = ProductSalesSummary(
          productId: pid,
          productName: name,
          productUnit: unit,
          totalQuantity: existing.totalQuantity + qty,
          totalAmount: existing.totalAmount + subtotalAmount,
        );
      } else {
        summaryMap[pid] = ProductSalesSummary(
          productId: pid,
          productName: name,
          productUnit: unit,
          totalQuantity: qty,
          totalAmount: subtotalAmount,
        );
      }
    }

    final totalRevenue = orders.fold<double>(
      0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0),
    );

    return MonthlyReport(
      year: year,
      month: month,
      productSummaries: summaryMap.values.toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)),
      totalRevenue: totalRevenue,
      orderCount: orders.length,
    );
  }
}