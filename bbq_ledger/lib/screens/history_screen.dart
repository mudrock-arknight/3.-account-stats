// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  final _searchController = TextEditingController();

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
    final orders = await _orderService.getOrders(statuses: ['completed']);
    setState(() => _orders = orders);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _load();
      return;
    }
    final orders = await _orderService.searchHistory(query.trim());
    setState(() => _orders = orders);
  }

  void _showDetail(Order order) async {
    final items = await _orderService.getOrderItems(order.id!);
    if (!mounted) return;

    final currencyFormat = NumberFormat('#,##0.00');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Text('${order.customerName} — 订单明细', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  ...items.map((item) => ListTile(
                        title: Text('${item.productName} × ${item.quantity}${item.productUnit}'),
                        subtitle: Text('单价 ¥${item.unitPrice.toStringAsFixed(2)}'),
                        trailing: Text('¥${currencyFormat.format(item.calculatedSubtotal)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('总金额', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('¥${currencyFormat.format(order.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                    ],
                  ),
                  if (order.paidAt != null)
                    Text('收款时间: ${DateFormat('yyyy-MM-dd HH:mm').format(order.paidAt!)}',
                        style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史账单')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索客户名称、货品名称...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? const Center(child: Text('暂无历史账单'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return OrderCard(
                          order: order,
                          onAction: () => _showDetail(order),
                          actionLabel: '查看明细',
                          actionColor: Colors.grey,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}