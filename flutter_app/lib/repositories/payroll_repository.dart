import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/pay_period.dart';
import '../models/payroll_record.dart';

final payrollRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return PayrollRepository(dio);
});

// --- Riverpod providers ---

/// Fetches payroll records for a specific pay period ID.
final periodPayrollProvider =
    FutureProvider.family<List<PayrollRecord>, int>((ref, payPeriodId) async {
  final repo = ref.watch(payrollRepositoryProvider);
  return repo.getPayrollByPeriod(payPeriodId);
});

/// Kept for backward compat — fetches payroll by calendar month/year.
final monthlyPayrollProvider =
    FutureProvider.family<List<PayrollRecord>, DateTime>((ref, date) async {
  final repository = ref.watch(payrollRepositoryProvider);
  return repository.getMonthlyPayroll(date.month, date.year);
});

/// Fetches all open/processing pay periods for the pay period picker.
final openPayPeriodsProvider = FutureProvider<List<PayPeriod>>((ref) async {
  final repo = ref.watch(payrollRepositoryProvider);
  return repo.getOpenPayPeriods();
});

/// Fetches all pay periods.
final allPayPeriodsProvider = FutureProvider<List<PayPeriod>>((ref) async {
  final repo = ref.watch(payrollRepositoryProvider);
  return repo.getPayPeriods();
});

class PayrollRepository {
  final Dio _dio;

  PayrollRepository(this._dio);

  // ── Period-based (new) ────────────────────────────────────────────────────

  /// Generates payroll for all active employees in a pay period.
  /// [calculationMode] is the global mode: "INCLUDE_BREAKS" or "EXCLUDE_BREAKS".
  /// [overrides] is a list of per-employee exceptions: [{"employeeId": 5, "calculationMode": "EXCLUDE_BREAKS"}]
  Future<List<PayrollRecord>> generatePayroll({
    required int payPeriodId,
    required String calculationMode,
    List<Map<String, dynamic>> overrides = const [],
  }) async {
    try {
      final response = await _dio.post('/payroll/generate', data: {
        'payPeriodId': payPeriodId,
        'calculationMode': calculationMode,
        'overrides': overrides,
      });
      if (response.data is List) {
        return (response.data as List)
            .map((e) => PayrollRecord.fromJson(e))
            .toList();
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to generate payroll: $e');
    }
  }

  /// Returns both INCLUDE_BREAKS and EXCLUDE_BREAKS computed values without persisting.
  Future<List<Map<String, dynamic>>> previewPayroll(int payPeriodId) async {
    try {
      final response = await _dio.get('/payroll/preview/$payPeriodId');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Unexpected preview response format');
    } catch (e) {
      throw Exception('Failed to load payroll preview: $e');
    }
  }

  /// Fetches payroll records for a specific pay period.
  Future<List<PayrollRecord>> getPayrollByPeriod(int payPeriodId) async {
    try {
      final response = await _dio.get('/payroll/period/$payPeriodId');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => PayrollRecord.fromJson(e))
            .toList();
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to load payroll for period: $e');
    }
  }

  /// Marks a single employee's payroll record as PAID.
  Future<PayrollRecord> markPayrollPaid(
      int employeeId, int payPeriodId) async {
    try {
      final response =
          await _dio.put('/payroll/mark-paid/$employeeId/$payPeriodId');
      return PayrollRecord.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to mark payroll as paid: $e');
    }
  }

  // ── Pay Period management ─────────────────────────────────────────────────

  /// Returns all pay periods ordered by start_date DESC.
  Future<List<PayPeriod>> getPayPeriods() async {
    try {
      final response = await _dio.get('/pay-periods');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => PayPeriod.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load pay periods: $e');
    }
  }

  /// Returns OPEN and PROCESSING pay periods for the period picker.
  Future<List<PayPeriod>> getOpenPayPeriods() async {
    try {
      final response = await _dio.get('/pay-periods/open');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => PayPeriod.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load open pay periods: $e');
    }
  }

  /// Creates a new pay period.
  Future<PayPeriod> createPayPeriod({
    required String name,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.post('/pay-periods', data: {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
      });
      return PayPeriod.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create pay period: $e');
    }
  }

  /// Updates the status of a pay period.
  Future<PayPeriod> updatePayPeriodStatus(int id, String status) async {
    try {
      final response = await _dio.put('/pay-periods/$id/status', data: {
        'status': status,
      });
      return PayPeriod.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update pay period status: $e');
    }
  }

  /// Deletes an OPEN pay period.
  Future<void> deletePayPeriod(int id) async {
    try {
      await _dio.delete('/pay-periods/$id');
    } catch (e) {
      throw Exception('Failed to delete pay period: $e');
    }
  }

  // ── Month-based (kept for backward compat) ────────────────────────────────

  /// Fetches payroll records by calendar month/year.
  Future<List<PayrollRecord>> getMonthlyPayroll(int month, int year) async {
    try {
      final response = await _dio.get('/payroll/month/$month/$year');
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

  /// Calculates payroll for all employees for a given month.
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
