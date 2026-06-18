# BBQ记账本 V3 改进计划

> **For agentic workers:** 使用此计划逐步实施。步骤使用 checkbox (`- [ ]`) 语法跟踪。

**Goal:** 实现16项功能改进：切换用户修复、田字排列首页、历史账单搜索、货品管理页面、单位优化、客户随时添加、搜索功能、UI优化、日期默认值、送达时间显示、每日总表、图表金额轴、自动价格、总价显示、Excel导出。

**Architecture:** 沿用现有 Flutter + Supabase + Provider 架构。新增货品管理页面和每日汇总页面，修改现有页面逻辑。新增 `excel` + `path_provider` 依赖用于导出。数据库无需改表。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, Supabase Flutter ^2.3.0, Provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, excel (新), path_provider (新), share_plus (新, 用于打开文件)

**依赖新增:**
- `excel: ^4.0.0` - 创建xlsx文件
- `path_provider: ^2.1.0` - 获取设备存储路径
- `open_file: ^3.3.0` - 打开已保存的文件

---

### Task 1: 添加依赖

**Files:**
- Modify: `/workspace/bbq_ledger/pubspec.yaml`

- [ ] **Step 1: 添加 excel, path_provider, open_file 依赖**

在 `pubspec.yaml` 的 `dependencies` 下添加：
```yaml
  excel: ^4.0.0
  path_provider: ^2.1.0
  open_file: ^3.3.0
```

- [ ] **Step 2: 安装依赖**

```bash
cd /workspace/bbq_ledger && flutter pub get
```

---

### Task 2: 修复切换用户（自动登录bug）

**Files:**
- Modify: `/workspace/bbq_ledger/lib/providers/auth_provider.dart:68-71`
- Modify: `/workspace/bbq_ledger/lib/screens/home_screen.dart:48-58`

**问题:** 登出后 `SharedPreferences` 仍保留 `last_user_id`，LoginScreen 的 `_init()` 检测到后立即自动登录回原来的用户。

- [ ] **Step 1: 修改 `logout()` 清除 last_user_id**

修改 `auth_provider.dart` 的 `logout()` 方法：
```dart
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_user_id');
  }
```

需要在文件顶部添加 import：
```dart
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 2: 修改 HomeScreen AppBar 切换按钮为异步调用**

`home_screen.dart` 第48-58行改为：
```dart
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: '切换账号',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
```

---

### Task 3: 首页田字排列四个窗口

**Files:**
- Modify: `/workspace/bbq_ledger/lib/screens/home_screen.dart:96-151`

- [ ] **Step 1: 将水平滚动改为 2x2 GridView**

删除现有 `SizedBox(height: 100)` 包裹的 `ListView` 整段（第96-151行），替换为：

```dart
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _QuickActionCard(
                      icon: Icons.add_circle,
                      label: '记一笔',
                      color: Colors.green,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NewOrderScreen()),
                        );
                        _refresh();
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.inbox,
                      label: '待认领 (${orderProvider.pendingOrders.length})',
                      color: Colors.orange,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrderPoolScreen()),
                        );
                        _refresh();
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.delivery_dining,
                      label: '我送的 (${orderProvider.myDeliveries.length})',
                      color: Colors.blue,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyDeliveriesScreen()),
                        );
                        _refresh();
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.attach_money,
                      label: '未收款 (${orderProvider.unpaidOrders.length})',
                      color: Colors.red,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UnpaidScreen()),
                        );
                        _refresh();
                      },
                    ),
                  ],
                ),
```

- [ ] **Step 2: 修改 `_QuickActionCard` 宽度自适应**

`_QuickActionCard.build` 中去掉固定 `width: 110`，保留 `margin` 去掉：
```dart
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
```

---

### Task 4: 货品管理页面（增删）

**Files:**
- Create: `/workspace/bbq_ledger/lib/screens/product_management_screen.dart`
- Modify: `/workspace/bbq_ledger/lib/screens/home_screen.dart` (添加入口)

- [ ] **Step 1: 创建货品管理页面**

新建 `lib/screens/product_management_screen.dart`：

```dart
// lib/screens/product_management_screen.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _loading = true;

  final _searchController = TextEditingController();
  List<Product> _filtered = [];

  static const _units = ['包', '件', '条', '箱', '斤', '公斤', '袋', '瓶', '桶'];

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

  Future<void> _add() async {
    final nameController = TextEditingController();
    String selectedUnit = '箱';

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
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withValues(alpha: 0.2),
                              child: Text(product.name[0], style: const TextStyle(color: Colors.orange)),
                            ),
                            title: Text(product.name),
                            subtitle: Text('单位: ${product.unit}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _delete(product),
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
```

- [ ] **Step 2: 首页添加货品管理入口**

在 `home_screen.dart` 的历史账单和月度汇总之间，添加货品管理入口：

```dart
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('货品管理'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductManagementScreen()),
                  ),
                ),
