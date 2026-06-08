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