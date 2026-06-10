# AGENTS.md — BBQ Ledger (记账本)

## 项目概述

**bbq_ledger** 是一款面向家庭/小团队的烧烤原料批发配送记账 App，基于 Flutter 开发，后端使用 Supabase (PostgreSQL)。支持多用户角色协作（记账、送货、收款），提供订单管理、客户管理、货品管理、日报/月报统计、Excel 导出、地图导航等功能。

- **App 名称**: 记账本
- **Android 包名**: `com.bbq.bbq_ledger`
- **版本**: 1.0.0+1

---

## 技术栈

| 层 | 技术 |
|---|------|
| **前端框架** | Flutter 3.38+ (Dart SDK >=3.1.0 <4.0.0) |
| **后端 (BaaS)** | Supabase (PostgreSQL + REST API + Realtime) |
| **状态管理** | Provider (`provider ^6.1.1`) + ChangeNotifier |
| **路由** | Material Navigator (push/pop)，无第三方路由库 |
| **图表** | fl_chart ^0.66.0 |
| **地图** | flutter_map ^7.0.0 + latlong2 + map_launcher ^3.0.0 |
| **Excel 导出** | excel ^4.0.0 |
| **本地存储** | shared_preferences ^2.2.2 |
| **联系人导入** | flutter_contacts ^1.1.9 |
| **地理位置** | geolocator ^10.1.0 |
| **平台** | Android 为主 (也包含 rudimentary web 支持) |

### Android 构建环境

| 组件 | 版本 |
|------|------|
| **Gradle** | 8.12 |
| **AGP** | 8.9.1 |
| **Kotlin** | 2.1.0 |
| **Java** | 17 (通过 `gradle.properties` 指定) |
| **compileSdk** | flutter.compileSdkVersion (默认 34) |
| **minSdk** | flutter.minSdkVersion |
| **JVM 堆** | Xmx2560m |

### Gradle Maven 镜像

项目使用阿里云 Maven 镜像加速依赖下载（配置在 `android/build.gradle.kts`）。如需还原为 Google/Maven Central 官方源，删除镜像即可。

---

## 目录结构

```
bbq_ledger/
├── lib/
│   ├── main.dart                          # 入口：初始化 Supabase，运行 App
│   ├── app.dart                           # MaterialApp + MultiProvider 注册
│   ├── config/
│   │   └── supabase_config.dart           # Supabase URL / anonKey / serviceRoleKey
│   ├── models/
│   │   ├── user.dart                      # AppUser 模型
│   │   ├── customer.dart                  # Customer 模型（坐标编码在 notes JSON）
│   │   ├── product.dart                   # Product 模型（name + unit）
│   │   ├── order.dart                     # Order 模型 + OrderStatus 枚举
│   │   └── order_item.dart                # OrderItem 模型
│   ├── services/
│   │   ├── auth_service.dart              # 用户 CRUD、登录验证
│   │   ├── customer_service.dart          # 客户 CRUD、搜索
│   │   ├── product_service.dart           # 货品 CRUD、历史单价记忆
│   │   ├── order_service.dart             # 订单创建/认领/送达/收款/转单/历史搜索
│   │   ├── report_service.dart            # 日报/月报数据聚合（含数据类）
│   │   └── export_service.dart            # Excel 导出（日报/月报）
│   ├── providers/
│   │   ├── auth_provider.dart             # 登录态、用户列表、自动登录
│   │   ├── order_provider.dart            # 四个订单列表 + 操作 + 延期加载优化
│   │   └── report_provider.dart           # 月报状态
│   ├── screens/
│   │   ├── login_screen.dart              # 选择用户登录（自动登录支持）
│   │   ├── home_screen.dart               # 首页仪表盘（快捷卡片 + 菜单）
│   │   ├── new_order_screen.dart          # 新建订单（选客户 → 加货品 → 设送达时间）
│   │   ├── order_pool_screen.dart         # 待认领订单池
│   │   ├── my_deliveries_screen.dart      # 我的送货任务（转单/确认送达）
│   │   ├── unpaid_screen.dart             # 未收款列表（确认收款）
│   │   ├── history_screen.dart            # 历史账单（搜索/筛选/汇总）
│   │   ├── order_overview_screen.dart     # 订单总览
│   │   ├── daily_report_screen.dart       # 每日总表 + 图表
│   │   ├── monthly_report_screen.dart     # 月度汇总报表 + 图表
│   │   ├── customer_management_screen.dart # 客户管理（新增/编辑/删除/通讯录导入）
│   │   ├── product_management_screen.dart  # 货品管理（新增/删除）
│   │   ├── import_screen.dart             # 导入历史账单
│   │   └── location_picker_screen.dart    # 地图选点（含防抖搜索）
│   └── widgets/
│       └── order_card.dart                # 订单卡片组件（通用） + 导航选择
├── supabase/
│   └── migrations/
│       └── 001_initial_schema.sql         # 数据库建表 DDL
├── android/                               # Android 原生工程
├── test/
│   └── widget_test.dart                   # 占位测试
├── pubspec.yaml                           # Flutter 依赖配置
├── pubspec.lock
├── analysis_options.yaml
└── .gitignore
```

