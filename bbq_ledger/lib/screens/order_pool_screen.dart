import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';

class OrderPoolScreen extends StatelessWidget {
  const OrderPoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('待认领订单')),
      body: orderProvider.pendingOrders.isEmpty
          ? const Center(child: Text('暂无待认领订单'))
          : RefreshIndicator(
              onRefresh: () => orderProvider.loadAll(auth.currentUser!.id),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.pendingOrders.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.pendingOrders[index];
                  return OrderCard(
                    order: order,
                    showClaimButton: true,
                    onClaim: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认认领'),
                          content: Text('确定要配送「${order.customerName}」的订单吗？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                orderProvider.claimOrder(order.id!, auth.currentUser!.id);
                              },
                              child: const Text('确认认领'),
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