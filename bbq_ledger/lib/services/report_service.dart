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
  final List<CustomerProductRow> customerProductRows;
  final double totalAmount;
  final int orderCount;

  const DailyReport({
    required this.date,
    required this.customerSummaries,
    required this.productSummaries,
    required this.customerProductRows,
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

class CustomerProductRow {
  final String productName;
  final String productUnit;
  final Map<String, double> customerQuantities;
  final double totalQuantity;

  const CustomerProductRow({
    required this.productName,
    required this.productUnit,
    required this.customerQuantities,
    required this.totalQuantity,
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
    // Use UTC+8 (China) boundary: date 00:00 China = (date-1) 16:00 UTC
    final chinaStart = DateTime.utc(date.year, date.month, date.day).subtract(const Duration(hours: 8));
    final chinaEnd = chinaStart.add(const Duration(days: 1));

    final response = await _client
        .from('orders')
        .select('''
          *,
          customers:customer_id(name)
        ''')
        .gte('created_at', chinaStart.toIso8601String())
        .lt('created_at', chinaEnd.toIso8601String())
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

    // Build customer × product pivot table
    final Map<String, Map<String, double>> pivot = {}; // productName -> customerName -> qty
    if (orderIds.isNotEmpty) {
      final pivotResponse = await _client
          .from('order_items')
          .select('''
            product_id,
            quantity,
            products:product_id(name, unit),
            orders:order_id(customer_id, customers:customer_id(name))
          ''')
          .inFilter('order_id', orderIds);
      for (final item in (pivotResponse as List)) {
        final pName = item['products']?['name'] ?? '';
        final pUnit = item['products']?['unit'] ?? '';
        final cName = item['orders']?['customers']?['name'] ?? '';
        final qty = (item['quantity'] as num).toDouble();
        final key = '$pName|$pUnit';
        pivot.putIfAbsent(key, () => {});
        pivot[key]!.update(cName, (v) => v + qty, ifAbsent: () => qty);
      }
    }
    final customerProductRows = pivot.entries.map((e) {
      final parts = e.key.split('|');
      final totalQty = e.value.values.fold<double>(0, (s, v) => s + v);
      return CustomerProductRow(
        productName: parts[0],
        productUnit: parts.length > 1 ? parts[1] : '',
        customerQuantities: e.value,
        totalQuantity: totalQty,
      );
    }).toList()
      ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    return DailyReport(
      date: date,
      customerSummaries: customerMap.values.toList(),
      productSummaries: productSummaries,
      customerProductRows: customerProductRows,
      totalAmount: totalAmount,
      orderCount: orders.length,
    );
  }
}