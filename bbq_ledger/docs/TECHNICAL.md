# BBQ Ledger（记账本）技术文档

> 版本: 1.2.0+3 | 更新日期: 2026-06-14

---

## 1. 项目概述

**bbq_ledger** 是一款面向家庭/小团队的烧烤原料批发配送记账 App，基于 Flutter 开发，后端使用 Supabase (PostgreSQL + REST API)。支持多用户角色协作（记账、送货、收款），提供订单管理、客户管理、货品管理、库存管理、日报/月报统计、Excel 导出、地图导航等功能。

| 属性 | 值 |
|------|-----|
| App 名称 | 记账本 |
| Android 包名 | `com.bbq.bbq_ledger` |
| 版本 | 1.2.0+3 |
| 平台 | Android（主要）、Web（基础支持） |
| 开发语言 | Dart (Flutter 3.38+) |

---

## 2. 技术栈

| 层 | 技术 | 版本 |
|----|------|------|
| 前端框架 | Flutter | 3.38+ (Dart SDK >=3.1.0 <4.0.0) |
| 后端 (BaaS) | Supabase | PostgreSQL + REST API + Realtime |
| 状态管理 | Provider | ^6.1.1 |
| 路由 | Navigator (push/pop) | 原生，无第三方路由库 |
| 图表 | fl_chart | ^0.66.0 |
| 地图 | flutter_map + latlong2 + map_launcher | ^7.0.0 / ^0.9.0 / ^3.0.0 |
| Excel 导出 | excel | ^4.0.0 |
| 本地存储 | shared_preferences | ^2.2.2 |
| 联系人导入 | flutter_contacts | ^1.1.9 |
| GPS 定位 | geolocator | ^10.1.0 |
| 文件选择 | file_picker | ^8.0.0 |
| 文件打开 | open_file | ^3.3.0 |
| 日期格式化 | intl | ^0.19.0 |
| 文件路径 | path_provider | ^2.1.0 |
| HTTP 请求 | http | ^1.2.0 |
| 静态分析 | flutter_lints | ^3.0.1 |

### Android 构建环境

| 组件 | 版本 |
|------|------|
| Gradle | 8.12 |
| AGP | 8.9.1 |
| Kotlin | 2.1.0 |
| Java | 17 |
| compileSdk | 34 |
| minSdk | flutter.minSdkVersion |
| JVM 堆 | Xmx2560m |

---

## 3. 项目目录结构

```
bbq_ledger/
├── lib/
│   ├── main.dart                          # 入口：初始化 Supabase，运行 App
│   ├── app.dart                           # MaterialApp + MultiProvider 注册 + 自动登录
│   ├── config/
│   │   └── supabase_config.dart           # Supabase URL / anonKey / serviceRoleKey
│   ├── models/
│   │   ├── user.dart                      # AppUser 模型
│   │   ├── customer.dart                  # Customer 模型（坐标编码在 notes JSON）
│   │   ├── product.dart                   # Product 模型（name + unit）
│   │   ├── order.dart                     # Order 模型 + OrderStatus 枚举
│   │   └── order_item.dart                # OrderItem 模型
│   ├── services/
│   │   ├── auth_service.dart              # 用户 CRUD、PIN 码登录验证
│   │   ├── customer_service.dart          # 客户 CRUD、搜索
│   │   ├── product_service.dart           # 货品 CRUD、历史单价/单位记忆
│   │   ├── order_service.dart             # 订单全生命周期管理
│   │   ├── inventory_service.dart         # 库存进出记录、库存统计
│   │   ├── report_service.dart            # 日报/月报数据聚合
│   │   └── export_service.dart            # Excel 导出（日报/月报）
│   ├── providers/
│   │   ├── auth_provider.dart             # 登录态、用户列表、自动登录
│   │   ├── order_provider.dart            # 四个订单列表管理 + 延期加载
│   │   └── report_provider.dart           # 月报数据状态
│   ├── screens/
│   │   ├── login_screen.dart              # 用户选择登录（PIN 码验证）
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
│   │   ├── inventory_screen.dart          # 库存管理（进出库记录、当前库存统计）
│   │   └── location_picker_screen.dart    # 地图选点（含防抖搜索）
│   └── widgets/
│       └── order_card.dart                # 订单卡片组件（通用）
├── supabase/
│   └── migrations/
│       ├── 001_initial_schema.sql         # 数据库初始建表 DDL
│       └── 002_inventory.sql              # 库存表 DDL
├── android/                               # Android 原生工程
├── test/
│   └── widget_test.dart                   # 占位测试
├── pubspec.yaml                           # Flutter 依赖配置
├── pubspec.lock
└── analysis_options.yaml
```

