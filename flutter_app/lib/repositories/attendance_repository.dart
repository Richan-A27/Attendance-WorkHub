import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/attendance_log.dart';
import '../models/daily_attendance.dart';
import '../models/attendance_break.dart';
import '../models/attendance_session.dart';

final attendanceRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return AttendanceRepository(dio);
});

final attendanceLogsProvider = FutureProvider<List<AttendanceLog>>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getAttendanceLogs();
});

final dailyAttendanceProvider = FutureProvider.family<List<DailyAttendance>, String>((ref, date) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getDailyAttendance(date);
});

final attendanceBreaksProvider = FutureProvider.family<List<AttendanceBreak>, String>((ref, param) async {
  final parts = param.split('/');
  final employeeId = int.parse(parts[0]);
  final date = parts[1];
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getAttendanceBreaks(employeeId, date);
});

final attendanceSessionsProvider = FutureProvider.family<List<AttendanceSession>, String>((ref, param) async {
  final parts = param.split('/');
  final employeeId = int.parse(parts[0]);
  final date = parts[1];
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getAttendanceSessions(employeeId, date);
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

  Future<List<DailyAttendance>> getDailyAttendance(String date) async {
    try {
      final response = await _dio.get('/intelligence/daily/range', queryParameters: {
        'startDate': date,
        'endDate': date,
      });
      final List<dynamic> data = response.data;
      return data.map((e) => DailyAttendance.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load daily attendance: $e');
    }
  }

  Future<List<AttendanceBreak>> getAttendanceBreaks(int employeeId, String date) async {
    try {
      final response = await _dio.get('/intelligence/breaks/$employeeId/$date');
      final List<dynamic> data = response.data;
      return data.map((e) => AttendanceBreak.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load attendance breaks: $e');
    }
  }

  Future<List<AttendanceSession>> getAttendanceSessions(int employeeId, String date) async {
    try {
      final response = await _dio.get('/intelligence/sessions/$employeeId/$date');
      final List<dynamic> data = response.data;
      return data.map((e) => AttendanceSession.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load attendance sessions: $e');
    }
  }
}
