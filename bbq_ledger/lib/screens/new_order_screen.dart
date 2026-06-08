// lib/screens/new_order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/order_item.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../providers/auth_provider.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  List<Customer> _customers = [];
  List<Product> _products = [];
  Customer? _selectedCustomer;
  DateTime? _deliveryDeadline;
  TimeOfDay? _deliveryTime;

  final List<_ItemRow> _items = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final customers = await _customerService.getAll();
    final products = await _productService.getAll();
    setState(() {
      _customers = customers;
      _products = products;
    });
  }

  void _addItem() {
    setState(() {
      _items.add(_ItemRow());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _onProductSelected(int index, Product product) async {
    final item = _items[index];
    item.product = product;
    item.quantityController.text = '1';

    if (_selectedCustomer != null) {
      final lastPrice = await _productService.getLastPrice(
        _selectedCustomer!.id, product.id,
      );
      if (lastPrice != null) {
        item.priceController.text = lastPrice.toStringAsFixed(2);
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择客户')),
      );
      return;
    }

    final validItems = _items.where((item) => item.isValid).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个货品')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = context.read<AuthProvider>().currentUser!;
      final deliveryDeadline = _deliveryDeadline != null && _deliveryTime != null
          ? DateTime(
              _deliveryDeadline!.year,
              _deliveryDeadline!.month,
              _deliveryDeadline!.day,
              _deliveryTime!.hour,
              _deliveryTime!.minute,
            )
          : null;

      await _orderService.create(
        customerId: _selectedCustomer!.id,
        createdBy: user.id,
        deliveryDeadline: deliveryDeadline,
        items: validItems.map((item) => OrderItem(
          productId: item.product!.id,
          productName: item.product!.name,
          productUnit: item.product!.unit,
          quantity: double.tryParse(item.quantityController.text) ?? 1,
          unitPrice: double.tryParse(item.priceController.text) ?? 0,
        )).toList(),
      );

      for (final item in validItems) {
        final price = double.tryParse(item.priceController.text) ?? 0;
        await _productService.savePrice(_selectedCustomer!.id, item.product!.id, price);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订单已创建'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建订单')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<Customer>(
            initialValue: _selectedCustomer,
            decoration: const InputDecoration(
              labelText: '选择客户',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            items: _customers.map((c) => DropdownMenuItem(
              value: c, child: Text(c.name),
            )).toList(),
            onChanged: (c) => setState(() => _selectedCustomer = c),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_deliveryDeadline != null
                      ? '${_deliveryDeadline!.month}/${_deliveryDeadline!.day}'
                      : '送达日期'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) setState(() => _deliveryDeadline = date);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(_deliveryTime?.format(context) ?? '送达时间'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setState(() => _deliveryTime = time);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text('货品明细', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          ...List.generate(_items.length, (index) {
            final item = _items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Product>(
                            initialValue: item.product,
                            decoration: const InputDecoration(
                              labelText: '货品',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _products.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('${p.name} (${p.unit})'),
                            )).toList(),
                            onChanged: (p) {
                              if (p != null) _onProductSelected(index, p);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: item.quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '数量',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: item.priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '单价',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixText: '¥',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('添加货品'),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('提交订单', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow {
  Product? product;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool get isValid => product != null && quantityController.text.isNotEmpty && priceController.text.isNotEmpty;

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}