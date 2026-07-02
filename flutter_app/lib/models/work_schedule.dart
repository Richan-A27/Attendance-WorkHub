import 'package:flutter/material.dart';

class WorkSchedule {
  final int? id;
  final int employeeId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int lunchDurationMinutes;
  final int gracePeriodMinutes;
  final List<String> workDays;
  final bool active;

  WorkSchedule({
    this.id,
    required this.employeeId,
    required this.startTime,
    required this.endTime,
    this.lunchDurationMinutes = 45,
    this.gracePeriodMinutes = 10,
    required this.workDays,
    this.active = true,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      id: json['id'],
      employeeId: json['employeeId'],
      startTime: _parseTime(json['startTime']),
      endTime: _parseTime(json['endTime']),
      lunchDurationMinutes: json['lunchDurationMinutes'] ?? 45,
      gracePeriodMinutes: json['gracePeriodMinutes'] ?? 10,
      workDays: List<String>.from(json['workDays'] ?? []),
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'startTime': _formatTime(startTime),
      'endTime': _formatTime(endTime),
      'lunchDurationMinutes': lunchDurationMinutes,
      'gracePeriodMinutes': gracePeriodMinutes,
      'workDays': workDays,
      'active': active,
    };
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00'; // backend expects LocalTime with seconds
  }
}
