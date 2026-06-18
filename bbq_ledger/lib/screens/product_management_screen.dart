import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductService _productService = ProductService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  List<Product> _products = [];
  bool _loading = true;

  final _searchController = TextEditingController();
  List<Product> _filtered = [];

  // Per-product expanded state + customer price data
  final Set<String> _expandedProductIds = {};
  final Map<String, List<({String customerId, String customerName, String unit, double price})>> _priceData = {};
  final Map<String, String> _priceCustomerSearch = {};
  bool _priceLoading = false;

  static const _units = ['包', '件', '条'];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _products : _products.where((p) => p.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await _productService.getAll();
    setState(() {
      _products = products;
      _filtered = List.from(products);
      _loading = false;
    });
  }

  Future<void> _togglePriceTable(Product product) async {
    final pid = product.id;
    if (_expandedProductIds.contains(pid)) {
      setState(() {
        _expandedProductIds.remove(pid);
      });
      return;
    }

    // Fetch price data if not already loaded
    if (!_priceData.containsKey(pid)) {
      setState(() => _priceLoading = true);
      final prices = await _productService.getCustomerPrices(pid);
      _priceData[pid] = prices;
      _priceLoading = false;
    }

    setState(() {
      _expandedProductIds.add(pid);
      _priceCustomerSearch.remove(pid);
    });
  }

  Future<void> _add() async {
    final nameController = TextEditingController();
    String selectedUnit = '包';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加新货品'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '货品名称', border: OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(labelText: '单位', border: OutlineInputBorder()),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setDialogState(() => selectedUnit = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, {'name': nameController.text.trim(), 'unit': selectedUnit});
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _productService.create(result['name']!, result['unit']!);
      await _load();
    }
  }

  Future<void> _delete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${product.name}」吗？\n已有订单中的记录不会受影响。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _productService.delete(product.id);
      _priceData.remove(product.id);
      _expandedProductIds.remove(product.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除：${product.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('货品管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索货品...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('暂无货品'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final product = _filtered[index];
                          final isExpanded = _expandedProductIds.contains(product.id);
                          final prices = _priceData[product.id] ?? [];
                          final customerSearch = _priceCustomerSearch[product.id] ?? '';
                          final filteredPrices = customerSearch.isEmpty
                              ? prices
                              : prices.where((p) => p.customerName.toLowerCase().contains(customerSearch.toLowerCase())).toList();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                                    child: Text(product.name[0], style: const TextStyle(color: Colors.orange)),
                                  ),
                                  title: Text(product.name),
                                  subtitle: Text('单位: ${product.unit}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (prices.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Chip(
                                            label: Text('${prices.length}个客户', style: const TextStyle(fontSize: 11)),
                                            backgroundColor: Colors.blue.shade50,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      IconButton(
                                        icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.blue),
                                        onPressed: () => _togglePriceTable(product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _delete(product),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isExpanded) ...[
                                  const Divider(height: 1),
                                  // Customer search for this product
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: '搜索客户...',
                                        hintStyle: const TextStyle(fontSize: 13),
                                        prefixIcon: const Icon(Icons.search, size: 18),
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                      onChanged: (v) {
                                        setState(() {
                                          _priceCustomerSearch[product.id] = v;
                                        });
                                      },
                                    ),
                                  ),
                                  // Price table header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                    child: Row(
                                      children: [
                                        const Expanded(flex: 3, child: Text('客户', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                                        Expanded(flex: 2, child: Text('单价', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.right)),
                                      ],
                                    ),
                                  ),
                                  // Price rows
                                  if (_priceLoading)
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                    )
                                  else if (filteredPrices.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Text('暂无价格记录', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    )
                                  else
                                    ...filteredPrices.map((p) => Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text(p.customerName, style: const TextStyle(fontSize: 13))),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '¥${_currencyFormat.format(p.price)}',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}