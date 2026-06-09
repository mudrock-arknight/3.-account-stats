// lib/screens/my_deliveries_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/auth_service.dart';
import '../widgets/order_card.dart';

class MyDeliveriesScreen extends StatefulWidget {
  const MyDeliveriesScreen({super.key});

  @override
  State<MyDeliveriesScreen> createState() => _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends State<MyDeliveriesScreen> {
  final AuthService _authService = AuthService();
  List<AppUser> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _authService.getUsers();
    setState(() => _allUsers = users);
  }

  void _showTransferDialog(String orderId, String currentUserId, String customerName, BuildContext context) {
    final otherUsers = _allUsers.where((u) => u.id != currentUserId).toList();
    if (otherUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有其他用户可转单')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('将「$customerName」的订单转给', style: Theme.of(ctx).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          ...otherUsers.map((u) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  child: Text(u.name[0], style: const TextStyle(color: Colors.blue)),
                ),
                title: Text(u.name),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<OrderProvider>().transferOrder(orderId, currentUserId, u.id);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的送货')),
      body: orderProvider.myDeliveries.isEmpty
          ? const Center(child: Text('暂无送货任务'))
          : RefreshIndicator(
              onRefresh: () => orderProvider.loadAll(auth.currentUser!.id),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.myDeliveries.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.myDeliveries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        OrderCard(order: order),
                        ButtonBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('转单'),
                              onPressed: () => _showTransferDialog(
                                order.id!, auth.currentUser!.id, order.customerName, context,
                              ),
                            ),
                            FilledButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('确认送达'),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('确认送达'),
                                    content: Text('确定${order.customerName}的订单已送达？\n总金额: ¥${order.totalAmount.toStringAsFixed(2)}'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          orderProvider.markDelivered(order.id!, auth.currentUser!.id);
                                        },
                                        child: const Text('确认送达'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}