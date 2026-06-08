# 记账本 v2 改进计划

> **Goal:** 移除 PIN 码登录改为直接选用户 + 自动登录，更新用户和产品数据，添加产品管理功能

**Architecture:** 用 shared_preferences 本地存储上次登录用户 ID，启动时自动恢复；登录页简化为纯用户选择；新增货品管理弹窗

**Tech Stack:** Flutter + Supabase + shared_preferences + Provider

---

### Task 1: 数据库重置（用户和产品）

**操作方式:** 通过 Supabase REST API（service_role key）直接操作

- [ ] **Step 1: 删除旧用户**

```bash
curl -X DELETE "https://wtoukdzykvuoycrolpfq.supabase.co/rest/v1/users?id=in.(用户ID列表)" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer SERVICE_ROLE_KEY"
```

- [ ] **Step 2: 删除旧产品**

```bash
curl -X DELETE "https://wtoukdzykvuoycrolpfq.supabase.co/rest/v1/products?id=in.(产品ID列表)" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer SERVICE_ROLE_KEY"
```

- [ ] **Step 3: 插入新用户（6个）**

```bash
curl -X POST "https://wtoukdzykvuoycrolpfq.supabase.co/rest/v1/users" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '[
    {"name":"临时用户","pin_code":"","avatar_color":"#9E9E9E"},
    {"name":"宋子翔","pin_code":"","avatar_color":"#2196F3"},
    {"name":"曾春香","pin_code":"","avatar_color":"#E91E63"},
    {"name":"宋卫华","pin_code":"","avatar_color":"#4CAF50"},
    {"name":"袁期桂","pin_code":"","avatar_color":"#FF9800"},
    {"name":"宋卫民","pin_code":"","avatar_color":"#9C27B0"}
  ]'
```

- [ ] **Step 4: 插入新产品（6个）**

```bash
curl -X POST "https://wtoukdzykvuoycrolpfq.supabase.co/rest/v1/products" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '[
    {"name":"大火腿","unit":"箱"},
    {"name":"3号肠","unit":"箱"},
    {"name":"1号肠","unit":"箱"},
    {"name":"鸡柳","unit":"箱"},
    {"name":"南拳王","unit":"箱"},
    {"name":"热狗","unit":"包"}
  ]'
```

---

### Task 2: 添加 shared_preferences 依赖

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 添加依赖**

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.3.0
  provider: ^6.1.1
  intl: ^0.19.0
  fl_chart: ^0.66.0
  shared_preferences: ^2.2.2
```

- [ ] **Step 2: 安装依赖**

```bash
cd /workspace/bbq_ledger && flutter pub get
```

---

### Task 3: 修改 AuthProvider（移除 PIN + 自动登录）

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**将整个文件替换为：**

```dart
// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  List<AppUser> _users = [];
  bool _loading = true;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get users => _users;
  bool get isLoggedIn => _currentUser != null;
  bool get loading => _loading;

  Future<void> loadUsers() async {
    _users = await _authService.getUsers();
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String userId) async {
    final user = _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => _users.first,
    );
    _currentUser = user;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_user_id', userId);
  }

  Future<bool> tryAutoLogin() async {
    await loadUsers();
    if (_users.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('last_user_id');

    if (savedUserId != null) {
      final user = _users.where((u) => u.id == savedUserId).firstOrNull;
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
```

---

### Task 4: 修改 LoginScreen（纯用户选择，无 PIN）

**Files:**
- Modify: `lib/screens/login_screen.dart`

**将整个文件替换为：**

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUsers();
    });
  }

  Future<void> _doLogin(AppUser user) async {
    await context.read<AuthProvider>().login(user.id);
    if (mounted) {
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
              const Icon(Icons.menu_book, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text('记账本', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('选择你的账号', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 40),

              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.loading) {
                    return const CircularProgressIndicator();
                  }
                  if (auth.users.isEmpty) {
                    return const Text('暂无用户，请先在数据库中添加', style: TextStyle(color: Colors.grey));
                  }
                  return Wrap(
                    spacing: 16,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: auth.users.map((user) {
                      return GestureDetector(
                        onTap: () => _doLogin(user),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(int.parse(user.avatarColor.replaceFirst('#', '0xFF'))),
                              child: Text(
                                user.name[0],
                                style: const TextStyle(fontSize: 28, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(user.name, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Task 5: 修改 App 入口（启动时自动登录）

**Files:**
- Modify: `lib/app.dart`

**将 `_BbqLedgerAppState` 和 `BbqLedgerApp` 改为 StatefulWidget，替换整个文件：**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/report_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class BbqLedgerApp extends StatefulWidget {
  const BbqLedgerApp({super.key});

  @override
  State<BbqLedgerApp> createState() => _BbqLedgerAppState();
}

class _BbqLedgerAppState extends State<BbqLedgerApp> {
  bool _autoLoginChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLogin();
    });
  }

  Future<void> _tryAutoLogin() async {
    final loggedIn = await context.read<AuthProvider>().tryAutoLogin();
    setState(() => _autoLoginChecked = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: '记账本',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.orange,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: _autoLoginChecked
            ? Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
                },
              )
            : const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}
```

---

### Task 6: 修改 HomeScreen（改标题 + 切换账号按钮）

**Files:**
- Modify: `lib/screens/home_screen.dart`

**修改 AppBar 部分：**

搜索：
```dart
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
```

替换为：
```dart
appBar: AppBar(
  title: const Text('记账本'),
  actions: [
    IconButton(
      icon: const Icon(Icons.swap_horiz),
      tooltip: '切换账号',
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
```

---

### Task 7: 添加货品管理功能

**Files:**
- Modify: `lib/screens/new_order_screen.dart`

**在 ListView 的 children 中，在「货品明细」标题之前，添加一个「添加新货品」按钮：**

在 `Text('货品明细', style: ...)` 之前插入：

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('货品明细', style: Theme.of(context).textTheme.titleMedium),
    TextButton.icon(
      onPressed: _addNewProduct,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('新货品'),
    ),
  ],
),
```

**添加 `_addNewProduct` 方法到 `_NewOrderScreenState` 中：**

```dart
Future<void> _addNewProduct() async {
  final nameController = TextEditingController();
  final unitController = TextEditingController(text: '箱');

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('添加新货品'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '货品名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: unitController,
            decoration: const InputDecoration(
              labelText: '单位',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty) return;
            Navigator.pop(ctx, {
              'name': nameController.text.trim(),
              'unit': unitController.text.trim().isEmpty ? '箱' : unitController.text.trim(),
            });
          },
          child: const Text('添加'),
        ),
      ],
    ),
  );

  if (result != null) {
    try {
      final newProduct = await _productService.create(result['name']!, result['unit']!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加：${newProduct.name}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
```

---

### Task 8: 构建 APK 并上传

- [ ] **Step 1: 清理 Gradle 缓存并构建**

```bash
rm -rf /root/.gradle/daemon && cd /workspace/bbq_ledger && flutter build apk --release
```

- [ ] **Step 2: 上传到 Supabase Storage（覆盖已有文件）**

```bash
curl -X POST "https://wtoukdzykvuoycrolpfq.supabase.co/storage/v1/object/apk/app-release.apk" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer SERVICE_ROLE_KEY" \
  -H "Content-Type: application/vnd.android.package-archive" \
  -H "x-upsert: true" \
  --data-binary @/workspace/bbq_ledger/build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 3: 验证下载链接**

```
https://wtoukdzykvuoycrolpfq.supabase.co/storage/v1/object/public/apk/app-release.apk
```