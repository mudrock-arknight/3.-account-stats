// lib/screens/my_deliveries_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';

class MyDeliveriesScreen extends StatelessWidget {
  const MyDeliveriesScreen({super.key});

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
                  return OrderCard(
                    order: order,
                    actionLabel: '确认送达',
                    actionColor: Colors.green,
                    onAction: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认送达'),
                          content: Text('确定「${order.customerName}」的订单已送达？\n总金额: ¥${order.totalAmount.toStringAsFixed(2)}'),
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
                  );
                },
              ),
            ),
    );
  }
}