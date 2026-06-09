# 记账本 V2 改进实现# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter +# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增:# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
|# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_s# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/prov# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 |# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.d# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart`# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provid# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id`，导致 LoginScreen 自动登录回同一个用户。

- [ ] **Step 1: 在 logout() 中清除 last_user_id**

修改 `lib/pro# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id`，导致 LoginScreen 自动登录回同一个用户。

- [ ] **Step 1: 在 logout() 中清除 last_user_id**

修改 `lib/providers/auth_provider.dart`，将 logout 方法改为：

```dart
Future<void# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id`，导致 LoginScreen 自动登录回同一个用户。

- [ ] **Step 1: 在 logout() 中清除 last_user_id**

修改 `lib/providers/auth_provider.dart`，将 logout 方法改为：

```dart
Future<void> logout() async {
  _currentUser = null;
  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('last_user_id');
}# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id`，导致 LoginScreen 自动登录回同一个用户。

- [ ] **Step 1: 在 logout() 中清除 last_user_id**

修改 `lib/providers/auth_provider.dart`，将 logout 方法改为：

```dart
Future<void> logout() async {
  _currentUser = null;
  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('last_user_id');
}
```

---

### Task 2: 首页田字排列 + 新入口

**Files# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id`，导致 LoginScreen 自动登录回同一个用户。

- [ ] **Step 1: 在 logout() 中清除 last_user_id**

修改 `lib/providers/auth_provider.dart`，将 logout 方法改为：

```dart
Future<void> logout() async {
  _currentUser = null;
  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('last_user_id');
}
```

---

### Task 2: 首页田字排列 + 新入口

**Files:**
- Modify: `lib/screens/home_screen.dart`

**需求:**# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id`，导致 LoginScreen 自动登录回同一个用户。

- [ ] **Step 1: 在 logout() 中清除 last_user_id**

修改 `lib/providers/auth_provider.dart`，将 logout 方法改为：

```dart
Future<void> logout() async {
  _currentUser = null;
  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('last_user_id');
}
```

---

### Task 2: 首页田字排列 + 新入口

**Files:**
- Modify: `lib/screens/home_screen.dart`

**需求:** 将四个快速操作按钮改为 2x2 田字 GridView，不再# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id`，导致 LoginScreen 自动登录回同一个用户。

- [ ] **Step 1: 在 logout() 中清除 last_user_id**

修改 `lib/providers/auth_provider.dart`，将 logout 方法改为：

```dart
Future<void> logout() async {
  _currentUser = null;
  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('last_user_id');
}
```

---

### Task 2: 首页田字排列 + 新入口

**Files:**
- Modify: `lib/screens/home_screen.dart`

**需求:** 将四个快速操作按钮改为 2x2 田字 GridView，不再需要横向滚动。增加"货品管理"和"每日报表"入口。

-# 记账本 V2 改进实现计划

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现16项用户反馈的功能改进，覆盖首页布局、新建订单、货品管理、报表导出等模块。

**Architecture:** 基于现有 Flutter + Supabase 架构，采用 Provider 状态管理。修改现有 screen/service/provider 文件，新增货品管理页面、每日报表页面。数据层保持不变，前端新增搜索、过滤、导出等交互能力。

**Tech Stack:** Flutter 3.38.10, Dart 3.10.9, supabase_flutter ^2.3.0, provider ^6.1.1, fl_chart ^0.66.0, intl ^0.19.0, 新增: excel (Excel导出), share_plus (文件分享), path_provider (文件路径)

---

## 文件结构总览

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `lib/providers/auth_provider.dart` | logout 时清除 last_user_id |
| 修改 | `lib/screens/home_screen.dart` | 田字布局 + 新页面入口 |
| 修改 | `lib/screens/new_order_screen.dart` | 客户/货品搜索、UI优化、总价显示 |
| 修改 | `lib/screens/history_screen.dart` | 搜索过滤功能 |
| 修改 | `lib/screens/order_pool_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/my_deliveries_screen.dart` | 显示送达时间 |
| 修改 | `lib/screens/unpaid_screen.dart` | 显示要求送达+实际送达时间 |
| 修改 | `lib/screens/monthly_report_screen.dart` | 数轴改为金额，添加导出按钮 |
| 修改 | `lib/widgets/order_card.dart` | 显示送达时间信息 |
| 修改 | `lib/services/report_service.dart` | 添加每日报表查询 |
| 修改 | `lib/services/product_service.dart` | 添加搜索方法 |
| 修改 | `lib/providers/report_provider.dart` | 支持每日报表 |
| 创建 | `lib/screens/product_management_screen.dart` | 货品管理（增删）|
| 创建 | `lib/screens/daily_report_screen.dart` | 每日总表汇总 |
| 创建 | `lib/services/export_service.dart` | Excel 导出 + 分享 |
| 修改 | `pubspec.yaml` | 添加 excel, share_plus, path_provider 依赖 |

---

### Task 1: 修复切换用户功能

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**问题:** logout() 没有清除 SharedPreferences 中的 `last_user_id`，导致 LoginScreen 自动登录回同一个用户。

- [ ] **Step 1: 在 logout() 中清除 last_user_id**

修改 `lib/providers/auth_provider.dart`，将 logout 方法改为：

```dart
Future<void> logout() async {
  _currentUser = null;
  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('last_user_id');
}
```

---

### Task 2: 首页田字排列 + 新入口

**Files:**
- Modify: `lib/screens/home_screen.dart`

**需求:** 将四个快速操作按钮改为 2x2 田字 GridView，不再需要横向滚动。增加"货品管理"和"每日报表"入口。

- [ ] **Step 1: 替换快速操作为 2x2 GridView