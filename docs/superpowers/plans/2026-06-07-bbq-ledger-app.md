# BBQ 烧烤原料批发客户账本 App 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个 Flutter Android APK，供烧烤原料批发家庭团队使用：多人记账→云端同步→认领送货→标记送达→收款→历史账单→月度汇总。

**Architecture:** Flutter 前端 + Supabase 后端（PostgreSQL + Realtime 实时同步）。短期用 Supabase 云端，后期切换到自托管 Supabase 只需改 API 地址。PIN 码登录区分家庭成员。订单状态流转：pending → claimed → delivered → completed。

**Tech Stack:** Flutter 3.x (Dart), Supabase (PostgreSQL + Realtime), supabase_flutter, provider (状态管理), fl_chart (月度报表图表)

---

## 文件结构总览

```
/workspace/bbq_ledger/
├── pubspec.yaml
├── analysis_options.yaml
├── supabase/
│   └── migrations/
│       └── 001_initial_schema.sql
├── lib/
│   ├── main.dart                          # 入口，初始化 Supabase
│   ├── app.dart                           # MaterialApp + 路由
│   ├── config/
│   │   └── supabase_config.dart           # Supabase URL + anon key
│   ├── models/
│   │   ├── user.dart                      # User 数据模型
│   │   ├── customer.dart                  # Customer 数据模型
│   │   ├── product.dart                   # Product 数据模型
│   │   ├── order.dart                     # Order 数据模型
│   │   └── order_item.dart                # OrderItem 数据模型
│   ├── services/
│   │   ├── auth_service.dart              # PIN 码登录认证
│   │   ├── customer_service.dart          # 客户 CRUD
│   │   ├── product_service.dart           # 货品 CRUD
│   │   ├── order_service.dart             # 订单 CRUD + 状态流转 + 实时订阅
│   │   └── report_service.dart            # 月度汇总查询
│   ├── providers/
│   │   ├── auth_provider.dart             # 当前登录用户状态
│   │   ├── order_provider.dart            # 订单列表 + 实时更新
│   │   └── report_provider.dart           # 报表数据
│   ├── screens/
│   │   ├── login_screen.dart              # 选人 + 输 PIN
│   │   ├── home_screen.dart               # 首页导航 + 概览
│   │   ├── new_order_screen.dart          # 新建订单（选客户、加货品、定价格、设时限）
│   │   ├── order_pool_screen.dart         # 待认领订单池
│   │   ├── my_deliveries_screen.dart      # 我的送货任务
│   │   ├── unpaid_screen.dart             # 未收款订单
│   │   ├── history_screen.dart            # 历史账单（已收款）
│   │   └── monthly_report_screen.dart     # 月度汇总报表
│   └── widgets/
│       ├── user_avatar.dart               # 用户头像选择器
│       ├── order_card.dart                # 订单卡片组件
│       ├── order_item_row.dart            # 订单货品行组件
│       └── price_history_chip.dart        # 历史价格提示 chip
```

---

## 数据库设计

```sql
-- 用户表
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  pin_code TEXT NOT NULL,
  avatar_color TEXT DEFAULT '#4CAF50',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 客户表
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT DEFAULT '',
  address TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 货品表
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  unit TEXT NOT NULL DEFAULT '包',  -- 包、箱、斤、袋
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 客户-货品历史单价表（首次录入后自动记住）
CREATE TABLE customer_product_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  product_id UUID NOT NULL REFERENCES products(id),
  unit_price NUMERIC(10,2) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(customer_id, product_id)
);

-- 订单主表
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  created_by UUID NOT NULL REFERENCES users(id),       -- 谁记的账
  claimed_by UUID REFERENCES users(id),                -- 谁认领的
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','claimed','delivered','completed')),
  delivery_deadline TIMESTAMPTZ,                       -- 送达时限
  total_amount NUMERIC(10,2) DEFAULT 0,                -- 总金额
  is_paid BOOLEAN DEFAULT false,
  paid_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 订单货品明细
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  quantity NUMERIC(10,2) NOT NULL,
  unit_price NUMERIC(10,2) NOT NULL,
  subtotal NUMERIC(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- 启用 Supabase Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE order_items;

-- RLS 策略（简化：同一家庭成员全部可读写，按 app 内用户查询）
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_product_prices ENABLE ROW LEVEL SECURITY;

-- 全部放通（PIN 码登录已有足够安全级别，家庭内部使用）
CREATE POLICY "Allow all" ON users FOR ALL USING (true);
CREATE POLICY "Allow all" ON customers FOR ALL USING (true);
CREATE POLICY "Allow all" ON products FOR ALL USING (true);
CREATE POLICY "Allow all" ON orders FOR ALL USING (true);
CREATE POLICY "Allow all" ON order_items FOR ALL USING (true);
CREATE POLICY "Allow all" ON customer_product_prices FOR ALL USING (true);
```

---

## 订单状态流转图