---

## 4. 架构设计

### 4.1 分层架构

```
┌─────────────────────────────────────────┐
│  UI Layer (screens/ + widgets/)         │
│  LoginScreen, HomeScreen, OrderPool...  │
├─────────────────────────────────────────┤
│  State Layer (providers/)               │
│  AuthProvider, OrderProvider,           │
│  ReportProvider (ChangeNotifier)        │
├─────────────────────────────────────────┤
│  Service Layer (services/)              │
│  AuthService, OrderService,             │
│  CustomerService, ProductService,       │
│  InventoryService, ReportService,       │
│  ExportService                          │
├─────────────────────────────────────────┤
│  Data Layer                              │
│  Supabase REST API → PostgreSQL          │
│  SharedPreferences (本地)                │
└─────────────────────────────────────────┘
```

### 4.2 状态管理

使用 **Provider + ChangeNotifier** 模式，共三个 Provider：

- **AuthProvider**: 管理 `currentUser`（当前登录用户）、`users`（用户列表）、`isLoggedIn`、`loading`。支持 `SharedPreferences` 自动登录（记住上次登录用户 ID）。
- **OrderProvider**: 管理四个订单列表：
  - `pendingOrders` — 待认领（status = 'pending'）
  - `myDeliveries` — 我的送货（status = 'claimed' + claimed_by = currentUser）
  - `unpaidOrders` — 未收款（status = 'delivered'）
  - `historyOrders` — 已完成（status = 'completed'）
  
  使用 `_initialized` 标志区分首次加载（显示 spinner）和后续刷新（静默更新）。使用 `Future.wait` 并行加载四个列表。
- **ReportProvider**: 管理 `MonthlyReport?` 月报数据、`loading` 状态。

### 4.3 路由

基于 Flutter 原生 `Navigator.push` / `pushReplacement` / `pushAndRemoveUntil`，无第三方路由库。登录成功后使用 `pushAndRemoveUntil` 清除返回栈，防止用户按返回键回到登录页。

### 4.4 应用入口流程

```
main.dart
  → Supabase.initialize(url, publishableKey)
  → runApp(BbqLedgerApp)
    → MultiProvider (AuthProvider, OrderProvider, ReportProvider)
    → tryAutoLogin() — 从 SharedPreferences 读取 last_user_id 实现自动登录
    → 已登录 → HomeScreen
    → 未登录 → LoginScreen
```

---

## 5. 数据库 Schema

### 5.1 表结构

