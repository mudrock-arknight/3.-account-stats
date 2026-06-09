// lib/screens/order_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';

class OrderOverviewScreen extends StatefulWidget {
  const OrderOverviewScreen({super.key});

  @override
  State<OrderOverviewScreen> createState() => _OrderOverviewScreenState();
}

class _OrderOverviewScreenState extends State<OrderOverviewScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _loading = true;
  String? _statusFilter;

  static const _filters = [
    {'label': '全部', 'value': null},
    {'label': '待认领', 'value': 'pending'},
    {'label': '配送中', 'value': 'claimed'},
    {'label': '已送达', 'value': 'delivered'},
    {'label': '已完成', 'value': 'completed'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await _orderService.getOrders(
      statuses: _statusFilter != null ? [_statusFilter!] : null,
    );
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _orders.where((o) => o.status == OrderStatus.pending).length;
    final claimedCount = _orders.where((o) => o.status == OrderStatus.claimed).length;
    final undeliveredCount = pendingCount + claimedCount;

    return Scaffold(
      appBar: AppBar(title: const Text('订单总览')),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(label: '全部', value: '${_orders.length}', color: Colors.blue),
                _StatChip(label: '未送', value: '$undeliveredCount', color: Colors.red),
                _StatChip(label: '待认领', value: '$pendingCount', color: Colors.orange),
                _StatChip(label: '已完成', value: '${_orders.where((o) => o.status == OrderStatus.completed).length}', color: Colors.green),
              ],
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final selected = _statusFilter == f['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f['label'] as String),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _statusFilter = f['value'] as String?);
                        _load();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Order list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _orders.isEmpty
                        ? const Center(child: Text('暂无订单'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) {
                              final order = _orders[i];
                              return OrderCard(order: order);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}