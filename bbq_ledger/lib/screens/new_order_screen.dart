// lib/screens/new_order_screen.dart
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/order_item.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

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

  final _customerSearchController = TextEditingController();
  final _productSearchController = TextEditingController();
  List<Customer> _filteredCustomers = [];
  List<Product> _filteredProducts = [];

  // Common units (only 3 options: 包, 件, 条)
  static const List<String> _commonUnits = ['包', '件', '条'];

  @override
  void initState() {
    super.initState();
    _deliveryDeadline = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _productSearchController.dispose();
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

    // Default unit from product
    item.unit = product.unit;

    if (_selectedCustomer != null) {
      // Look up last used unit and price
      final result = await _productService.getLastUnitPrice(
        _selectedCustomer!.id, product.id,
      );
      if (result.unit != null && result.unit!.isNotEmpty) {
        item.unit = result.unit!;
      }
      if (result.price != null) {
        item.priceController.text = result.price!.toStringAsFixed(2);
      }
    }
    setState(() {});
  }

  Future<void> _onUnitChanged(int index) async {
    final item = _items[index];
    if (item.product == null || _selectedCustomer == null) return;

    // When unit changes, look up price for this unit
    final result = await _productService.getLastUnitPrice(
      _selectedCustomer!.id, item.product!.id,
    );
    // Only update price if the stored unit matches and price exists
    if (result.unit == item.unit && result.price != null) {
      item.priceController.text = result.price!.toStringAsFixed(2);
      setState(() {});
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (final item in _items) {
      if (!item.isValid) continue;
      final qty = double.tryParse(item.quantityController.text) ?? 0;
      final price = double.tryParse(item.priceController.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  // --- Customer picker ---
  void _showCustomerPicker() async {
    _filteredCustomers = List.from(_customers);
    _customerSearchController.clear();

    final result = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customerSearchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: '搜索客户...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (q) {
                          setSheetState(() {
                            _filteredCustomers = q.isEmpty
                                ? List.from(_customers)
                                : _customers.where((c) => c.name.toLowerCase().contains(q.toLowerCase())).toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.orange),
                      tooltip: '新增客户',
                      onPressed: () async {
                        final newCustomer = await _showAddCustomerDialog();
                        if (newCustomer != null) {
                          setState(() => _selectedCustomer = newCustomer);
                          if (ctx.mounted) Navigator.pop(ctx, newCustomer);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredCustomers.isEmpty
                    ? const Center(child: Text('没有匹配的客户'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (_, i) {
                          final c = _filteredCustomers[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withValues(alpha: 0.2),
                              child: Text(c.name[0], style: const TextStyle(color: Colors.orange)),
                            ),
                            title: Text(c.name),
                            subtitle: c.phone.isNotEmpty ? Text(c.phone) : null,
                            trailing: _selectedCustomer?.id == c.id ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () => Navigator.pop(ctx, c),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedCustomer = result);
    }
  }

  Future<Customer?> _showAddCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加新客户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '客户名称 *', border: OutlineInputBorder()),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: '电话', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: '地址', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'address': addressController.text.trim(),
              });
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null) {
      final customer = await _customerService.create(
        result['name']!,
        phone: result['phone'] ?? '',
        address: result['address'] ?? '',
      );
      await _loadData();
      return customer;
    }
    return null;
  }

  // --- Product picker ---
  void _showProductPicker(int index) async {
    _filteredProducts = List.from(_products);
    _productSearchController.clear();

    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.8,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _productSearchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '搜索货品...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (q) {
                    setSheetState(() {
                      _filteredProducts = q.isEmpty
                          ? List.from(_products)
                          : _products.where((p) => p.name.toLowerCase().contains(q.toLowerCase())).toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? const Center(child: Text('没有匹配的货品'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredProducts.length,
                        itemBuilder: (_, i) {
                          final p = _filteredProducts[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withValues(alpha: 0.2),
                              child: Text(p.name[0], style: const TextStyle(color: Colors.orange)),
                            ),
                            title: Text(p.name),
                            trailing: Text(p.unit, style: const TextStyle(color: Colors.grey)),
                            onTap: () => Navigator.pop(ctx, p),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      await _onProductSelected(index, result);
    }
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
      final deliveryDeadline = _deliveryDeadline != null
          ? DateTime(
              _deliveryDeadline!.year,
              _deliveryDeadline!.month,
              _deliveryDeadline!.day,
              _deliveryTime?.hour ?? 23,
              _deliveryTime?.minute ?? 59,
            )
          : null;

      await _orderService.create(
        customerId: _selectedCustomer!.id,
        createdBy: user.id,
        deliveryDeadline: deliveryDeadline,
        items: validItems.map((item) => OrderItem(
          productId: item.product!.id,
          productName: item.product!.name,
          productUnit: item.unit,
          quantity: double.tryParse(item.quantityController.text) ?? 1,
          unitPrice: double.tryParse(item.priceController.text) ?? 0,
        )).toList(),
      );

      // Save unit+price memory for each item
      for (final item in validItems) {
        final price = double.tryParse(item.priceController.text) ?? 0;
        await _productService.saveUnitPrice(
          _selectedCustomer!.id, item.product!.id, item.unit, price,
        );
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
          // Customer selection
          InkWell(
            onTap: () => _showCustomerPicker(),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '选择客户',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                suffixIcon: Icon(Icons.search),
              ),
              child: _selectedCustomer != null
                  ? Text(_selectedCustomer!.name, style: const TextStyle(fontSize: 16))
                  : const Text('点击选择客户', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 16),

          // Delivery date & time
          Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_deliveryDeadline != null
                      ? '${_deliveryDeadline!.month}/${_deliveryDeadline!.day}'
                      : '送达日期'),
                  subtitle: const Text('送达日期', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _deliveryDeadline ?? DateTime.now(),
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
                  title: Text(_deliveryTime?.format(context) ?? '不限'),
                  subtitle: const Text('送达时间（可选）', style: TextStyle(fontSize: 12)),
                  trailing: _deliveryTime != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _deliveryTime = null),
                        )
                      : const Icon(Icons.chevron_right),
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

          // Products header
          Text('货品明细', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // Product items
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            return _buildItemCard(index, item);
          }),

          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('添加货品'),
          ),

          // Total
          if (_items.any((i) => i.isValid)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('合计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '¥${_calculateTotal().toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],

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

  Widget _buildItemCard(int index, _ItemRow item) {
    // Build unit list (common units + product's default unit if unique)
    final units = <String>[..._commonUnits];
    if (item.product != null && !units.contains(item.product!.unit)) {
      units.insert(0, item.product!.unit);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Product name + unit dropdown
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showProductPicker(index),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '货品',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: item.product != null
                          ? Text(item.product!.name, maxLines: 1, overflow: TextOverflow.ellipsis)
                          : const Text('点击选择货品', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: DropdownButtonFormField<String>(
                    value: units.contains(item.unit) ? item.unit : units.first,
                    decoration: const InputDecoration(
                      labelText: '单位',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    isExpanded: true,
                    items: units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: item.product != null
                        ? (v) {
                            if (v != null) {
                              item.unit = v;
                              _onUnitChanged(index);
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Quantity + Price + subtotal + delete
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: item.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '数量', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: item.priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '单价', border: OutlineInputBorder(), isDense: true, prefixText: '¥'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Spacer(),
                if (item.isValid)
                  Text('¥${((double.tryParse(item.quantityController.text) ?? 0) * (double.tryParse(item.priceController.text) ?? 0)).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                  onPressed: () => _removeItem(index),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  Product? product;
  String unit = '包';
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool get isValid => product != null && quantityController.text.isNotEmpty && priceController.text.isNotEmpty;

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}