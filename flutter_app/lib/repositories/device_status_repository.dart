import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

final deviceStatusRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return DeviceStatusRepository(dio);
});

final deviceStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(deviceStatusRepositoryProvider);
  return repo.getDeviceStatus();
});

final diagnosticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(deviceStatusRepositoryProvider);
  return repo.getDiagnostics();
});

class DeviceStatusRepository {
  final Dio _dio;
  DeviceStatusRepository(this._dio);

  Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final response = await _dio.get('/operations/device-status');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load device status: $e');
    }
  }

  Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final response = await _dio.get('/operations/diagnostics');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load diagnostics: $e');
    }
  }

  Future<void> triggerManualSync() async {
    await _dio.post('/operations/manual-sync');
  }
}
