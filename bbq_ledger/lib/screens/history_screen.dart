// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/order_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final OrderService _orderService = OrderService();
  final _searchController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<Order> _orders = [];
  bool _loading = true;
  Map<String, _CustomerSummary>? _summary;
  List<String> _productKeywords = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await _orderService.getOrders(statuses: ['completed']);

    // Batch-load items in parallel — much faster than sequential loop
    if (orders.isNotEmpty) {
      final futures = orders.map((o) => _orderService.getOrderItems(o.id!));
      final itemsList = await Future.wait(futures);

      for (var i = 0; i < orders.length; i++) {
        orders[i] = Order(
          id: orders[i].id, customerId: orders[i].customerId, customerName: orders[i].customerName,
          customerAddress: orders[i].customerAddress, customerLatitude: orders[i].customerLatitude,
          customerLongitude: orders[i].customerLongitude, createdBy: orders[i].createdBy,
          createdByName: orders[i].createdByName, claimedBy: orders[i].claimedBy,
          claimedByName: orders[i].claimedByName, status: orders[i].status,
          deliveryDeadline: orders[i].deliveryDeadline, totalAmount: orders[i].totalAmount,
          isPaid: orders[i].isPaid, paidAt: orders[i].paidAt, deliveredAt: orders[i].deliveredAt,
          createdAt: orders[i].createdAt, items: itemsList[i],
        );
      }
    }

    setState(() {
      _orders = orders;
      _loading = false;
      _summary = null;
      _productKeywords = [];
    });
  }

  Future<void> _search({String? query, DateTime? from, DateTime? to}) async {
    setState(() => _loading = true);
    final orders = await _orderService.searchHistory(
      query?.trim() ?? '',
      dateFrom: from,
      dateTo: to,
    );
    final q = query?.trim() ?? '';

    final keywords = q.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final customerKeywords = keywords.where((k) =>
      orders.any((o) => o.customerName.toLowerCase().contains(k.toLowerCase()))
    ).toList();
    _productKeywords = keywords.where((k) => !customerKeywords.contains(k)).toList();

    _summary = null;
    if (q.isNotEmpty && orders.isNotEmpty) {
      _summary = _buildSummary(orders, q);
    }

    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  Map<String, _CustomerSummary> _buildSummary(List<Order> orders, String queryStr) {
    final keywords = queryStr.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final customerKeyword = keywords.where((k) => _matchCustomer(orders, k)).toList();
    final productKeyword = keywords.where((k) => _matchProduct(orders, k)).toList();

    if (customerKeyword.isEmpty && productKeyword.isEmpty) return {};

    final map = <String, _CustomerSummary>{};
    for (final order in orders) {
      final key = order.customerName;
      map.putIfAbsent(key, () => _CustomerSummary(customerName: key));
      final items = _productKeywords.isNotEmpty
          ? order.items.where((i) => _productKeywords.any((k) => i.productName.toLowerCase().contains(k.toLowerCase()))).toList()
          : order.items;
      final total = items.fold<double>(0, (s, i) => s + i.calculatedSubtotal);
      map[key]!.totalAmount += total;
      map[key]!.orderCount++;
      map[key]!.orders.add(order);
    }
    return map;
  }

  bool _matchCustomer(List<Order> orders, String keyword) {
    return orders.any((o) => o.customerName.toLowerCase().contains(keyword.toLowerCase()));
  }

  bool _matchProduct(List<Order> orders, String keyword) {
    return orders.any((o) => o.items.any(
          (i) => i.productName.toLowerCase().contains(keyword.toLowerCase()),
        ));
  }

  void _showSummary() {
    if (_summary == null || _summary!.isEmpty) return;
    final currencyFormat = NumberFormat('#,##0.00');

    final allProducts = <String>{};
    for (final cs in _summary!.values) {
      for (final o in cs.orders) {
        for (final item in o.items) {
          allProducts.add(item.productName);
        }
      }
    }
    final sortedProducts = allProducts.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('汇总', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('${_summary!.length}个客户', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._summary!.entries.map((entry) {
                      final cs = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(cs.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              Text('¥${currencyFormat.format(cs.totalAmount)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                          subtitle: Text('${cs.orderCount}笔订单'),
                          children: [
                            ..._buildCustomerProductRows(cs, sortedProducts, currencyFormat),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('总计', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('¥${currencyFormat.format(_summary!.values.fold<double>(0, (s, c) => s + c.totalAmount))}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCustomerProductRows(_CustomerSummary cs, List<String> products, NumberFormat fmt) {
    final grouped = <String, _ProductAgg>{};
    for (final order in cs.orders) {
      for (final item in order.items) {
        grouped.putIfAbsent(item.productName, () => _ProductAgg(name: item.productName, unit: item.productUnit));
        grouped[item.productName]!.totalQty += item.quantity;
        grouped[item.productName]!.totalAmount += item.calculatedSubtotal;
        grouped[item.productName]!.prices.add(item.unitPrice);
      }
    }

    return grouped.values.map((agg) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text('${agg.name} ×${agg.totalQty}${agg.unit}', style: const TextStyle(fontSize: 13))),
            Expanded(flex: 2, child: Text('¥${agg.prices.map((p) => p.toStringAsFixed(2)).join("/")}', style: const TextStyle(fontSize: 11, color: Colors.grey))),
            Expanded(flex: 2, child: Text('¥${fmt.format(agg.totalAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          ],
        ),
      );
    }).toList();
  }

  List<OrderItem> _filteredItems(Order order) {
    if (_productKeywords.isEmpty) return order.items;
    return order.items.where((item) =>
      _productKeywords.any((k) => item.productName.toLowerCase().contains(k.toLowerCase()))
    ).toList();
  }

  Widget _buildOrderCard(Order order) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final currencyFormat = NumberFormat('#,##0.00');
    final items = _filteredItems(order);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Text('¥${currencyFormat.format(order.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 6),
            if (order.createdAt != null)
              Text(dateFormat.format(order.createdAt!), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (order.paidAt != null)
              Text('收款: ${dateFormat.format(order.paidAt!)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (items.isNotEmpty) ...[
              const Divider(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('${item.productName} ×${item.quantity}${item.productUnit}', style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 2, child: Text('¥${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('¥${currencyFormat.format(item.calculatedSubtotal)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');

    return Scaffold(
      appBar: AppBar(title: const Text('历史账单')),
      body: Column(
        children: [
          // Date range
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateFrom ?? DateTime.now().subtract(const Duration(days: 7)),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateFrom = date);
                        _search(query: _searchController.text.trim(), from: _dateFrom, to: _dateTo);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '开始', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      child: Text(_dateFrom != null ? dateFormat.format(_dateFrom!) : '不限', style: TextStyle(fontSize: 13, color: _dateFrom != null ? null : Colors.grey)),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('至', style: TextStyle(color: Colors.grey))),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: _dateTo ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                      if (date != null) {
                        setState(() => _dateTo = date);
                        _search(query: _searchController.text.trim(), from: _dateFrom, to: _dateTo);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '结束', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      child: Text(_dateTo != null ? dateFormat.format(_dateTo!) : '不限', style: TextStyle(fontSize: 13, color: _dateTo != null ? null : Colors.grey)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar (standalone, full width, no right button to stay within bounds)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜客户名 货品名',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); _load(); })
                    : null,
              ),
              style: const TextStyle(fontSize: 14),
              onSubmitted: (v) => _search(query: v, from: _dateFrom, to: _dateTo),
            ),
          ),

          // Summary button
          if (_summary != null && _summary!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.summarize),
                  label: Text('查看汇总（${_summary!.length}个客户）'),
                  onPressed: _showSummary,
                ),
              ),
            ),

          // Clear filters
          if (_dateFrom != null || _dateTo != null || _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () { setState(() { _dateFrom = null; _dateTo = null; }); _searchController.clear(); _load(); },
                child: const Text('清除筛选'),
              ),
            ),

          // Order list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _orders.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_off, size: 48, color: Colors.grey.shade400), const SizedBox(height: 8), const Text('暂无匹配的历史账单')]))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSummary {
  final String customerName;
  double totalAmount = 0;
  int orderCount = 0;
  final List<Order> orders = [];
  _CustomerSummary({required this.customerName});
}

class _ProductAgg {
  final String name;
  final String unit;
  double totalQty = 0;
  double totalAmount = 0;
  final List<double> prices = [];
  _ProductAgg({required this.name, required this.unit});
}