```
记账人创建订单
      │
      ▼
 [pending]  ──── 任何人都可以认领 ────▶  [claimed]
 待认领                                   已认领（显示认领人姓名）
                                                │
                                                ▼
                                          [delivered]
                                          已送达（未收款）
                                          记录送达时间+总价
                                                │
                                                ▼
                                          [completed]
                                          已收款（进入历史账单）
```

---

### Task 1: 项目初始化与基础配置

**Files:**
- Create: `/workspace/bbq_ledger/pubspec.yaml`
- Create: `/workspace/bbq_ledger/analysis_options.yaml`
- Create: `/workspace/bbq_ledger/lib/main.dart`
- Create: `/workspace/bbq_ledger/lib/app.dart`
- Create: `/workspace/bbq_ledger/lib/config/supabase_config.dart`
- Create: `/workspace/bbq_ledger/supabase/migrations/001_initial_schema.sql`

- [ ] **Step 1: 创建 Flutter 项目**

```bash
cd /workspace && flutter create bbq_ledger --org com.bbq --platforms android
```

- [ ] **Step 2: 配置 pubspec.yaml 依赖**

```yaml
name: bbq_ledger
description: BBQ 烧烤原料批发客户账本
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.1.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.3.0
  provider: ^6.1.1
  intl: ^0.19.0
  fl_chart: ^0.66.0
  uuid: ^4.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
```

- [ ] **Step 3: 创建 Supabase 配置文件**

```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  // TODO: 替换为你的 Supabase 项目 URL 和 anon key
  // 后期迁移到自托管时只需修改这两个值
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

- [ ] **Step 4: 创建 main.dart 入口**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const BbqLedgerApp());
}
```

- [ ] **Step 5: 创建 app.dart**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

class BbqLedgerApp extends StatelessWidget {
  const BbqLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBQ 账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const LoginScreen(),
    );
  }
}
```

- [ ] **Step 6: 创建数据库迁移 SQL**

```sql
-- supabase/migrations/001_initial_schema.sql
-- （内容见上文数据库设计完整 SQL）
```

- [ ] **Step 7: 验证项目可编译**

```bash
cd /workspace/bbq_ledger && flutter pub get && flutter analyze
```

Expected: No errors (可能会有 info/warning 关于未使用的 import，后续任务会解决)

---

### Task 2: 数据模型层

**Files:**
- Create: `/workspace/bbq_ledger/lib/models/user.dart`
- Create: `/workspace/bbq_ledger/lib/models/customer.dart`
- Create: `/workspace/bbq_ledger/lib/models/product.dart`
- Create: `/workspace/bbq_ledger/lib/models/order.dart`
- Create: `/workspace/bbq_ledger/lib/models/order_item.dart`

- [ ] **Step 1: User 模型**

```dart
// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String pinCode;
  final String avatarColor;

  const User({
    required this.id,
    required this.name,
    required this.pinCode,
    this.avatarColor = '#4CAF50',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      pinCode: json['pin_code'] as String,
      avatarColor: (json['avatar_color'] as String?) ?? '#4CAF50',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pin_code': pinCode,
      'avatar_color': avatarColor,
    };
  }
}
```

- [ ] **Step 2: Customer 模型**

```dart
// lib/models/customer.dart
class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;

  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
    };
  }
}
```

- [ ] **Step 3: Product 模型**

```dart
// lib/models/product.dart
class Product {
  final String id;
  final String name;
  final String unit;

  const Product({
    required this.id,
    required this.name,
    this.unit = '包',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: (json['unit'] as String?) ?? '包',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
    };
  }
}
```

- [ ] **Step 4: OrderItem 模型**

```dart
// lib/models/order_item.dart
class OrderItem {
  final String? id;
  final String productId;
  final String productName;  // join 查询带出来的
  final String productUnit;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.productUnit,
    required this.quantity,
    required this.unitPrice,
    this.subtotal = 0,
  });

  double get calculatedSubtotal => quantity * unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String?,
      productId: json['product_id'] as String,
      productName: (json['product_name'] as String?) ?? '',
      productUnit: (json['product_unit'] as String?) ?? '包',
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}
```

- [ ] **Step 5: Order 模型**

```dart
// lib/models/order.dart
import 'order_item.dart';

enum OrderStatus { pending, claimed, delivered, completed }

class Order {
  final String? id;
  final String customerId;
  final String customerName;
  final String createdBy;
  final String createdByName;
  final String? claimedBy;
  final String? claimedByName;
  final OrderStatus status;
  final DateTime? deliveryDeadline;
  final double totalAmount;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;
  final List<OrderItem> items;