```

并在文件顶部添加 import：
```dart
import 'product_management_screen.dart';
```

---

### Task 5: 新建订单 - 客户随时添加 + 客户货品搜索

**Files:**
- Modify: `/workspace/bbq_ledger/lib/screens/new_order_screen.dart`

- [ ] **Step 1: 添加客户搜索和新增功能**

修改客户选择区域（替换原来的 DropdownButtonFormField，约第224-235行）：

```dart
          // 客户选择（带搜索和新增）
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
```

- [ ] **Step 2: 添加 `_showCustomerPicker` 方法**

在 `_NewOrderScreenState` 中添加：

```dart
  final _customerSearchController = TextEditingController();
  List<Customer> _filteredCustomers = [];

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
                          Navigator.pop(ctx, newCustomer);
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
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '客户名称 *', border: OutlineInputBorder()), autofocus: true),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: '电话', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: '地址', border: OutlineInputBorder())),
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
```

- [ ] **Step 3: 货品选择添加搜索**

类似客户选择，在 `_ItemRow` 的货品 DropdownButtonFormField 旁边添加搜索。修改 `_items` 中每个 item 的货品选择区域（约第299-314行），在 DropdownButtonFormField 的 items 前面加上一个搜索入口：

将 DropdownButtonFormField 的 items 改为支持搜索的下拉：
```dart
                        Expanded(
                          child: InkWell(
                            onTap: () => _showProductPicker(index),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: '货品',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              child: item.product != null
                                  ? Text('${item.product!.name} (${item.product!.unit})', overflow: TextOverflow.ellipsis)
                                  : const Text('点击选择货品', style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        ),
```

- [ ] **Step 4: 添加 `_showProductPicker` 方法**

```dart
  final _productSearchController = TextEditingController();
  List<Product> _filteredProducts = [];

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
```

---

### Task 6: 新建订单 - 送达日期默认今天 + 时间可选 + 总价显示 + UI优化

**Files:**
- Modify: `/workspace/bbq_ledger/lib/screens/new_order_screen.dart`

- [ ] **Step 1: 送达日期默认今天，时间改为可选**

修改 `_initState()`：
```dart
  @override
  void initState() {
    super.initState();
    _deliveryDeadline = DateTime.now();
    _loadData();
  }
```

修改送达日期 ListTile 标题始终显示日期：
```dart
          Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('${_deliveryDeadline!.month}/${_deliveryDeadline!.day}'),
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
```

- [ ] **Step 2: 修改保存逻辑适配可选时间**

修改 `_save()` 中 deliveryDeadline 的构建逻辑：
```dart
      final deliveryDeadline = _deliveryDeadline != null
          ? DateTime(
              _deliveryDeadline!.year,
              _deliveryDeadline!.month,
              _deliveryDeadline!.day,
              _deliveryTime?.hour ?? 23,
              _deliveryTime?.minute ?? 59,
            )
          : null;
```

- [ ] **Step 3: 订单总价实时显示**

在货品明细列表之后、提交按钮之前添加总价显示：
```dart
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
```

添加 `_calculateTotal()` 方法：
```dart
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
```

- [ ] **Step 4: UI优化 - 货品名过长时换行**

修改货品行布局。目前是 Row 中 Expanded(下拉) + 80(数量) + 100(单价) + 删除按钮。改为两行布局：

```dart
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 第一行：货品选择
                        InkWell(
                          onTap: () => _showProductPicker(index),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '货品',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: item.product != null
                                ? Text('${item.product!.name} (${item.product!.unit})',
                                    maxLines: 2, overflow: TextOverflow.ellipsis)
                                : const Text('点击选择货品', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 第二行：数量 + 单价 + 删除
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: item.quantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: '数量', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: item.priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: '单价', border: OutlineInputBorder(), isDense: true, prefixText: '¥'),
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
              }),
```

---

### Task 7: 历史账单搜索功能

**Files:**
- Modify: `/workspace/bbq_ledger/lib/screens/history_screen.dart`
- Modify: `/workspace/bbq_ledger/lib/services/order_service.dart`

- [ ] **Step 1: 在 OrderService 添加搜索方法**

在 `order_service.dart` 末尾添加：
```dart
  Future<List<Order>> searchHistory(String query) async {
    // 先通过 customer name 匹配
    final customerResponse = await _client
        .from('customers')
        .select('id')
        .ilike('name', '%$query%');

    final customerIds = (customerResponse as List).map((c) => c['id'] as String).toList();

    var orderQuery = _client.from('orders').select('''
      *,
      customers:customer_id(name),
      created_by_user:created_by(name),
      claimed_by_user:claimed_by(name)
    ''').eq('status', 'completed');

    if (customerIds.isNotEmpty) {
      orderQuery = orderQuery.inFilter('customer_id', customerIds);
    }

    final response = await orderQuery.order('created_at', ascending: false);

    final orders = (response as List).map((row) {
      return Order(
        id: row['id'],
        customerId: row['customer_id'],
        customerName: row['customers']?['name'] ?? '',
        createdBy: row['created_by'],
        createdByName: row['created_by_user']?['name'] ?? '',
        claimedBy: row['claimed_by'],
        claimedByName: row['claimed_by_user']?['name'] ?? '',
        status: Order.parseStatus(row['status']),
        deliveryDeadline: row['delivery_deadline'] != null
            ? DateTime.parse(row['delivery_deadline'])
            : null,
        totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0,
        isPaid: row['is_paid'] ?? false,
        paidAt: row['paid_at'] != null ? DateTime.parse(row['paid_at']) : null,
        deliveredAt: row['delivered_at'] != null ? DateTime.parse(row['delivered_at']) : null,
        createdAt: DateTime.parse(row['created_at']),
      );
    }).toList();

    // 再通过 order items 的 product name、unit price、quantity 过滤
    if (query.isNotEmpty) {
      final itemResponse = await _client
          .from('order_items')
          .select('order_id, quantity, unit_price, products:product_id(name)')
          .or('quantity.eq.${double.tryParse(query) ?? -1},unit_price.eq.${double.tryParse(query) ?? -1}');

      final matchedOrderIds = (itemResponse as List)
          .where((item) {
            final productName = (item['products']?['name'] ?? '').toString().toLowerCase();
            return productName.contains(query.toLowerCase());
          })
          .map((item) => item['order_id'] as String)
          .toSet();

      orders.retainWhere((o) => customerIds.contains(o.customerId) || matchedOrderIds.contains(o.id));
    }

    return orders;
  }
```

- [ ] **Step 2: 修改 HistoryScreen 添加搜索栏**

在 `history_screen.dart` 中修改：

```dart
class _HistoryScreenState extends State<HistoryScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final orders = await _orderService.getOrders(statuses: ['completed']);
    setState(() => _orders = orders);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _load();
      return;
    }
    final orders = await _orderService.searchHistory(query.trim());
    setState(() => _orders = orders);
  }

  // ... build 方法开头添加搜索框:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史账单')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索客户名称、货品名称、单价、数量...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? const Center(child: Text('暂无历史账单'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return OrderCard(
                          order: order,
                          onAction: () => _showDetail(order),
                          actionLabel: '查看明细',
                          actionColor: Colors.grey,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