| 表名 | 用途 | 关键字段 |
|------|------|---------|
| `users` | 用户 | `id`(UUID PK), `name`, `pin_code`, `avatar_color`, `created_at` |
| `customers` | 客户 | `id`(UUID PK), `name`, `phone`, `address`, `notes`(JSON，含坐标+历史单价偏好), `created_at` |
| `products` | 货品 | `id`(UUID PK), `name`(UNIQUE), `unit`, `created_at` |
| `orders` | 订单主表 | `id`(UUID PK), `customer_id`(FK), `created_by`(FK), `claimed_by`(FK), `status`(CHECK), `delivery_deadline`, `total_amount`, `is_paid`, `paid_at`, `delivered_at`, `created_at`, `updated_at` |
| `order_items` | 订单货品明细 | `id`(UUID PK), `order_id`(FK CASCADE), `product_id`(FK), `quantity`, `unit_price`, `subtotal`(GENERATED STORED), `unit`(TEXT) |
| `customer_product_prices` | 客户-货品历史单价 | `id`(UUID PK), `customer_id`(FK), `product_id`(FK), `unit_price`, `updated_at`, UNIQUE(customer_id, product_id) |
| `inventory_records` | 库存进出记录 | `id`(UUID PK), `product_id`(FK), `type`(CHECK: 'in'/'out'), `quantity`, `note`, `related_order_id`(FK, ON DELETE SET NULL), `created_at` |

### 5.2 坐标存储方案

客户坐标 (lat, lng) 和货品单价偏好存储在 `customers.notes` 字段的 JSON 中：

```json
{
  "lat": 30.5928,
  "lng": 114.3055,
  "product_prefs": {
    "<product_id>": {
      "unit": "包",
      "price": 35.0
    }
  }
}
```

### 5.3 订单状态流转

```
pending ──→ claimed ──→ delivered ──→ completed
(待认领)     (送货中)     (未收款)      (已完成)

操作人: 任何人认领   送货人送达    记账人收款
```

状态流转对应的 Service 方法：
- `claim(orderId, userId)` → pending → claimed
- `markDelivered(orderId)` → claimed → delivered（同时自动扣减库存）
- `markPaid(orderId)` → delivered → completed（设置 is_paid = true, paid_at）
- `transfer(orderId, toUserId)` → 转单给其他送货员（状态不变，claimed_by 变更）

### 5.4 RLS 策略

所有表均启用 RLS，使用 `CREATE POLICY "Allow all" ... USING (true)` 全放通策略（家庭内部使用场景，无外部用户）。

### 5.5 Supabase Realtime

`orders`、`order_items`、`inventory_records` 三张表已加入 `supabase_realtime` publication，支持实时数据同步。

---

## 6. 数据模型

### 6.1 AppUser

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | UUID 主键 |
| name | String | 用户名 |
| pinCode | String | PIN 码（登录凭证） |
| avatarColor | String | 头像颜色（十六进制，默认 #4CAF50） |

### 6.2 Customer

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | UUID 主键 |
| name | String | 客户名称 |
| phone | String | 电话 |
| address | String | 地址 |
| notes | String | JSON 字符串（坐标 + 货品偏好） |
| latitude | double? | 解析后的纬度 |
| longitude | double? | 解析后的经度 |

### 6.3 Product

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | UUID 主键 |
| name | String | 货品名称（唯一） |
| unit | String | 单位（默认"包"） |

### 6.4 Order

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String? | UUID 主键（新建时可为 null） |
| customerId | String | 客户 ID |
| customerName | String | 客户名称（JOIN 填充） |
| createdBy | String | 创建人 ID |
| createdByName | String | 创建人名称（JOIN 填充） |
| claimedBy | String? | 认领人 ID |
| claimedByName | String? | 认领人名称（JOIN 填充） |
| customerLatitude/longitude | double? | 客户坐标（从 notes JSON 解析） |
| customerAddress | String | 客户地址 |
| status | OrderStatus | 订单状态枚举 |
| deliveryDeadline | DateTime? | 送达截止时间 |
| totalAmount | double | 订单总金额 |
| isPaid | bool | 是否已收款 |
| paidAt | DateTime? | 收款时间 |
| deliveredAt | DateTime? | 送达时间 |
| createdAt | DateTime? | 创建时间 |
| items | List\<OrderItem\> | 订单货品明细 |

### 6.5 OrderItem

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String? | UUID 主键 |
| productId | String | 货品 ID |
| productName | String | 货品名称（JOIN 填充） |
| productUnit | String | 货品单位 |
| quantity | double | 数量 |
| unitPrice | double | 单价 |
| subtotal | double | 小计（quantity × unitPrice） |

