// lib/widgets/order_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Color? actionColor;
  final bool showClaimButton;
  final VoidCallback? onClaim;

  const OrderCard({
    super.key,
    required this.order,
    this.onAction,
    this.actionLabel,
    this.actionColor,
    this.showClaimButton = false,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final currencyFormat = NumberFormat('#,##0.00');

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
                Expanded(
                  child: Text(
                    order.customerName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(color: _statusColor(order.status), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (order.deliveryDeadline != null)
              _InfoRow(icon: Icons.access_time, text: '要求送达: ${dateFormat.format(order.deliveryDeadline!)}'),
            if (order.deliveredAt != null)
              _InfoRow(icon: Icons.check_circle_outline, text: '实际送达: ${dateFormat.format(order.deliveredAt!)}'),
            _InfoRow(icon: Icons.person, text: '记账: ${order.createdByName}'),
            if (order.claimedByName != null && order.claimedByName!.isNotEmpty)
              _InfoRow(icon: Icons.delivery_dining, text: '送货: ${order.claimedByName}'),

            const Divider(height: 16),

            Text('总金额: ¥${currencyFormat.format(order.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showClaimButton && order.status == OrderStatus.pending)
                  FilledButton.icon(
                    onPressed: onClaim,
                    icon: const Icon(Icons.directions_bike, size: 18),
                    label: const Text('我去送'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                if (actionLabel != null && onAction != null) ...[
                  if (showClaimButton) const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: actionColor,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.claimed: return Colors.blue;
      case OrderStatus.delivered: return Colors.red;
      case OrderStatus.completed: return Colors.green;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}