```

---

### Task 8: 订单卡片显示送达时间和实际送达时间

**Files:**
- Modify: `/workspace/bbq_ledger/lib/widgets/order_card.dart`

- [ ] **Step 1: 在 OrderCard 中增加 deliveredAt 显示**

修改 `order_card.dart`，在 deliveryDeadline 后面添加 deliveredAt 显示：

```dart
            if (order.deliveryDeadline != null)
              _InfoRow(icon: Icons.access_time, text: '要求送达: ${dateFormat.format(order.deliveryDeadline!)}'),
            if (order.deliveredAt != null)
              _InfoRow(icon: Icons.check_circle_outline, text: '实际送达: ${dateFormat.format(order.deliveredAt!)}'),
```

---

### Task 9: 每日总表汇总

**Files:**
- Create: `/workspace/bbq_ledger/lib/screens/daily_report_screen.dart`
- Modify: `/workspace/bbq_ledger/lib/screens/home_screen.dart` (添加入口)
- Modify: `/workspace/bbq_ledger/lib/services/report_service.dart`

- [ ] **Step 1: 在 ReportService 添加每日报告方法**

在 `report_service.dart` 中添加类和方法：

```dart
class DailyReport {
  final DateTime date;
  final List<DailyCustomerSummary> customerSummaries;
  final List<ProductSalesSummary> productSummaries;
  final double totalAmount;
  final int orderCount;