### 6.6 InventoryRecord

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | UUID 主键 |
| productId | String | 货品 ID |
| productName | String | 货品名称（JOIN 填充） |
| productUnit | String | 货品单位 |
| type | String | 'in'（入库）或 'out'（出库） |
| quantity | double | 数量 |
| note | String | 备注 |
| relatedOrderId | String? | 关联订单 ID |
| createdAt | DateTime | 创建时间 |

### 6.7 ProductStock

| 字段 | 类型 | 说明 |
|------|------|------|
| productId | String | 货品 ID |
| productName | String | 货品名称 |
| productUnit | String | 货品单位 |
| totalIn | double | 总入库量 |
| totalOut | double | 总出库量 |
| current | double | 当前库存（计算属性 = totalIn - totalOut） |

---

## 7. 业务逻辑

### 7.1 用户认证

- 无传统注册/密码，使用 **PIN 码** 方式登录
- 用户列表从 Supabase 加载，用户选择自己的头像后输入 PIN 码验证
- 支持 `SharedPreferences` 自动登录（记住 `last_user_id`）
- 用户角色未做严格区分，所有用户可执行所有操作

### 7.2 订单生命周期

```
1. 创建订单 (new_order_screen)
   → 选择客户 → 添加货品（数量、单价、单位）→ 设置送达时间
   → 入库: orders (status='pending') + order_items

2. 认领订单 (order_pool_screen)
   → 送货员在订单池中认领 → orders.status='claimed', claimed_by=当前用户

3. 确认送达 (my_deliveries_screen)
   → 送货员确认送达 → orders.status='delivered', delivered_at=now
   → 自动扣减库存: inventory_records (type='out', note='订单出货')

4. 确认收款 (unpaid_screen)
   → 记账人确认收款 → orders.status='completed', is_paid=true, paid_at=now

5. 转单 (my_deliveries_screen)
   → 送货员将订单转给其他送货员 → orders.claimed_by 变更
```

### 7.3 历史单价记忆

下单时选择货品后，自动从 `customer_product_prices` 表和 `customers.notes.product_prefs` JSON 中读取该客户-货品的历史单价和单位，填充到下单表单中。

### 7.4 库存管理

- **入库**: 在 `inventory_screen` 手动录入（type='in'）
- **出库**: 确认送达时自动扣减（type='out', related_order_id 关联订单），也可手动录入
- **库存查询**: 优先通过 Supabase RPC `get_inventory_stock` 获取，失败时回退到 Dart 端计算汇总
- 历史记录最多返回 200 条

### 7.5 日报/月报

- **日报**: 按北京时间 (UTC+8) 统计当日所有订单
  - 客户 × 货品 销量交叉表（透视表）
  - 货品金额汇总
  - 客户汇总（订单数 + 金额）
- **月报**: 按 `paid_at` 统计当月已完成订单
  - 货品销量 + 金额汇总
  - 总营业额 + 订单数
- 支持 Excel 导出（`.xlsx` 格式）

### 7.6 历史搜索

支持**组合关键词**搜索（空格分隔），例如 "王老板 鸡柳"：
1. 在 `customers` 表中模糊匹配客户名称
2. 在 `order_items` 中匹配货品名称
3. 取交集（AND 逻辑），返回同时匹配客户和货品的订单

---

## 8. 密钥与配置

### 8.1 Supabase 连接

| 密钥名称 | 值 | 文件位置 |
|---------|-----|---------|
| url | `https://wtoukdzykvuoycrolpfq.supabase.co` | `lib/config/supabase_config.dart` |
| anonKey | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (service_role JWT) | `lib/config/supabase_config.dart` |
| serviceRoleKey | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (同 anonKey) | `lib/config/supabase_config.dart` |
| 项目 Ref | `wtoukdzykvuoycrolpfq` | 从 URL/JWT 提取 |

