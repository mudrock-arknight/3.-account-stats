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
import 'daily_report_screen.dart';
import 'product_management_screen.dart';
import 'customer_management_screen.dart';
import 'import_screen.dart';
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
        title: const Text('记账本'),
        actions: [
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
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('每日总表'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyReportScreen()),
                  ),
                ),
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
                  leading: const Icon(Icons.people),
                  title: const Text('客户管理'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerManagementScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('货品管理'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductManagementScreen()),
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
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('导入历史账单'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportScreen()),
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
        elevation: 2,
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}