  const DailyReport({
    required this.date,
    required this.customerSummaries,
    required this.productSummaries,
    required this.totalAmount,
    required this.orderCount,
  });
}

class DailyCustomerSummary {
  final String customerId;
  final String customerName;
  final double totalAmount;
  final int orderCount;

  const DailyCustomerSummary({
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.orderCount,
  });
}
```

在 `ReportService` 类中添加方法：
```dart
  Future<DailyReport> getDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('orders')
        .select('''
          *,
          customers:customer_id(name)
        ''')
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String())
        .order('created_at', ascending: false);

    final orders = response as List;
    final orderIds = orders.map((o) => o['id'] as String).toList();
    final totalAmount = orders.fold<double>(0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));

    // Customer summary
    final Map<String, DailyCustomerSummary> customerMap = {};
    for (final o in orders) {
      final cid = o['customer_id'] as String;
      final cname = o['customers']?['name'] ?? '';
      final amt = (o['total_amount'] as num?)?.toDouble() ?? 0;
      if (customerMap.containsKey(cid)) {
        final existing = customerMap[cid]!;
        customerMap[cid] = DailyCustomerSummary(
          customerId: cid, customerName: cname,
          totalAmount: existing.totalAmount + amt,
          orderCount: existing.orderCount + 1,
        );
      } else {
        customerMap[cid] = DailyCustomerSummary(
          customerId: cid, customerName: cname,
          totalAmount: amt, orderCount: 1,
        );
      }
    }

    // Product summary (from order_items)
    List<ProductSalesSummary> productSummaries = [];
    if (orderIds.isNotEmpty) {
      final itemResponse = await _client
          .from('order_items')
          .select('''
            product_id,
            quantity,
            unit_price,
            subtotal,
            products:product_id(name, unit)
          ''')
          .inFilter('order_id', orderIds);

      final Map<String, ProductSalesSummary> productMap = {};
      for (final item in (itemResponse as List)) {
        final pid = item['product_id'] as String;
        final name = item['products']?['name'] ?? '';
        final unit = item['products']?['unit'] ?? '';
        final qty = (item['quantity'] as num).toDouble();
        final subtotalAmt = (item['subtotal'] as num).toDouble();

        if (productMap.containsKey(pid)) {
          final e = productMap[pid]!;
          productMap[pid] = ProductSalesSummary(
            productId: pid, productName: name, productUnit: unit,
            totalQuantity: e.totalQuantity + qty,
            totalAmount: e.totalAmount + subtotalAmt,
          );
        } else {
          productMap[pid] = ProductSalesSummary(
            productId: pid, productName: name, productUnit: unit,
            totalQuantity: qty, totalAmount: subtotalAmt,
          );
        }
      }
      productSummaries = productMap.values.toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }

    return DailyReport(
      date: date,
      customerSummaries: customerMap.values.toList(),
      productSummaries: productSummaries,
      totalAmount: totalAmount,
      orderCount: orders.length,
    );
  }