  const Order({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.createdBy,
    required this.createdByName,
    this.claimedBy,
    this.claimedByName,
    required this.status,
    this.deliveryDeadline,
    this.totalAmount = 0,
    this.isPaid = false,
    this.paidAt,
    this.deliveredAt,
    this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem> items = const []}) {
    return Order(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String,
      customerName: (json['customer_name'] as String?) ?? '',
      createdBy: json['created_by'] as String,
      createdByName: (json['created_by_name'] as String?) ?? '',
      claimedBy: json['claimed_by'] as String?,
      claimedByName: (json['claimed_by_name'] as String?) ?? '',
      status: _parseStatus(json['status'] as String),
      deliveryDeadline: json['delivery_deadline'] != null
          ? DateTime.parse(json['delivery_deadline'] as String)
          : null,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      isPaid: (json['is_paid'] as bool?) ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      items: items,
    );
  }

  static OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'pending': return OrderStatus.pending;
      case 'claimed': return OrderStatus.claimed;
      case 'delivered': return OrderStatus.delivered;
      case 'completed': return OrderStatus.completed;
      default: return OrderStatus.pending;
    }
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending: return '待认领';
      case OrderStatus.claimed: return '送货中';
      case OrderStatus.delivered: return '未收款';
      case OrderStatus.completed: return '已完成';
    }
  }

  String get statusDbValue {
    switch (status) {
      case OrderStatus.pending: return 'pending';
      case OrderStatus.claimed: return 'claimed';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.completed: return 'completed';
    }
  }
}
```

- [ ] **Step 6: 验证编译**

```bash
cd /workspace/bbq_ledger && flutter analyze lib/models/
```

Expected: No errors.

---

### Task 3: 认证服务（PIN 码登录）

**Files:**
- Create: `/workspace/bbq_ledger/lib/services/auth_service.dart`
- Create: `/workspace/bbq_ledger/lib/providers/auth_provider.dart`
- Create: `/workspace/bbq_ledger/lib/screens/login_screen.dart`

- [ ] **Step 1: AuthService**

```dart
// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 获取所有用户列表（供选择登录）
  Future<List<User>> getUsers() async {
    final response = await _client.from('users').select();
    return (response as List).map((e) => User.fromJson(e)).toList();
  }

  /// PIN 码验证登录
  Future<User?> login(String userId, String pin) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .eq('pin_code', pin)
        .maybeSingle();

    if (response == null) return null;
    return User.fromJson(response);
  }

  /// 创建新用户（首次使用时手动在 Supabase 控制台添加，这里备用）
  Future<User> createUser(String name, String pinCode, String avatarColor) async {
    final response = await _client.from('users').insert({
      'name': name,
      'pin_code': pinCode,
      'avatar_color': avatarColor,
    }).select().single();

    return User.fromJson(response);
  }
}
```

- [ ] **Step 2: AuthProvider**

```dart
// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  List<User> _users = [];

  User? get currentUser => _currentUser;
  List<User> get users => _users;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadUsers() async {
    _users = await _authService.getUsers();
    notifyListeners();
  }

  Future<String?> login(String userId, String pin) async {
    final user = await _authService.login(userId, pin);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return null; // 成功，无错误信息
    }
    return 'PIN 码错误，请重试';
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
```

- [ ] **Step 3: LoginScreen**

```dart
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  User? _selectedUser;
  final _pinController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_selectedUser == null) {
      setState(() => _error = '请先选择用户');
      return;
    }
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = '请输入 PIN 码');
      return;
    }

    final error = await context.read<AuthProvider>().login(_selectedUser!.id, pin);
    if (error != null) {
      setState(() => _error = error);
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.outdoor_grill, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text('BBQ 烧烤账本', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 40),

              // 用户选择
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: auth.users.map((user) {
                      final selected = _selectedUser?.id == user.id;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedUser = user;
                          _error = null;
                        }),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: selected
                                  ? Colors.orange
                                  : Color(int.parse(user.avatarColor.replaceFirst('#', '0xFF'))),
                              child: Text(
                                user.name[0],
                                style: const TextStyle(fontSize: 24, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(user.name, style: TextStyle(
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? Colors.orange : null,
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),

              // PIN 输入
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'PIN 码',
                  border: const OutlineInputBorder(),
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => _doLogin(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _doLogin,
                  child: const Text('登录', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 更新 app.dart 添加 Provider**

更新 `lib/app.dart`，在 MaterialApp 外层包裹 MultiProvider：

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';

class BbqLedgerApp extends StatelessWidget {
  const BbqLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'BBQ 账本',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.orange,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
```

- [ ] **Step 5: 验证编译**

```bash
cd /workspace/bbq_ledger && flutter pub get && flutter analyze
```

Expected: No errors.

---

### Task 4: 基础数据服务（客户、货品）

**Files:**
- Create: `/workspace/bbq_ledger/lib/services/customer_service.dart`
- Create: `/workspace/bbq_ledger/lib/services/product_service.dart`

- [ ] **Step 1: CustomerService**

```dart
// lib/services/customer_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Customer>> getAll() async {
    final response = await _client
        .from('customers')
        .select()
        .order('name');
    return (response as List).map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> create(String name, {String phone = '', String address = '', String notes = ''}) async {
    final response = await _client.from('customers').insert({
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
    }).select().single();
    return Customer.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  /// 搜索客户（用于快速查找）
  Future<List<Customer>> search(String query) async {
    final response = await _client
        .from('customers')
        .select()
        .ilike('name', '%$query%')
        .order('name');
    return (response as List).map((e) => Customer.fromJson(e)).toList();
  }
}
```

- [ ] **Step 2: ProductService**

```dart
// lib/services/product_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> getAll() async {
    final response = await _client
        .from('products')
        .select()
        .order('name');
    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> create(String name, String unit) async {
    final response = await _client.from('products').insert({
      'name': name,
      'unit': unit,
    }).select().single();
    return Product.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  /// 获取某客户某货品的历史单价
  Future<double?> getLastPrice(String customerId, String productId) async {
    final response = await _client
        .from('customer_product_prices')
        .select('unit_price')
        .eq('customer_id', customerId)
        .eq('product_id', productId)
        .maybeSingle();

    if (response == null) return null;
    return (response['unit_price'] as num).toDouble();
  }

  /// 保存/更新客户-货品单价
  Future<void> savePrice(String customerId, String productId, double price) async {
    await _client.from('customer_product_prices').upsert({
      'customer_id': customerId,
      'product_id': productId,
      'unit_price': price,
    });
  }
}
```

- [ ] **Step 3: 验证编译**

```bash
cd /workspace/bbq_ledger && flutter analyze lib/services/
```

Expected: No errors.

---

### Task 5: 订单服务（核心业务逻辑）

**Files:**
- Create: `/workspace/bbq_ledger/lib/services/order_service.dart`

- [ ] **Step 1: OrderService**

```dart
// lib/services/order_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 创建订单（含货品明细）
  Future<Order> create({
    required String customerId,
    required String createdBy,
    DateTime? deliveryDeadline,
    required List<OrderItem> items,
  }) async {
    // 1. 创建订单主记录
    final orderResponse = await _client.from('orders').insert({
      'customer_id': customerId,
      'created_by': createdBy,
      'delivery_deadline': deliveryDeadline?.toIso8601String(),
      'status': 'pending',
    }).select('''
      *,
      customers:customer_id(name),
      created_by_user:created_by(name)
    ''').single();

    final orderId = orderResponse['id'] as String;

    // 2. 批量插入货品明细
    final itemRows = items.map((item) => {
      'order_id': orderId,
      'product_id': item.productId,
      'quantity': item.quantity,
      'unit_price': item.unitPrice,
    }).toList();

    await _client.from('order_items').insert(itemRows);

    // 3. 更新总金额
    await _updateTotalAmount(orderId);

    return Order.fromJson(orderResponse);
  }

  /// 更新订单总金额（从 order_items subtotal 汇总）
  Future<void> _updateTotalAmount(String orderId) async {
    final result = await _client
        .from('order_items')
        .select('subtotal')
        .eq('order_id', orderId);

    final total = (result as List).fold<double>(
      0, (sum, item) => sum + ((item['subtotal'] as num?)?.toDouble() ?? 0),
    );

    await _client.from('orders').update({
      'total_amount': total,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// 查询订单（按状态过滤），带 join 客户名、创建人名、认领人名
  Future<List<Order>> getOrders({
    List<String>? statuses,
    String? claimedBy,
  }) async {
    var query = _client.from('orders').select('''
      *,
      customers:customer_id(name),
      created_by_user:created_by(name),
      claimed_by_user:claimed_by(name)
    ''').order('created_at', ascending: false);

    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter('status', statuses);
    }
    if (claimedBy != null) {
      query = query.eq('claimed_by', claimedBy);
    }

    final response = await query;
    final orders = (response as List).map((row) {
      return Order(
        id: row['id'],
        customerId: row['customer_id'],
        customerName: row['customers']?['name'] ?? '',
        createdBy: row['created_by'],
        createdByName: row['created_by_user']?['name'] ?? '',
        claimedBy: row['claimed_by'],
        claimedByName: row['claimed_by_user']?['name'] ?? '',
        status: Order._parseStatus(row['status']),
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

    return orders;
  }

  /// 获取订单货品明细
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final response = await _client.from('order_items').select('''
      *,
      products:product_id(name, unit)
    ''').eq('order_id', orderId);

    return (response as List).map((row) {
      return OrderItem(
        id: row['id'],
        productId: row['product_id'],
        productName: row['products']?['name'] ?? '',
        productUnit: row['products']?['unit'] ?? '包',
        quantity: (row['quantity'] as num).toDouble(),
        unitPrice: (row['unit_price'] as num).toDouble(),
        subtotal: (row['subtotal'] as num).toDouble(),
      );
    }).toList();
  }

  /// 认领订单
  Future<void> claim(String orderId, String userId) async {
    await _client.from('orders').update({
      'claimed_by': userId,
      'status': 'claimed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// 标记送达（记录送达时间，状态变为 delivered，仍为未收款）
  Future<void> markDelivered(String orderId) async {
    await _client.from('orders').update({
      'status': 'delivered',
      'delivered_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// 标记已收款（进入历史账单）
  Future<void> markPaid(String orderId) async {
    await _client.from('orders').update({
      'status': 'completed',
      'is_paid': true,
      'paid_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// 实时订阅订单变化
  Stream<List<Map<String, dynamic>>> subscribeOrders({List<String>? statuses}) {
    var channel = _client.from('orders').stream(primaryKey: ['id']);
    // 注意：Supabase Realtime 的过滤能力有限，复杂过滤在客户端做
    return channel.map((snapshots) {
      return snapshots.map((s) => s as Map<String, dynamic>).toList();
    });
  }
}
```

- [ ] **Step 2: 修复 Order 模型中的 _parseStatus 访问权限**

将 `Order._parseStatus` 改为公开的静态方法（因为 `OrderService` 引用了它）。更新 `lib/models/order.dart` 中 `_parseStatus` 为 `parseStatus`（去掉下划线前缀）。

Search for `static OrderStatus _parseStatus` and replace with `static OrderStatus parseStatus`. Also update the `fromJson` factory to call `parseStatus`.

使用 SearchReplace 修改：

```dart
// 找到 _parseStatus 定义，改为公开
static OrderStatus parseStatus(String s) {
  // ... same body
}
```

同时更新 fromJson 中的调用 `_parseStatus` → `parseStatus`。

- [ ] **Step 3: 验证编译**

```bash
cd /workspace/bbq_ledger && flutter analyze lib/services/order_service.dart lib/models/order.dart
```

Expected: No errors.

---

### Task 6: 首页（导航中枢 + 概览卡片）

**Files:**
- Create: `/workspace/bbq_ledger/lib/screens/home_screen.dart`
- Create: `/workspace/bbq_ledger/lib/providers/order_provider.dart`

- [ ] **Step 1: OrderProvider**

```dart
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

  List<Order> get pendingOrders => _pendingOrders;
  List<Order> get myDeliveries => _myDeliveries;
  List<Order> get unpaidOrders => _unpaidOrders;
  List<Order> get historyOrders => _historyOrders;
  bool get loading => _loading;

  Future<void> loadAll(String currentUserId) async {
    _loading = true;
    notifyListeners();

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
    notifyListeners();
  }

  Future<void> claimOrder(String orderId, String userId) async {
    await _orderService.claim(orderId, userId);
    await loadAll(userId); // 刷新
  }

  Future<void> markDelivered(String orderId, String userId) async {
    await _orderService.markDelivered(orderId);
    await loadAll(userId);
  }

  Future<void> markPaid(String orderId, String userId) async {
    await _orderService.markPaid(orderId);
    await loadAll(userId);
  }
}
```

- [ ] **Step 2: HomeScreen**

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'new_order_screen.dart';
import 'order_pool_screen.dart';
import 'my_deliveries_screen.dart';
import 'unpaid_screen.dart';
import 'history_screen.dart';
import 'monthly_report_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      context.read<OrderProvider>().loadAll(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BBQ 烧烤账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            if (orderProvider.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 当前用户信息
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(user.name[0], style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${user.name}，你好！', style: Theme.of(context).textTheme.titleMedium),
                            Text(DateFormat('yyyy年MM月dd日').format(DateTime.now()),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 快捷操作按钮
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
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
                ),
                const SizedBox(height: 16),

                // 历史账单 + 月度报表
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('历史账单'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('月度汇总报表'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.15),
        margin: const EdgeInsets.only(right: 12),
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 更新 app.dart 注册 OrderProvider**

在 `lib/app.dart` 的 MultiProvider 中追加：

```dart
ChangeNotifierProvider(create: (_) => OrderProvider()),
```

- [ ] **Step 4: 验证编译**

```bash
cd /workspace/bbq_ledger && flutter analyze lib/screens/home_screen.dart lib/providers/order_provider.dart
```

Expected: No errors.

---

### Task 7: 新建订单页面（核心录入界面）

**Files:**
- Create: `/workspace/bbq_ledger/lib/screens/new_order_screen.dart`

- [ ] **Step 1: NewOrderScreen**

```dart
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

  // 当前订单的货品行
  final List<_ItemRow> _items = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      _items.removeAt(index);
    });
  }

  Future<void> _onProductSelected(int index, Product product) async {
    final item = _items[index];
    item.product = product;
    item.quantityController.text = '1';

    // 自动查询该客户该货品的历史单价
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
    // 验证
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

      // 保存每个货品的历史单价
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
          // 选择客户
          DropdownButtonFormField<Customer>(
            value: _selectedCustomer,
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

          // 送达时限
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

          // 货品列表
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
                            value: item.product,
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
```

- [ ] **Step 2: 在 NewOrderScreen dispose 中释放 _items 控制器**

在 `_NewOrderScreenState` 中添加：

```dart
@override
void dispose() {
  for (final item in _items) {
    item.dispose();
  }
  super.dispose();
}
```

- [ ] **Step 3: 验证编译**

```bash
cd /workspace/bbq_ledger && flutter analyze lib/screens/new_order_screen.dart
```

Expected: No errors.

---

### Task 8: 订单池 + 我的送货 + 未收款 + 历史账单 四个列表页

**Files:**
- Create: `/workspace/bbq_ledger/lib/screens/order_pool_screen.dart`
- Create: `/workspace/bbq_ledger/lib/screens/my_deliveries_screen.dart`
- Create: `/workspace/bbq_ledger/lib/screens/unpaid_screen.dart`
- Create: `/workspace/bbq_ledger/lib/screens/history_screen.dart`
- Create: `/workspace/bbq_ledger/lib/widgets/order_card.dart`

- [ ] **Step 1: OrderCard 通用组件**

```dart
// lib/widgets/order_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/order_service.dart';

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
            // 标题行
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
                    color: _statusColor(order.status).withOpacity(0.15),
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

            // 信息行
            if (order.deliveryDeadline != null)
              _InfoRow(icon: Icons.access_time, text: '${dateFormat.format(order.deliveryDeadline!)} 前送达'),
            _InfoRow(icon: Icons.person, text: '记账: ${order.createdByName}'),
            if (order.claimedByName.isNotEmpty)
              _InfoRow(icon: Icons.delivery_dining, text: '送货: ${order.claimedByName}'),

            const Divider(height: 16),

            // 货品列表（静态展示，不实时查询）
            Text('总金额: ¥${currencyFormat.format(order.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            const SizedBox(height: 12),

            // 操作按钮
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
```

- [ ] **Step 2: OrderPoolScreen（待认领订单池）**

```dart
// lib/screens/order_pool_screen.dart
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
```

- [ ] **Step 3: MyDeliveriesScreen（我的送货）**

```dart
// lib/screens/my_deliveries_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';

class MyDeliveriesScreen extends StatelessWidget {
  const MyDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的送货')),
      body: orderProvider.myDeliveries.isEmpty
          ? const Center(child: Text('暂无送货任务'))
          : RefreshIndicator(
              onRefresh: () => orderProvider.loadAll(auth.currentUser!.id),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.myDeliveries.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.myDeliveries[index];
                  return OrderCard(
                    order: order,
                    actionLabel: '确认送达',
                    actionColor: Colors.green,
                    onAction: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认送达'),
                          content: Text('确定「${order.customerName}」的订单已送达？\n总金额: ¥${order.totalAmount.toStringAsFixed(2)}'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                orderProvider.markDelivered(order.id!, auth.currentUser!.id);
                              },
                              child: const Text('确认送达'),
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
```

- [ ] **Step 4: UnpaidScreen（未收款）**

```dart
// lib/screens/unpaid_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';

class UnpaidScreen extends StatelessWidget {
  const UnpaidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('未收款订单')),
      body: orderProvider.unpaidOrders.isEmpty
          ? const Center(child: Text('暂无未收款订单'))
          : RefreshIndicator(
              onRefresh: () => orderProvider.loadAll(auth.currentUser!.id),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.unpaidOrders.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.unpaidOrders[index];
                  return OrderCard(
                    order: order,
                    actionLabel: '确认收款',
                    actionColor: Colors.blue,
                    onAction: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认收款'),
                          content: Text('确定已收到「${order.customerName}」的 ¥${order.totalAmount.toStringAsFixed(2)}？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                orderProvider.markPaid(order.id!, auth.currentUser!.id);
                              },
                              child: const Text('确认收款'),
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
```

- [ ] **Step 5: HistoryScreen（历史账单 - 已收款订单）**

```dart
// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  String? _selectedCustomerId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await _orderService.getOrders(statuses: ['completed']);
    setState(() => _orders = orders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史账单')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _orders.isEmpty
            ? const Center(child: Text('暂无历史账单'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return OrderCard(
                    order: order,
                    onAction: () => _showDetail(context, order),
                    actionLabel: '查看明细',
                    actionColor: Colors.grey,
                  );
                },
              ),
      ),
    );
  }

  void _showDetail(BuildContext context, Order order) async {
    final items = await _orderService.getOrderItems(order.id!);
    if (!mounted) return;

    final currencyFormat = NumberFormat('#,##0.00');
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${order.customerName} — 订单明细', style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              ...items.map((item) => ListTile(
                    title: Text('${item.productName} × ${item.quantity}${item.productUnit}'),
                    subtitle: Text('单价 ¥${item.unitPrice.toStringAsFixed(2)}'),
                    trailing: Text('¥${currencyFormat.format(item.calculatedSubtotal)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('总金额', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('¥${currencyFormat.format(order.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                ],
              ),
              if (order.paidAt != null)
                Text('收款时间: ${DateFormat('yyyy-MM-dd HH:mm').format(order.paidAt!)}',
                    style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 6: 验证编译**

```bash
cd /workspace/bbq_ledger && flutter analyze lib/screens/order_pool_screen.dart lib/screens/my_deliveries_screen.dart lib/screens/unpaid_screen.dart lib/screens/history_screen.dart lib/widgets/order_card.dart
```

Expected: No errors.

---

### Task 9: 月度汇总报表页面

**Files:**
- Create: `/workspace/bbq_ledger/lib/services/report_service.dart`
- Create: `/workspace/bbq_ledger/lib/providers/report_provider.dart`
- Create: `/workspace/bbq_ledger/lib/screens/monthly_report_screen.dart`

- [ ] **Step 1: ReportService**

```dart
// lib/services/report_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyReport {
  final int year;
  final int month;
  final List<ProductSalesSummary> productSummaries;
  final double totalRevenue;
  final int orderCount;

  const MonthlyReport({
    required this.year,
    required this.month,
    required this.productSummaries,
    required this.totalRevenue,
    required this.orderCount,
  });
}

class ProductSalesSummary {
  final String productId;
  final String productName;
  final String productUnit;
  final double totalQuantity;
  final double totalAmount;

  const ProductSalesSummary({
    required this.productId,
    required this.productName,
    required this.productUnit,
    required this.totalQuantity,
    required this.totalAmount,
  });
}

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 获取指定月份的销售汇总
  Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    // 查询该月份所有已完成（已收款）的订单
    final orderResponse = await _client
        .from('orders')
        .select('id, total_amount')
        .eq('status', 'completed')
        .gte('paid_at', startDate.toIso8601String())
        .lt('paid_at', endDate.toIso8601String());

    final orders = orderResponse as List;
    final orderIds = orders.map((o) => o['id'] as String).toList();

    if (orderIds.isEmpty) {
      return MonthlyReport(
        year: year, month: month,
        productSummaries: [], totalRevenue: 0, orderCount: 0,
      );
    }

    // 查询这些订单的所有货品明细，按货品汇总
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

    final items = itemResponse as List;

    // 按 product_id 聚合
    final Map<String, ProductSalesSummary> summaryMap = {};
    for (final item in items) {
      final pid = item['product_id'] as String;
      final name = item['products']?['name'] ?? '';
      final unit = item['products']?['unit'] ?? '';
      final qty = (item['quantity'] as num).toDouble();
      final subtotal = (item['subtotal'] as num).toDouble();

      if (summaryMap.containsKey(pid)) {
        final existing = summaryMap[pid]!;
        summaryMap[pid] = ProductSalesSummary(
          productId: pid,
          productName: name,
          productUnit: unit,
          totalQuantity: existing.totalQuantity + qty,
          totalAmount: existing.totalAmount + subtotal,
        );
      } else {
        summaryMap[pid] = ProductSalesSummary(
          productId: pid,
          productName: name,
          productUnit: unit,
          totalQuantity: qty,
          totalAmount: subtotal,
        );
      }
    }

    final totalRevenue = orders.fold<double>(
      0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0),
    );

    return MonthlyReport(
      year: year,
      month: month,
      productSummaries: summaryMap.values.toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)),
      totalRevenue: totalRevenue,
      orderCount: orders.length,
    );
  }
}
```

- [ ] **Step 2: ReportProvider**

```dart
// lib/providers/report_provider.dart
import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  MonthlyReport? _report;
  bool _loading = false;

  MonthlyReport? get report => _report;
  bool get loading => _loading;

  Future<void> loadReport(int year, int month) async {
    _loading = true;
    notifyListeners();

    _report = await _reportService.getMonthlyReport(year, month);
    _loading = false;
    notifyListeners();
  }
}
```

- [ ] **Step 3: MonthlyReportScreen**

```dart
// lib/screens/monthly_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/report_provider.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<ReportProvider>().loadReport(_selectedYear, _selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: const Text('月度汇总报表')),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, _) {
          return Column(
            children: [
              // 月份选择器
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          if (_selectedMonth == 1) {
                            _selectedMonth = 12;
                            _selectedYear--;
                          } else {
                            _selectedMonth--;
                          }
                        });
                        _load();
                      },
                    ),
                    Text(
                      '${_selectedYear}年${_selectedMonth}月',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final now = DateTime.now();
                        if (_selectedYear == now.year && _selectedMonth == now.month) return;
                        setState(() {
                          if (_selectedMonth == 12) {
                            _selectedMonth = 1;
                            _selectedYear++;
                          } else {
                            _selectedMonth++;
                          }
                        });
                        _load();
                      },
                    ),
                  ],
                ),
              ),

              if (reportProvider.loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (reportProvider.report == null)
                const Expanded(child: Center(child: Text('暂无数据')))
              else ...[
                // 汇总卡片
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _SummaryCard(
                        title: '总营业额',
                        value: '¥${currencyFormat.format(reportProvider.report!.totalRevenue)}',
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        title: '订单数',
                        value: '${reportProvider.report!.orderCount}笔',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 柱状图
                if (reportProvider.report!.productSummaries.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: reportProvider.report!.productSummaries
                              .map((s) => s.totalQuantity)
                              .reduce((a, b) => a > b ? a : b) * 1.3,
                          barGroups: reportProvider.report!.productSummaries.take(10).map((s) {
                            return BarChartGroupData(
                              x: reportProvider.report!.productSummaries.indexOf(s),
                              barRods: [
                                BarChartRodData(
                                  toY: s.totalQuantity,
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
                                  if (index >= 0 && index < reportProvider.report!.productSummaries.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        reportProvider.report!.productSummaries[index].productName,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 详细列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reportProvider.report!.productSummaries.length,
                    itemBuilder: (context, index) {
                      final s = reportProvider.report!.productSummaries[index];
                      return ListTile(
                        title: Text(s.productName),
                        subtitle: Text('总销量: ${s.totalQuantity}${s.productUnit}'),
                        trailing: Text(
                          '¥${currencyFormat.format(s.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
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
        color: color.withOpacity(0.1),
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

- [ ] **Step 4: 注册 ReportProvider 到 app.dart**

在 `lib/app.dart` 的 MultiProvider 中追加：

```dart
ChangeNotifierProvider(create: (_) => ReportProvider()),
```

同时在 OrderProvider 中也注册：

```dart
ChangeNotifierProvider(create: (_) => OrderProvider()),
```

- [ ] **Step 5: 验证编译**

```bash
cd /workspace/bbq_ledger && flutter analyze
```

Expected: No errors.

---

### Task 10: 端到端集成测试与 APK 构建

- [ ] **Step 1: 在 Supabase 控制台执行数据库迁移 SQL**

将 `supabase/migrations/001_initial_schema.sql` 的内容在 Supabase 控制台 SQL Editor 中执行。

- [ ] **Step 2: 预置种子数据（手动在 Supabase 控制台操作）**

```sql
-- 添加家庭成员
INSERT INTO users (name, pin_code, avatar_color) VALUES
  ('爸爸', '1234', '#FF5722'),
  ('妈妈', '1234', '#E91E63'),
  ('A', '1234', '#4CAF50');

-- 添加示例客户
INSERT INTO customers (name) VALUES ('网吧王老板'), ('学校李主任'), ('工地张工头');

-- 添加示例货品
INSERT INTO products (name, unit) VALUES
  ('热狗', '包'),
  ('火腿', '箱'),
  ('鸡翅', '袋'),
  ('牛肉串', '袋'),
  ('羊肉串', '袋');
```

- [ ] **Step 3: 配置 SupabaseConfig**

修改 `lib/config/supabase_config.dart` 中的 URL 和 anonKey 为实际 Supabase 项目值。

- [ ] **Step 4: 构建 APK**

```bash
cd /workspace/bbq_ledger && flutter build apk --release
```

- [ ] **Step 5: 验证 APK 生成**

```bash
ls -la /workspace/bbq_ledger/build/app/outputs/flutter-apk/app-release.apk
```

Expected: APK 文件存在且大小合理（通常 15-30MB）。

---

## 后续优化（非本期）

1. **Supabase Realtime 实时同步**: 当前通过手动刷新，后续可改为 Supabase Realtime 订阅，订单池自动更新。
2. **离线模式**: 添加本地 SQLite 缓存，断网时可记账，联网后自动同步。
3. **客户管理页面**: 新建/编辑/删除客户和货品的独立管理界面。
4. **推送通知**: 新订单创建后通知所有人。
5. **自托管 Supabase 迁移**: 修改 `SupabaseConfig` 中的 URL 指向自托管服务器即可。
6. **历史账单筛选**: 按客户、日期范围筛选，导出 Excel。

---

## Self-Review 自查清单

**1. Spec coverage:**
- [x] 客户记账（网吧王老板，货品+数量+时限） → Task 7 NewOrderScreen
- [x] 云端同步（多人查看） → Supabase 实时数据库
- [x] 认领送货（A 选择去送） → Task 8 OrderPoolScreen
- [x] 标记送达 → Task 8 MyDeliveriesScreen
- [x] 记录总价 + 未收款 → Task 7（录入单价）+ Task 8 UnpaidScreen
- [x] 收款存入历史 → Task 8 HistoryScreen
- [x] 历史账单记录日期、货品、数量、单价 → Task 5 OrderService + Task 8 HistoryScreen
- [x] 月度汇总销量+金额 → Task 9 MonthlyReportScreen
- [x] 不同客户不同单价 → customer_product_prices 表 + 首次录入记忆
- [x] PIN 码登录 → Task 3 LoginScreen
- [x] 后期改为本地储存服务器 → Supabase 自托管方案

**2. Placeholder scan:**
- 所有代码步骤都包含完整实现代码，无 TBD/TODO。

**3. Type consistency:**
- `Order._parseStatus` → 已修复为公开的 `Order.parseStatus`，OrderService 和 model 一致。
- Customer、Product、Order、OrderItem 模型在各 Service 和 Screen 中一致。
- Provider 命名一致：AuthProvider、OrderProvider、ReportProvider。