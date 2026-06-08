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
                      '$_selectedYear年$_selectedMonth月',
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
                            final idx = reportProvider.report!.productSummaries.indexOf(s);
                            return BarChartGroupData(
                              x: idx,
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
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                        ),
                      ),
                    ),
                  ),

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