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
  final DateFormat _dateFormat = DateFormat('MM/dd');
  List<Order> _orders = [];
  bool _loading = true;
  String? _statusFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;

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
    // Default to today
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, now.day);
    _dateTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await _orderService.getOrders(
      statuses: _statusFilter != null ? [_statusFilter!] : null,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
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
          // Date range picker
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateFrom ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateFrom = DateTime(date.year, date.month, date.day));
                        _load();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '开始',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: Text(
                        _dateFrom != null ? _dateFormat.format(_dateFrom!) : '不限',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('至', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateTo ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateTo = DateTime(date.year, date.month, date.day, 23, 59, 59));
                        _load();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '结束',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: Text(
                        _dateTo != null ? _dateFormat.format(_dateTo!) : '不限',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: '清除日期',
                  onPressed: () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    });
                    _load();
                  },
                ),
              ],
            ),
          ),

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