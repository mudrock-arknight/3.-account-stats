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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await _orderService.getOrders(statuses: ['completed']);
    setState(() => _orders = orders);
  }

  void _showDetail(Order order) async {
    final items = await _orderService.getOrderItems(order.id!);
    if (!mounted) return;

    final currencyFormat = NumberFormat('#,##0.00');
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史账单')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _orders.isEmpty
            ? const Center(child: Text('暂无历史账单'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
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
    );
  }
}