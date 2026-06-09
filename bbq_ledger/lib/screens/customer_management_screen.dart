// lib/screens/customer_management_screen.dart
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'location_picker_screen.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  List<Customer> _filtered = [];

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
      _filtered = q.isEmpty ? _customers : _customers.where((c) => c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final customers = await _customerService.getAll();
    setState(() {
      _customers = customers;
      _filtered = List.from(customers);
      _loading = false;
    });
  }

  Future<void> _addOrEdit({Customer? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    double? lat = existing?.latitude;
    double? lng = existing?.longitude;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? '编辑客户' : '添加新客户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '客户名称 *', border: OutlineInputBorder()),
                  autofocus: existing == null,
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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await Navigator.push<Map<String, double>>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => LocationPickerScreen(
                          initialLat: lat,
                          initialLng: lng,
                          title: '${nameController.text.isNotEmpty ? nameController.text : "客户"}的位置',
                        ),
                      ),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        lat = picked['lat'];
                        lng = picked['lng'];
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(lat != null ? '已设置位置 ✓' : '选择地址位置',
                            style: const TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, {'delete': true}),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'address': addressController.text.trim(),
                  'lat': lat,
                  'lng': lng,
                });
              },
              child: Text(existing != null ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    if (result['delete'] == true && existing != null) {
      await _customerService.delete(existing.id);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除：${existing.name}')));
      return;
    }

    if (existing != null) {
      final updated = existing.copyWith(
        name: result['name'] as String,
        phone: result['phone'] as String,
        address: result['address'] as String,
        latitude: result['lat'] as double?,
        longitude: result['lng'] as double?,
        clearLocation: result['lat'] == null,
      );
      await _customerService.update(updated);
    } else {
      await _customerService.create(
        result['name'] as String,
        phone: result['phone'] as String,
        address: result['address'] as String,
        latitude: result['lat'] as double?,
        longitude: result['lng'] as double?,
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('客户管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索客户...',
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
                    ? const Center(child: Text('暂无客户'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final c = _filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withValues(alpha: 0.2),
                              child: Text(c.name[0], style: const TextStyle(color: Colors.orange)),
                            ),
                            title: Text(c.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (c.phone.isNotEmpty) Text(c.phone),
                                if (c.address.isNotEmpty) Text(c.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (c.latitude != null)
                                  const Icon(Icons.location_on, color: Colors.green, size: 18),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _addOrEdit(existing: c),
                                ),
                              ],
                            ),
                            onTap: () => _addOrEdit(existing: c),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}