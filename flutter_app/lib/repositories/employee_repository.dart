import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/employee.dart';

final employeeRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return EmployeeRepository(dio);
});

final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  final repository = ref.watch(employeeRepositoryProvider);
  return repository.getEmployees();
});

class EmployeeRepository {
  final Dio _dio;

  EmployeeRepository(this._dio);

  Future<List<Employee>> getEmployees() async {
    try {
      final response = await _dio.get('/employees');
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data,
        (data) => data as List<dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.map((e) => Employee.fromJson(e)).toList();
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to load employees: $e');
    }
  }

  Future<void> updateHourlyRate(int id, double rate) async {
    try {
      final response = await _dio.patch(
        '/employees/$id/hourly-rate',
        data: rate,
        options: Options(contentType: 'application/json'),
      );
      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        (data) => data,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to update hourly rate: $e');
    }
  }
}
