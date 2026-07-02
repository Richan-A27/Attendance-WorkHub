import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_response.dart';

final dashboardRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return DashboardRepository(dio);
});

final dashboardSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getSummary();
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _dio.get('/dashboard');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to load dashboard summary: $e');
    }
  }

  Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final response = await _dio.get('/device/status');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load device status: $e');
    }
  }
}

final deviceStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDeviceStatus();
});