```

- [ ] **Step 2: 创建每日总表页面**

新建 `lib/screens/daily_report_screen.dart`：

```dart
// lib/screens/daily_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/report_service.dart';
import '../services/export_service.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final ReportService _reportService = ReportService();
  final ExportService _exportService = ExportService();
  DailyReport? _report;
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _report = await _reportService.getDailyReport(_selectedDate);
    setState(() => _loading = false);
  }

  Future<void> _export() async {
    if (_report == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = await _exportService.exportDailyReport(_report!, dir.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到: $path'), action: SnackBarAction(label: '打开', onPressed: () => OpenFile.open(path))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateStr = DateFormat('yyyy年MM月dd日').format(_selectedDate);
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: Text('每日总表'),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), tooltip: '导出Excel', onPressed: _export),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('暂无数据'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 日期切换
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                              _load();
                            },
                          ),
                          Text(dateStr, style: Theme.of(context).textTheme.titleLarge),
                          if (!isToday)
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                                _load();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 汇总卡片
                      Row(
                        children: [
                          _SummaryCard(title: '当日营业额', value: '¥${currencyFormat.format(_report!.totalAmount)}', color: Colors.orange),
                          const SizedBox(width: 12),
                          _SummaryCard(title: '订单数', value: '${_report!.orderCount}笔', color: Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 货品图表（数轴为金额）
                      if (_report!.productSummaries.isNotEmpty) ...[
                        const Text('货品销售额', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _report!.productSummaries
                                  .map((s) => s.totalAmount)
                                  .reduce((a, b) => a > b ? a : b) * 1.3,
                              barGroups: _report!.productSummaries.take(10).map((s) {
                                final idx = _report!.productSummaries.indexOf(s);
                                return BarChartGroupData(
                                  x: idx,
                                  barRods: [
                                    BarChartRodData(
                                      toY: s.totalAmount,
                                      color: Colors.orange,
                                      width: 20,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < _report!.productSummaries.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _report!.productSummaries[index].productName,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 客户汇总
                      if (_report!.customerSummaries.isNotEmpty) ...[
                        const Text('客户汇总', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._report!.customerSummaries.map((c) => Card(
                          child: ListTile(
                            title: Text(c.customerName),
                            subtitle: Text('${c.orderCount}笔订单'),
                            trailing: Text('¥${currencyFormat.format(c.totalAmount)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                          ),
                        )),
                      ],

                      // 货品明细
                      if (_report!.productSummaries.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('货品明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._report!.productSummaries.map((s) => ListTile(
                          title: Text(s.productName),
                          subtitle: Text('销量: ${s.totalQuantity}${s.productUnit}'),
                          trailing: Text('¥${currencyFormat.format(s.totalAmount)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        )),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 首页添加每日总表入口**

在 `home_screen.dart` 的月度汇总报表之前添加：
```dart
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('每日总表'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyReportScreen()),
                  ),
                ),
```

添加 import：
```dart
import 'daily_report_screen.dart';
```

---

### Task 10: 月度报表数轴改为金额 + Excel导出

**Files:**
- Modify: `/workspace/bbq_ledger/lib/screens/monthly_report_screen.dart`

- [ ] **Step 1: 修改图表数轴为金额**

修改 `monthly_report_screen.dart` 中图表部分，将 maxY 从 `totalQuantity` 改为 `totalAmount`，将 `toY` 从 `totalQuantity` 改为 `totalAmount`：

```dart
                          maxY: reportProvider.report!.productSummaries
                              .map((s) => s.totalAmount)
                              .reduce((a, b) => a > b ? a : b) * 1.3,
                          barGroups: reportProvider.report!.productSummaries.take(10).map((s) {
                            final idx = reportProvider.report!.productSummaries.indexOf(s);
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: s.totalAmount,
```

- [ ] **Step 2: 月度报表添加导出Excel按钮**

在 `monthly_report_screen.dart` 导入：
```dart
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/export_service.dart';
```

添加成员：
```dart
  final ExportService _exportService = ExportService();
```

添加导出方法：
```dart
  Future<void> _export() async {
    final report = context.read<ReportProvider>().report;
    if (report == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = await _exportService.exportMonthlyReport(report!, dir.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到: $path'), action: SnackBarAction(label: '打开', onPressed: () => OpenFile.open(path))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }
```

在 AppBar 的 actions 中添加导出按钮：
```dart
      appBar: AppBar(
        title: const Text('月度汇总报表'),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), tooltip: '导出Excel', onPressed: _export),
        ],
      ),
```

---

### Task 11: Excel导出服务

**Files:**
- Create: `/workspace/bbq_ledger/lib/services/export_service.dart`

- [ ] **Step 1: 创建导出服务**

新建 `lib/services/export_service.dart`：

```dart
// lib/services/export_service.dart
import 'package:excel/excel.dart';
import 'dart:io';
import 'report_service.dart';
import 'package:intl/intl.dart';

class ExportService {
  final _currencyFormat = NumberFormat('#,##0.00');

  Future<String> exportDailyReport(DailyReport report, String dirPath) async {
    final excel = Excel.createExcel();
    final sheet = excel['每日总表'];

    final dateStr = DateFormat('yyyy-MM-dd').format(report.date);

    // Header
    sheet.appendRow([
      TextCellValue('每日总表'),
    ]);
    sheet.appendRow([
      TextCellValue('日期: $dateStr'),
    ]);
    sheet.appendRow([
      TextCellValue('总营业额: ¥${_currencyFormat.format(report.totalAmount)}   订单数: ${report.orderCount}笔'),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('客户汇总')]);
    sheet.appendRow([TextCellValue('客户名称'), TextCellValue('订单数'), TextCellValue('金额')]);

    for (final c in report.customerSummaries) {
      sheet.appendRow([
        TextCellValue(c.customerName),
        IntCellValue(c.orderCount),
        TextCellValue('¥${_currencyFormat.format(c.totalAmount)}'),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('货品明细')]);
    sheet.appendRow([TextCellValue('货品'), TextCellValue('销量'), TextCellValue('单位'), TextCellValue('金额')]);

    for (final p in report.productSummaries) {
      sheet.appendRow([
        TextCellValue(p.productName),
        TextCellValue(p.totalQuantity.toString()),
        TextCellValue(p.productUnit),
        TextCellValue('¥${_currencyFormat.format(p.totalAmount)}'),
      ]);
    }

    final filePath = '$dirPath/每日总表_$dateStr.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    return filePath;
  }

  Future<String> exportMonthlyReport(MonthlyReport report, String dirPath) async {
    final excel = Excel.createExcel();
    final sheet = excel['月度汇总'];

    final dateStr = '${report.year}-${report.month.toString().padLeft(2, '0')}';

    sheet.appendRow([TextCellValue('月度汇总报表')]);
    sheet.appendRow([TextCellValue('月份: $dateStr')]);
    sheet.appendRow([TextCellValue('总营业额: ¥${_currencyFormat.format(report.totalRevenue)}   订单数: ${report.orderCount}笔')]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('货品'), TextCellValue('销量'), TextCellValue('单位'), TextCellValue('金额')]);

    for (final p in report.productSummaries) {
      sheet.appendRow([
        TextCellValue(p.productName),
        TextCellValue(p.totalQuantity.toString()),
        TextCellValue(p.productUnit),
        TextCellValue('¥${_currencyFormat.format(p.totalAmount)}'),
      ]);
    }

    final filePath = '$dirPath/月度汇总_$dateStr.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    return filePath;
  }
}
```

---

### Task 12: 验证构建

**Files:** 无

- [ ] **Step 1: 构建APK验证所有代码编译通过**

```bash
cd /workspace/bbq_ledger && flutter clean && ANDROID_HOME=/opt/android flutter build apk --release --split-per-abi
```

- [ ] **Step 2: 上传APK到Supabase Storage**

```bash
# 使用 curl 上传三个 APK 文件到 apk bucket（覆盖旧版本）
```

---

### 修改文件汇总

| 文件 | 操作 | 涉及功能 |
|------|------|---------|
| `pubspec.yaml` | 修改 | 添加 excel, path_provider, open_file |
| `lib/providers/auth_provider.dart` | 修改 | Task 2: 清除 last_user_id |
| `lib/screens/home_screen.dart` | 修改 | Task 2(切换按钮), Task 3(田字排列), Task 4(货品管理入口), Task 9(每日总表入口) |
| `lib/screens/new_order_screen.dart` | 修改 | Task 5(搜索/新增客户+货品), Task 6(默认日期+总价+UI) |
| `lib/screens/product_management_screen.dart` | 新建 | Task 4: 货品管理页面 |
| `lib/screens/history_screen.dart` | 修改 | Task 7: 历史账单搜索 |
| `lib/screens/daily_report_screen.dart` | 新建 | Task 9: 每日总表 |
| `lib/screens/monthly_report_screen.dart` | 修改 | Task 10: 图表金额+导出 |
| `lib/services/order_service.dart` | 修改 | Task 7: 搜索接口 |
| `lib/services/report_service.dart` | 修改 | Task 9: 每日报告接口 |
| `lib/services/export_service.dart` | 新建 | Task 11: Excel导出 |
| `lib/widgets/order_card.dart` | 修改 | Task 8: 送达时间显示 |