---

## 架构设计

### 分层架构

```
UI Layer (screens + widgets)
    ↓ 读取/触发
State Layer (providers: AuthProvider, OrderProvider, ReportProvider)
    ↓ 调用
Service Layer (services: AuthService, CustomerService, ProductService, OrderService, ReportService, ExportService)
    ↓ 查询
Data Layer (Supabase REST API → PostgreSQL)
```

### 状态管理

使用 **Provider + ChangeNotifier** 模式：

- `AuthProvider`: 管理 `currentUser`、`users` 列表、`isLoggedIn`、`loading` 状态。支持 `SharedPreferences` 自动登录。
- `OrderProvider`: 管理四个订单列表 (`pendingOrders`, `myDeliveries`, `unpaidOrders`, `historyOrders`)。使用 `_initialized` 标志区分首次加载（显示 spinner）和后续刷新（静默更新）。使用 `Future.wait` 并行加载四个列表。
- `ReportProvider`: 管理月报数据 (`MonthlyReport?`)、`loading` 状态。

### 路由

基于 Flutter 原生 `Navigator.push` / `pushReplacement` / `pushAndRemoveUntil`，无第三方路由库。

---

## 数据库 Schema (Supabase PostgreSQL)

### 表结构

| 表名 | 用途 | 关键字段 |
|------|------|---------|
| `users` | 用户 | `id`(UUID PK), `name`, `pin_code`, `avatar_color` |
| `customers` | 客户 | `id`(UUID PK), `name`, `phone`, `address`, `notes`(JSON，含坐标) |
| `products` | 货品 | `id`(UUID PK), `name`(UNIQUE), `unit` |
| `orders` | 订单主表 | `id`(UUID PK), `customer_id`(FK), `created_by`(FK), `claimed_by`(FK), `status`(CHECK), `delivery_deadline`, `total_amount`, `is_paid`, `paid_at`, `delivered_at` |
| `order_items` | 订单货品明细 | `id`(UUID PK), `order_id`(FK CASCADE), `product_id`(FK), `quantity`, `unit_price`, `subtotal`(GENERATED), `unit` |
| `customer_product_prices` | 客户-货品历史单价 | `id`(UUID PK), `customer_id`(FK), `product_id`(FK), `unit_price`, UNIQUE(customer_id, product_id) |

### 订单状态流转

```
pending → claimed → delivered → completed
(待认领)   (送货中)   (未收款)    (已完成)
```

### RLS 策略

所有表均启用 RLS，使用 `CREATE POLICY "Allow all" ... USING (true)` 全放通策略（家庭内部使用场景）。

### 重要：数据库迁移

如果遇到 `order_items` 表缺少 `unit` 列的错误，需要在 Supabase SQL Editor 执行：

```sql
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS unit text;
```

---

## 模型约定

### 坐标存储

