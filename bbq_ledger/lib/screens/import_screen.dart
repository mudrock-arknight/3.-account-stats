// lib/screens/import_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../models/order_item.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? _filePath;
  String? _fileName;
  List<List<String>> _rows = [];
  List<String> _headers = [];
  bool _loading = false;

  // Column mapping
  int? _customerCol;
  int? _productCol;
  int? _quantityCol;
  int? _unitPriceCol;
  int? _amountCol;
  int? _dateCol;
  bool _hasHeader = true;
  int _skipRows = 0;

  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _filePath = result.files.single.path;
      _fileName = result.files.single.name;
      _loading = true;
    });

    await _parseExcel();
  }

  Future<void> _parseExcel() async {
    try {
      final file = File(_filePath!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;

      final rows = <List<String>>[];
      for (final row in sheet.rows) {
        rows.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
      }

      setState(() {
        _rows = rows;
        _headers = rows.isNotEmpty ? rows.first : [];
        _customerCol = null;
        _productCol = null;
        _quantityCol = null;
        _unitPriceCol = null;
        _amountCol = null;
        _dateCol = null;
        _loading = false;
      });

      // Auto-detect columns
      _autoDetect();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('解析失败: $e')));
      }
    }
  }

  void _autoDetect() {
    if (_headers.isEmpty) return;
    for (int i = 0; i < _headers.length; i++) {
      final h = _headers[i].toLowerCase().trim();
      if (h.contains('客户') || h.contains('customer') || h.contains('名称') && !h.contains('货')) {
        _customerCol = i;
      } else if (h.contains('货品') || h.contains('产品') || h.contains('product') || h.contains('商品') || h.contains('货物')) {
        _productCol = i;
      } else if (h.contains('数量') || h.contains('quantity') || h.contains('qty')) {
        _quantityCol = i;
      } else if (h.contains('单价') || h.contains('price') || h.contains('unit')) {
        _unitPriceCol = i;
      } else if (h.contains('金额') || h.contains('amount') || h.contains('总价') || h.contains('小计')) {
        _amountCol = i;
      } else if (h.contains('日期') || h.contains('date') || h.contains('时间') || h.contains('time')) {
        _dateCol = i;
      }
    }
    _hasHeader = _customerCol != null || _productCol != null || _quantityCol != null;
    setState(() {});
  }

  List<List<String>> get _dataRows {
    final start = _hasHeader ? 1 + _skipRows : _skipRows;
    if (start >= _rows.length) return [];
    return _rows.sublist(start);
  }

  Future<void> _import() async {
    if (_customerCol == null || _productCol == null || _quantityCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少映射客户、货品、数量三列')),
      );
      return;
    }

    setState(() => _loading = true);
    final user = context.read<AuthProvider>().currentUser!;
    int success = 0;
    int failed = 0;

    try {
      // Group rows by customer + date
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in _dataRows) {
        if (row.length <= _customerCol! || row.length <= _productCol! || row.length <= _quantityCol!) continue;
        final customerName = _getCell(row, _customerCol!).trim();
        final productName = _getCell(row, _productCol!).trim();
        final qtyStr = _getCell(row, _quantityCol!).trim();
        if (customerName.isEmpty || productName.isEmpty || qtyStr.isEmpty) continue;
        final qty = double.tryParse(qtyStr) ?? 0;
        if (qty <= 0) continue;
        final priceStr = _unitPriceCol != null ? _getCell(row, _unitPriceCol!).trim() : '0';
        final unitPrice = double.tryParse(priceStr) ?? 0;
        final dateStr = _dateCol != null ? _getCell(row, _dateCol!).trim() : '';
        final key = '$customerName|$dateStr';
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add({
          'product': productName,
          'quantity': qty,
          'unitPrice': unitPrice,
        });
      }

      for (final entry in grouped.entries) {
        try {
          final parts = entry.key.split('|');
          final customerName = parts[0];
          final dateStr = parts.length > 1 ? parts[1] : '';

          // Find or create customer
          final customers = await _customerService.search(customerName);
          String customerId;
          if (customers.any((c) => c.name == customerName)) {
            customerId = customers.firstWhere((c) => c.name == customerName).id;
          } else {
            final c = await _customerService.create(customerName);
            customerId = c.id;
          }

          // Create order items
          final items = <OrderItem>[];
          for (final item in entry.value) {
            final products = await _productService.search(item['product'] as String);
            String productId;
            String productUnit;
            if (products.any((p) => p.name == item['product'])) {
              final p = products.firstWhere((p) => p.name == item['product']);
              productId = p.id;
              productUnit = p.unit;
            } else {
              final p = await _productService.create(item['product'] as String, '箱');
              productId = p.id;
              productUnit = '箱';
            }
            items.add(OrderItem(
              productId: productId,
              productName: item['product'] as String,
              productUnit: productUnit,
              quantity: (item['quantity'] as num).toDouble(),
              unitPrice: (item['unitPrice'] as num).toDouble(),
            ));
          }

          // Create order
          await _orderService.create(
            customerId: customerId,
            createdBy: user.id,
            items: items,
          );
          success++;
        } catch (_) {
          failed++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入完成：成功 $success 单，失败 $failed 单'),
            backgroundColor: success > 0 ? Colors.green : Colors.red,
          ),
        );
        if (success > 0) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getCell(List<String> row, int col) {
    if (col >= row.length) return '';
    return row[col];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入历史账单')),
      body: _filePath == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('选择 Excel 文件导入历史账单'),
                  const SizedBox(height: 8),
                  const Text('支持 .xlsx / .xls 格式', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.file_open),
                    label: const Text('选择文件'),
                  ),
                ],
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // File info
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.orange.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.description, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_fileName ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                          TextButton(onPressed: _pickFile, child: const Text('换文件')),
                        ],
                      ),
                    ),

                    // Settings
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Text('首行是表头'),
                          Switch(
                            value: _hasHeader,
                            onChanged: (v) => setState(() => _hasHeader = v),
                          ),
                          const SizedBox(width: 16),
                          Text('跳过行: $_skipRows'),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, size: 18),
                            onPressed: _skipRows > 0 ? () => setState(() => _skipRows--) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 18),
                            onPressed: () => setState(() => _skipRows++),
                          ),
                        ],
                      ),
                    ),

                    // Column mapping
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _MappingChip(label: '客户', colIdx: _customerCol, onSelected: (v) => setState(() => _customerCol = v)),
                          const SizedBox(width: 8),
                          _MappingChip(label: '货品', colIdx: _productCol, onSelected: (v) => setState(() => _productCol = v)),
                          const SizedBox(width: 8),
                          _MappingChip(label: '数量', colIdx: _quantityCol, onSelected: (v) => setState(() => _quantityCol = v)),
                          const SizedBox(width: 8),
                          _MappingChip(label: '单价', colIdx: _unitPriceCol, onSelected: (v) => setState(() => _unitPriceCol = v)),
                          const SizedBox(width: 8),
                          _MappingChip(label: '金额', colIdx: _amountCol, onSelected: (v) => setState(() => _amountCol = v)),
                          const SizedBox(width: 8),
                          _MappingChip(label: '日期', colIdx: _dateCol, onSelected: (v) => setState(() => _dateCol = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Preview
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('预览（前10行）', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                            columnSpacing: 16,
                            columns: List.generate(_headers.length, (i) => DataColumn(label: Text('列$i\n${_headers[i]}', style: const TextStyle(fontSize: 11)))),
                            rows: _dataRows.take(10).map((row) {
                              return DataRow(
                                cells: List.generate(row.length < _headers.length ? _headers.length : row.length,
                                  (i) => DataCell(Text(i < row.length ? row[i] : '', style: const TextStyle(fontSize: 11))),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    // Import button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _customerCol != null && _productCol != null ? _import : null,
                          child: const Text('开始导入', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _MappingChip extends StatefulWidget {
  final String label;
  final int? colIdx;
  final ValueChanged<int?> onSelected;

  const _MappingChip({required this.label, required this.colIdx, required this.onSelected});

  @override
  State<_MappingChip> createState() => _MappingChipState();
}

class _MappingChipState extends State<_MappingChip> {
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(widget.colIdx != null ? '${widget.label}:列${widget.colIdx}' : widget.label),
      selected: widget.colIdx != null,
      selectedColor: widget.label == '客户' ? Colors.green.shade100 : widget.label == '货品' ? Colors.orange.shade100 : Colors.blue.shade100,
      onSelected: (selected) {
        if (selected) {
          _showColumnPicker();
        } else {
          widget.onSelected(null);
        }
      },
    );
  }

  void _showColumnPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('选择「${widget.label}」对应的列', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...List.generate(20, (i) {
            return ListTile(
              title: Text('列 $i'),
              trailing: widget.colIdx == i ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                widget.onSelected(i);
                Navigator.pop(ctx);
              },
            );
          }),
        ],
      ),
    );
  }
}