# BBQ Ledger v1.1.0+2 编译发布计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 编译最新版 APK（split-per-abi），上传到 Supabase Storage 统一下载地址，清理多余代码，推送到 Git。

**Architecture:** Flutter 3.44.1 + Dart 3.10.9 + Gradle 8.12 + Java 17 + Android SDK 34，使用阿里云 Maven 镜像加速国内构建，`--split-per-abi` 生成 arm64-v8a / armeabi-v7a / x86_64 三份 APK 覆盖大多数安卓手机。

**Tech Stack:** Flutter, Supabase, Gradle, Android SDK

---

## 现状确认

6 项功能需求全部在代码中实现：

1. **六宫格字体调大** - `home_screen.dart:207` fontSize 15, fontWeight w700, icon 32
2. **订单总览时间段选择** - `order_overview_screen.dart:21-53` 默认今天，DatePicker 选择
3. **通讯录导入修复** - `customer_management_screen.dart:182` requestPermission 直接调用，`customer_management_screen.dart:245-257` 全选/取消全选
4. **货品管理客户价格表** - `product_management_screen.dart:61-82` 展开后显示价格，支持搜索客户
5. **库存管理** - `inventory_screen.dart` 汇总、出入库记录、筛选；`inventory_service.dart` 完整 CRUD
6. **不清楚要问** - AGENTS.md 永久规则

关键 Bug 修复：
- `app.dart` StatefulWidget + auto-login（修复启动一直加载）
- `login_screen.dart` 删除重复自动登录（修复死循环）
- `order_service.dart` markDelivered 自动扣减库存

---

### Task 1: 移除代理配置（修复 Gradle 网络问题）

**Files:**
- Modify: `/workspace/bbq_ledger/android/gradle.properties`

- [ ] **Step 1: 移除 gradle.properties 中的代理配置**

当前 `gradle.properties` 中包含 `-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=18080` 代理配置，但该代理未运行，会导致 Gradle 下载失败。移除代理相关 JVM 参数。

修改前：
```
org.gradle.jvmargs=-Xmx3072m -XX:MaxMetaspaceSize=512m -XX:ReservedCodeCacheSize=256m -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=18080 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=18080 -Dhttps.protocols=TLSv1.2,TLSv1.3 -Djdk.tls.client.protocols=TLSv1.2,TLSv1.3
```

修改后：
```
org.gradle.jvmargs=-Xmx3072m -XX:MaxMetaspaceSize=512m -XX:ReservedCodeCacheSize=256m -Dhttps.protocols=TLSv1.2,TLSv1.3 -Djdk.tls.client.protocols=TLSv1.2,TLSv1.3
```

- [ ] **Step 2: 验证 gradle.properties 修改成功**

Run: `grep -c "proxyHost" /workspace/bbq_ledger/android/gradle.properties`
Expected: `0`

---

### Task 2: 安装 Flutter 依赖

**Files:**
- Modify: `/workspace/bbq_ledger/pubspec.lock`

- [ ] **Step 1: 运行 flutter pub get**

```bash
cd /workspace/bbq_ledger && /usr/local/flutter/bin/flutter pub get
```

Expected: 成功，无错误

- [ ] **Step 2: 验证依赖安装**

Run: `ls /workspace/bbq_ledger/pubspec.lock`
Expected: 文件存在

---

### Task 3: 编译 APK (split-per-abi)

**Files:**
- Create: `/workspace/bbq_ledger/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- Create: `/workspace/bbq_ledger/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- Create: `/workspace/bbq_ledger/build/app/outputs/flutter-apk/app-x86_64-release.apk`

- [ ] **Step 1: 清理旧构建产物**

```bash
cd /workspace/bbq_ledger && /usr/local/flutter/bin/flutter clean
```

- [ ] **Step 2: 编译 release APK (split-per-abi)**

```bash
cd /workspace/bbq_ledger && /usr/local/flutter/bin/flutter build apk --release --split-per-abi
```

Expected: 成功生成三个 APK 文件

- [ ] **Step 3: 验证 APK 生成**

```bash
ls -lh /workspace/bbq_ledger/build/app/outputs/flutter-apk/app-*.apk
```

Expected: 三个 APK 文件存在，大小合理（arm64-v8a ~15MB, armeabi-v7a ~15MB, x86_64 ~16MB）

---

### Task 4: 上传 APK 到 Supabase Storage

**Files:**
- Modify: Supabase Storage bucket `apk-releases`

- [ ] **Step 1: 上传三个 APK 到 Supabase Storage**

使用 Supabase Management API 上传 APK 文件到 `apk-releases` bucket：

```bash
# 使用 curl 上传到 Supabase Storage
# Bucket: apk-releases
# Files: app-armeabi-v7a-release.apk, app-arm64-v8a-release.apk, app-x86_64-release.apk
```

Supabase URL: `https://wtoukdzykvuoycrolpfq.supabase.co`
Service Role Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0b3VrZHp5a3Z1b3ljcm9scGZxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg0ODk0OSwiZXhwIjoyMDk2NDI0OTQ5fQ.B5v_I2-ZHGMRbElpt1Xbfd-3w8wa_DgLuKYPh12MT0w`

- [ ] **Step 2: 确认上传成功，获取下载 URL**

列出 bucket 中的文件确认上传成功。

---

### Task 5: 清理无用文件并提交 Git

**Files:**
- Delete: `/workspace/bbq_ledger/AGENTS.md` (如果确定不需要)
- Modify: `/workspace/bbq_ledger/.gitignore`

- [ ] **Step 1: 检查是否有无用文件**

```bash
cd /workspace/bbq_ledger && git status
```

- [ ] **Step 2: 确保 .gitignore 正确**

确保 `.gitignore` 包含：
```
.dart_tool/
.packages
build/
*.apk
*.jks
*.key
*.keystore
.mcp.json
```

- [ ] **Step 3: 提交并推送**

```bash
cd /workspace/bbq_ledger
git add -A
git commit -m "release: v1.1.0+2 - 六项功能改进 + 库存管理 + 启动修复"
git push
```

---

### 执行确认清单

- [ ] 6 项功能全部在代码中实现
- [ ] app.dart 自动登录修复（StatefulWidget）
- [ ] login_screen.dart 无重复自动登录
- [ ] markDelivered 自动扣减库存
- [ ] 代理配置已移除
- [ ] APK 编译成功（3 个 ABI）
- [ ] APK 上传到 Supabase Storage
- [ ] 代码推送到 Git