import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/attendance_log.dart';

final attendanceRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return AttendanceRepository(dio);
});

final attendanceLogsProvider = FutureProvider<List<AttendanceLog>>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getAttendanceLogs();
});

class AttendanceRepository {
  final Dio _dio;

  AttendanceRepository(this._dio);

  Future<List<AttendanceLog>> getAttendanceLogs() async {
    try {
      final response = await _dio.get('/attendance');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success &&
          apiResponse.data != null &&
          apiResponse.data!['content'] != null) {
        final List<dynamic> content = apiResponse.data!['content'];
        return content.map((e) => AttendanceLog.fromJson(e)).toList();
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to load attendance logs: $e');
    }
  }
}
