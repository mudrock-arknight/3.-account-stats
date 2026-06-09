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

class DailyReport {
  final DateTime date;
  final List<DailyCustomerSummary> customerSummaries;
  final List<ProductSalesSummary> productSummaries;
  final double totalAmount;
  final int orderCount;

  const DailyReport({
    required this.date,
    required this.customerSummaries,
    required this.productSummaries,
    required this.totalAmount,
    required this.orderCount,
  });
}

class DailyCustomerSummary {
  final String customerId;
  final String customerName;
  final double totalAmount;
  final int orderCount;

  const DailyCustomerSummary({
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
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

  Future<DailyReport> getDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('orders')
        .select('''
          *,
          customers:customer_id(name)
        ''')
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String())
        .order('created_at', ascending: false);

    final orders = response as List;
    final orderIds = orders.map((o) => o['id'] as String).toList();
    final totalAmount = orders.fold<double>(0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));

    final Map<String, DailyCustomerSummary> customerMap = {};
    for (final o in orders) {
      final cid = o['customer_id'] as String;
      final cname = o['customers']?['name'] ?? '';
      final amt = (o['total_amount'] as num?)?.toDouble() ?? 0;
      if (customerMap.containsKey(cid)) {
        final existing = customerMap[cid]!;
        customerMap[cid] = DailyCustomerSummary(
          customerId: cid, customerName: cname,
          totalAmount: existing.totalAmount + amt,
          orderCount: existing.orderCount + 1,
        );
      } else {
        customerMap[cid] = DailyCustomerSummary(
          customerId: cid, customerName: cname,
          totalAmount: amt, orderCount: 1,
        );
      }
    }

    List<ProductSalesSummary> productSummaries = [];
    if (orderIds.isNotEmpty) {
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

      final Map<String, ProductSalesSummary> productMap = {};
      for (final item in (itemResponse as List)) {
        final pid = item['product_id'] as String;
        final name = item['products']?['name'] ?? '';
        final unit = item['products']?['unit'] ?? '';
        final qty = (item['quantity'] as num).toDouble();
        final subtotalAmt = (item['subtotal'] as num).toDouble();
        if (productMap.containsKey(pid)) {
          final e = productMap[pid]!;
          productMap[pid] = ProductSalesSummary(
            productId: pid, productName: name, productUnit: unit,
            totalQuantity: e.totalQuantity + qty,
            totalAmount: e.totalAmount + subtotalAmt,
          );
        } else {
          productMap[pid] = ProductSalesSummary(
            productId: pid, productName: name, productUnit: unit,
            totalQuantity: qty, totalAmount: subtotalAmt,
          );
        }
      }
      productSummaries = productMap.values.toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }

    return DailyReport(
      date: date,
      customerSummaries: customerMap.values.toList(),
      productSummaries: productSummaries,
      totalAmount: totalAmount,
      orderCount: orders.length,
    );
  }
}