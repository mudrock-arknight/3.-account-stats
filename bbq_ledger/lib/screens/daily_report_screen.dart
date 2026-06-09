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
        title: const Text('每日总表'),
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
                      Row(
                        children: [
                          _SummaryCard(title: '当日营业额', value: '¥${currencyFormat.format(_report!.totalAmount)}', color: Colors.orange),
                          const SizedBox(width: 12),
                          _SummaryCard(title: '订单数', value: '${_report!.orderCount}笔', color: Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                                          child: Text(_report!.productSummaries[index].productName, style: const TextStyle(fontSize: 10)),
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