客户坐标 (lat, lng) 存储在 `customers.notes` 字段的 JSON 中：

```json
{"lat": 30.5928, "lng": 114.3055, "product_prefs": {"<product_id>": {"unit": "包", "price": 35.0}}}
```

`product_prefs` 用于存储每个客户-货品的历史单价和单位选择（通过 `ProductService.saveUnitPrice` 写入）。

### 货品单位

目前仅支持 3 个单位：**包、件、条**。`new_order_screen.dart` 中硬编码 `_commonUnits = ['包', '件', '条']`。

---

## 运行 / 构建 / 测试命令

### 前置条件

- Flutter SDK 3.38+
- Java 17 (通过 `gradle.properties` 中的 `org.gradle.java.home` 指定)
- Android SDK (compileSdk 34)
- Gradle 8.12

### 命令

```bash
# 安装依赖
cd bbq_ledger && flutter pub get

# 开发运行
flutter run

# Release 模式运行
flutter run --release

# 仅构建 Android APK (arm64)
flutter build apk --target-platform android-arm64

# 构建全架构 APK
flutter build apk

# 构建 App Bundle
flutter build appbundle

# 代码静态分析
flutter analyze

# 运行测试
flutter test

# 清理构建缓存
flutter clean
```

### 构建产物位置

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-release.apk
```

---

## 性能优化要点

1. **并行加载**: `OrderProvider.loadAll()` 使用 `Future.wait` 并行加载四个订单列表。`HistoryScreen._load()` 使用 `Future.wait` 并行加载所有订单的 items。
2. **延期加载**: `OrderProvider` 使用 `_initialized` 标志，首次加载显示 spinner，后续刷新静默更新（避免闪烁）。
3. **去重刷新**: 子页面（OrderPoolScreen、MyDeliveriesScreen、UnpaidScreen）返回时不再重复刷新 HomeScreen，因为各子页面内部已自行处理数据更新。
4. **搜索防抖**: `LocationPickerScreen` 使用 500ms debounce 避免地址搜索请求风暴。

---

## 已知约定与注意事项

1. **Supabase Key**: 当前 `anonKey` 实际上是 `service_role` key（权限过高）。生产环境应替换为真正的 anon public key。
2. **APK 签名**: 当前使用 debug keystore 签名（`signingConfig = signingConfigs.getByName("debug")`）。上架应用商店前需配置正式签名。
3. **代理配置**: `gradle.properties` 中配置了 HTTP 代理 (`127.0.0.1:18080`)。本地无代理环境需移除相关配置。
4. **数据库 `unit` 列**: `order_items` 表需要 `unit text` 列，初始 migration 中未包含。需手动执行 ALTER TABLE。
5. **iOS 未配置**: 项目目前仅配置了 Android 端，iOS 目录内容可能不完整。
6. **测试覆盖**: 仅有一个占位 smoke test，业务逻辑无单元测试。
7. **Web 支持**: pubspec.yaml 未显式声明 web 平台，但 Flutter 默认包含 web 编译能力。

---

## 依赖版本速查

| 包 | 版本 | 用途 |
|---|------|------|
| supabase_flutter | ^2.3.0 | Supabase 客户端 |
| provider | ^6.1.1 | 状态管理 |
| intl | ^0.19.0 | 日期/货币格式化 |
| fl_chart | ^0.66.0 | 图表 |
| shared_preferences | ^2.2.2 | 本地键值存储 |
| excel | ^4.0.0 | Excel 生成 |
| path_provider | ^2.1.0 | 文件路径 |
| open_file | ^3.3.0 | 打开文件 |
| file_picker | ^8.0.0 | 文件选择 |
| geolocator | ^10.1.0 | GPS 定位 |
| http | ^1.2.0 | HTTP 请求 |
| flutter_map | ^7.0.0 | 地图展示 |
| latlong2 | ^0.9.0 | 经纬度类型 |
| map_launcher | ^3.0.0 | 唤起第三方导航 |
| flutter_contacts | ^1.1.9 | 通讯录导入 |