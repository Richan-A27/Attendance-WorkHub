import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/payroll_record.dart';

final payrollRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return PayrollRepository(dio);
});

final monthlyPayrollProvider =
    FutureProvider.family<List<PayrollRecord>, DateTime>((ref, date) async {
  final repository = ref.watch(payrollRepositoryProvider);
  return repository.getMonthlyPayroll(date.month, date.year);
});

class PayrollRepository {
  final Dio _dio;

  PayrollRepository(this._dio);

  Future<List<PayrollRecord>> getMonthlyPayroll(int month, int year) async {
    try {
      final response = await _dio.get('/payroll/month/$month/$year');

      // Payroll controller returns List directly, not wrapped in ApiResponse
      if (response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((e) => PayrollRecord.fromJson(e)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Failed to load payroll records: $e');
    }
  }

  Future<void> processAllPayroll(int month, int year) async {
    try {
      final response = await _dio.post('/payroll/calculate-all/$month/$year');
      if (response.statusCode != 200) {
        throw Exception('Failed to calculate payroll');
      }
    } catch (e) {
      throw Exception('Failed to process payroll: $e');
    }
  }
}
