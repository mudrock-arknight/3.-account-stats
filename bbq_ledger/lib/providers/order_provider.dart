// lib/providers/order_provider.dart
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _pendingOrders = [];
  List<Order> _myDeliveries = [];
  List<Order> _unpaidOrders = [];
  List<Order> _historyOrders = [];
  bool _loading = false;
  bool _initialized = false;

  List<Order> get pendingOrders => _pendingOrders;
  List<Order> get myDeliveries => _myDeliveries;
  List<Order> get unpaidOrders => _unpaidOrders;
  List<Order> get historyOrders => _historyOrders;
  bool get loading => _loading;

  Future<void> loadAll(String currentUserId) async {
    // Only show loading spinner on first load; subsequent loads update in background
    if (!_initialized) {
      _loading = true;
      notifyListeners();
    }

    final results = await Future.wait([
      _orderService.getOrders(statuses: ['pending']),
      _orderService.getOrders(statuses: ['claimed'], claimedBy: currentUserId),
      _orderService.getOrders(statuses: ['delivered']),
      _orderService.getOrders(statuses: ['completed']),
    ]);

    _pendingOrders = results[0];
    _myDeliveries = results[1];
    _unpaidOrders = results[2];
    _historyOrders = results[3];
    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> claimOrder(String orderId, String userId) async {
    await _orderService.claim(orderId, userId);
    await loadAll(userId);
  }

  Future<void> markDelivered(String orderId, String userId) async {
    await _orderService.markDelivered(orderId);
    await loadAll(userId);
  }

  Future<void> markPaid(String orderId, String userId) async {
    await _orderService.markPaid(orderId);
    await loadAll(userId);
  }

  Future<void> transferOrder(String orderId, String fromUserId, String toUserId) async {
    await _orderService.transfer(orderId, toUserId);
    await loadAll(fromUserId);
  }
}