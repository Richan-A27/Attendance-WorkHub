import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

final reportsRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return ReportsRepository(dio);
});

final weeklyReportProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  final dateStr =
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  return ref.watch(reportsRepositoryProvider).getWeeklyReport(dateStr);
});

final monthlyReportProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  return ref.watch(reportsRepositoryProvider).getMonthlyReport(date.month, date.year);
});

class ReportsRepository {
  final Dio _dio;
  ReportsRepository(this._dio);

  Future<Map<String, dynamic>> getWeeklyReport(String date) async {
    final response = await _dio.get('/reports/weekly/$date');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    final response = await _dio.get('/reports/monthly/$month/$year');
    return response.data as Map<String, dynamic>;
  }
}
