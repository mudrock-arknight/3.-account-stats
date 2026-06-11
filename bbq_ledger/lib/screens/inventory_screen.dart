import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ProductService _productService = ProductService();
  final DateFormat _dateFormat = DateFormat('MM/dd HH:mm');

  List<ProductStock> _stocks = [];
  List<InventoryRecord> _records = [];
  List<Product> _products = [];
  bool _loading = true;
  String? _filterProductId;
  String? _filterType; // 'in', 'out', null = all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stocks = await _inventoryService.getStocks();
    final records = await _inventoryService.getRecords(
      productId: _filterProductId,
      type: _filterType,
    );
    final products = await _productService.getAll();
    setState(() {
      _stocks = stocks;
      _records = records;
      _products = products;
      _loading = false;
    });
  }

  Future<void> _addRecord(String type) async {
    Product? selectedProduct;
    final qtyController = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(type == 'in' ? '进货' : '出货'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                value: selectedProduct,
                decoration: const InputDecoration(labelText: '货品', border: OutlineInputBorder()),
                items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (v) => setDialogState(() => selectedProduct = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                decoration: InputDecoration(
                  labelText: '数量（${selectedProduct?.unit ?? ''}）',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: '备注（可选）', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (selectedProduct == null || qtyController.text.isEmpty) return;
                final qty = double.tryParse(qtyController.text);
                if (qty == null || qty <= 0) return;
                Navigator.pop(ctx, {
                  'product_id': selectedProduct!.id,
                  'quantity': qty,
                  'note': noteController.text.trim(),
                });
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      if (type == 'in') {
        await _inventoryService.addStockIn(
          productId: result['product_id'],
          quantity: result['quantity'],
          note: result['note'],
        );
      } else {
        await _inventoryService.addStockOut(
          productId: result['product_id'],
          quantity: result['quantity'],
          note: result['note'],
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == "in" ? "进货" : "出货"}记录已保存'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('库存管理')),
      body: Column(
        children: [
          // Stock summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(label: '货品种类', value: '${_stocks.length}', color: Colors.blue),
                _StatChip(
                  label: '有库存',
                  value: '${_stocks.where((s) => s.current > 0).length}',
                  color: Colors.green,
                ),
                _StatChip(
                  label: '缺货',
                  value: '${_stocks.where((s) => s.current <= 0).length}',
                  color: Colors.red,
                ),
              ],
            ),
          ),

          // Filter chips for history
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: '全部记录',
                    selected: _filterType == null && _filterProductId == null,
                    onSelected: () => setState(() { _filterType = null; _filterProductId = null; _load(); }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '进货',
                    selected: _filterType == 'in',
                    onSelected: () => setState(() { _filterType = _filterType == 'in' ? null : 'in'; _load(); }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '出货',
                    selected: _filterType == 'out',
                    onSelected: () => setState(() { _filterType = _filterType == 'out' ? null : 'out'; _load(); }),
                  ),
                  // Product filter dropdown
                  const SizedBox(width: 12),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _filterProductId,
                        hint: const Text('按货品', style: TextStyle(fontSize: 13)),
                        isDense: true,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('全部货品', style: TextStyle(fontSize: 13))),
                          ..._products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 13)))),
                        ],
                        onChanged: (v) {
                          setState(() => _filterProductId = v);
                          _load();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stocks table header
          if (!_loading && _stocks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: Text('货品', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                  const Expanded(flex: 1, child: Text('当前', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center)),
                ],
              ),
            ),

          // Stock rows (compact)
          if (!_loading && _stocks.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _stocks.length,
                itemBuilder: (_, i) {
                  final s = _stocks[i];
                  final isLow = s.current <= 0;
                  return InkWell(
                    onTap: () {
                      setState(() => _filterProductId = s.productId);
                      _load();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${s.productName} (${s.productUnit})',
                              style: TextStyle(fontSize: 13, color: isLow ? Colors.red : null),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              s.current.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isLow ? Colors.red : Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const Divider(),

          // History header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('出入库记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          ),

          // History list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const Center(child: Text('暂无记录'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _records.length,
                          itemBuilder: (_, i) {
                            final r = _records[i];
                            final isIn = r.type == 'in';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      isIn ? Icons.add_circle : Icons.remove_circle,
                                      color: isIn ? Colors.green : Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${r.productName} (${r.productUnit})',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          Text(
                                            _dateFormat.format(r.createdAt),
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isIn ? "+" : "-"}${r.quantity}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isIn ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        if (r.note.isNotEmpty)
                                          Text(r.note, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'stock_out',
            onPressed: () => _addRecord('out'),
            backgroundColor: Colors.red,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'stock_in',
            onPressed: () => _addRecord('in'),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}