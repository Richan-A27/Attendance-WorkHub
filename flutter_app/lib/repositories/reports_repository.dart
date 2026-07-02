import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

final reportsRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return ReportsRepository(dio);
});

final currentWeeklyReportProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(reportsRepositoryProvider).getCurrentWeeklyReport();
});

final currentMonthlyReportProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(reportsRepositoryProvider).getCurrentMonthlyReport();
});

class ReportsRepository {
  final Dio _dio;
  ReportsRepository(this._dio);

  Future<Map<String, dynamic>> getCurrentWeeklyReport() async {
    final response = await _dio.get('/reports/weekly/current');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCurrentMonthlyReport() async {
    final response = await _dio.get('/reports/monthly/current');
    return response.data as Map<String, dynamic>;
  }
}
