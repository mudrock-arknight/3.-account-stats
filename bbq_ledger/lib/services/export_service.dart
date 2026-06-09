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

    sheet.appendRow([TextCellValue('每日总表')]);
    sheet.appendRow([TextCellValue('日期: $dateStr')]);
    sheet.appendRow([TextCellValue('总营业额: ¥${_currencyFormat.format(report.totalAmount)}   订单数: ${report.orderCount}笔')]);
    sheet.appendRow([]);

    // === PIVOT TABLE ===
    sheet.appendRow([TextCellValue('客户 × 品类 销量交叉表')]);

    final allCustomers = <String>{};
    for (final row in report.customerProductRows) {
      allCustomers.addAll(row.customerQuantities.keys);
    }
    final sortedCustomers = allCustomers.toList()..sort();

    final pivotHeader = <CellValue>[TextCellValue('品类')];
    for (final c in sortedCustomers) {
      pivotHeader.add(TextCellValue(c));
    }
    pivotHeader.add(TextCellValue('合计'));
    sheet.appendRow(pivotHeader);

    for (final row in report.customerProductRows) {
      final label = '${row.productName}(${row.productUnit})';
      final dataRow = <CellValue>[TextCellValue(label)];
      for (final c in sortedCustomers) {
        final qty = row.customerQuantities[c] ?? 0;
        dataRow.add(DoubleCellValue(qty));
      }
      dataRow.add(DoubleCellValue(row.totalQuantity));
      sheet.appendRow(dataRow);
    }

    sheet.appendRow([]);

    // Product summary
    sheet.appendRow([TextCellValue('货品金额汇总')]);
    sheet.appendRow([TextCellValue('货品'), TextCellValue('销量'), TextCellValue('单位'), TextCellValue('金额')]);
    for (final p in report.productSummaries) {
      sheet.appendRow([
        TextCellValue(p.productName),
        TextCellValue(p.totalQuantity.toString()),
        TextCellValue(p.productUnit),
        TextCellValue('¥${_currencyFormat.format(p.totalAmount)}'),
      ]);
    }

    sheet.appendRow([]);

    // Customer summary
    sheet.appendRow([TextCellValue('客户汇总')]);
    sheet.appendRow([TextCellValue('客户名称'), TextCellValue('订单数'), TextCellValue('金额')]);
    for (final c in report.customerSummaries) {
      sheet.appendRow([
        TextCellValue(c.customerName),
        IntCellValue(c.orderCount),
        TextCellValue('¥${_currencyFormat.format(c.totalAmount)}'),
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