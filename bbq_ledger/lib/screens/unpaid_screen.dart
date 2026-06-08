// lib/screens/unpaid_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';

class UnpaidScreen extends StatelessWidget {
  const UnpaidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('未收款订单')),
      body: orderProvider.unpaidOrders.isEmpty
          ? const Center(child: Text('暂无未收款订单'))
          : RefreshIndicator(
              onRefresh: () => orderProvider.loadAll(auth.currentUser!.id),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.unpaidOrders.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.unpaidOrders[index];
                  return OrderCard(
                    order: order,
                    actionLabel: '确认收款',
                    actionColor: Colors.blue,
                    onAction: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认收款'),
                          content: Text('确定已收到「${order.customerName}」的 ¥${order.totalAmount.toStringAsFixed(2)}？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                orderProvider.markPaid(order.id!, auth.currentUser!.id);
                              },
                              child: const Text('确认收款'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}