> ⚠️ **安全警告**: 当前 `anonKey` 实际是 `service_role` key（权限过高，可绕过 RLS）。生产环境应替换为真正的 `anon` public key。

### 8.2 MCP 服务

| 密钥名称 | 值 | 文件位置 |
|---------|-----|---------|
| mcpServers.supabase.url | `https://mcp.supabase.com/mcp` | `.mcp.json` |

### 8.3 HTTP 代理（Gradle 构建）

| 配置项 | 值 | 文件位置 |
|--------|-----|---------|
| systemProp.http.proxyHost | `127.0.0.1` | `android/gradle.properties` |
| systemProp.http.proxyPort | `18080` | `android/gradle.properties` |
| systemProp.https.proxyHost | `127.0.0.1` | `android/gradle.properties` |
| systemProp.https.proxyPort | `18080` | `android/gradle.properties` |

### 8.4 APK 签名

当前使用 **debug keystore** 签名（`signingConfig = signingConfigs.getByName("debug")`）。上架应用商店前需配置正式签名。

---

## 9. 构建与运行

### 9.1 前置条件

- Flutter SDK 3.38+
- Java 17
- Android SDK (compileSdk 34)
- Gradle 8.12

### 9.2 常用命令

```bash
# 安装依赖
cd bbq_ledger && flutter pub get

# 开发运行
flutter run

# Release 模式运行
flutter run --release

# 构建 arm64 APK
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

### 9.3 构建产物位置

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-release.apk
```

---

## 10. 性能优化

1. **并行加载**: `OrderProvider.loadAll()` 使用 `Future.wait` 并行加载四个订单列表。`HistoryScreen` 使用 `Future.wait` 并行加载所有订单的 items。
2. **延期加载**: `OrderProvider` 使用 `_initialized` 标志，首次加载显示 spinner，后续刷新静默更新（避免 UI 闪烁）。
3. **去重刷新**: 子页面返回时不再重复刷新 HomeScreen，各子页面内部自行处理数据更新。
4. **搜索防抖**: `LocationPickerScreen` 使用 500ms debounce 避免地址搜索请求风暴。
5. **库存回退**: 库存统计优先使用 Supabase RPC，失败时自动回退到 Dart 端计算。

---

## 11. 已知问题与注意事项

1. **Supabase Key 权限过高**: `anonKey` 实际使用 `service_role` key，客户端拥有数据库管理员权限。
2. **APK 签名**: 使用 debug keystore，上架前需配置正式签名。
3. **代理配置**: `gradle.properties` 中配置了 HTTP 代理 (`127.0.0.1:18080`)，本地环境需移除。
4. **数据库 `unit` 列**: `order_items` 表需要 `unit text` 列，初始 migration 中未包含，需手动执行 `ALTER TABLE order_items ADD COLUMN IF NOT EXISTS unit text;`。
5. **iOS 未配置**: 项目仅配置了 Android 端。
6. **测试覆盖**: 仅有一个占位 smoke test，业务逻辑无单元测试。
7. **Web 支持**: pubspec.yaml 未显式声明 web 平台，但 Flutter 默认包含 web 编译能力。
8. **货品单位硬编码**: 仅支持 3 个单位：包、件、条（`new_order_screen.dart` 中 `_commonUnits`）。
9. **库存记录限制**: 历史记录最多返回 200 条，无分页。
10. **Maven 镜像**: 使用阿里云镜像加速 Gradle 依赖下载。

---

## 12. 版本历史

| 版本 | 说明 |
|------|------|
| 1.0.0+1 | 初始版本：基础订单管理、客户/货品管理 |
| 1.1.0+2 | 新增日报/月报统计、Excel 导出、地图导航 |
| 1.2.0+3 | 新增库存管理、历史搜索、通讯录导入、UI 优化 |