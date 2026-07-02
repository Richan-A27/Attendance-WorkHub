import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/work_schedule.dart';
import '../models/holiday.dart';

final scheduleRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return ScheduleRepository(dio);
});

final workSchedulesProvider = FutureProvider<List<WorkSchedule>>((ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getAllWorkSchedules();
});

final holidaysProvider = FutureProvider<List<Holiday>>((ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getAllHolidays();
});

class ScheduleRepository {
  final Dio _dio;

  ScheduleRepository(this._dio);

  Future<List<WorkSchedule>> getAllWorkSchedules() async {
    try {
      final response = await _dio.get('/schedules/work-schedules');
      final List<dynamic> data = response.data;
      return data.map((e) => WorkSchedule.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load work schedules: $e');
    }
  }

  Future<WorkSchedule> saveWorkSchedule(WorkSchedule schedule) async {
    try {
      final response = await _dio.post(
        '/schedules/work-schedules',
        data: schedule.toJson(),
      );
      return WorkSchedule.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save work schedule: $e');
    }
  }

  Future<List<Holiday>> getAllHolidays() async {
    try {
      final response = await _dio.get('/schedules/holidays');
      final List<dynamic> data = response.data;
      return data.map((e) => Holiday.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load holidays: $e');
    }
  }

  Future<Holiday> saveHoliday(Holiday holiday) async {
    try {
      final response = await _dio.post(
        '/schedules/holidays',
        data: holiday.toJson(),
      );
      return Holiday.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save holiday: $e');
    }
  }
}
