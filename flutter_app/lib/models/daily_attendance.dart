class DailyAttendance {
  final int id;
  final int employeeId;
  final String attendanceDate;
  final String? firstPunch;
  final String? lastPunch;
  final int totalWorkingMinutes;
  final int breakDurationMinutes;
  final int lunchDurationMinutes;
  final int totalMinutes;
  final int workingMinutes;
  final int breakMinutes;
  final String status;
  final int overtimeMinutes;
  final int scheduledWorkMinutes;
  final int? workScheduleId;
  final bool isLate;
  final int lateMinutes;
  final bool isEarlyDeparture;
  final int earlyDepartureMinutes;

  DailyAttendance({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    this.firstPunch,
    this.lastPunch,
    required this.totalWorkingMinutes,
    required this.breakDurationMinutes,
    required this.lunchDurationMinutes,
    required this.totalMinutes,
    required this.workingMinutes,
    required this.breakMinutes,
    required this.status,
    required this.overtimeMinutes,
    required this.scheduledWorkMinutes,
    this.workScheduleId,
    required this.isLate,
    required this.lateMinutes,
    required this.isEarlyDeparture,
    required this.earlyDepartureMinutes,
  });

  factory DailyAttendance.fromJson(Map<String, dynamic> json) {
    return DailyAttendance(
      id: json['id'],
      employeeId: json['employeeId'],
      attendanceDate: json['attendanceDate'],
      firstPunch: json['firstPunch'],
      lastPunch: json['lastPunch'],
      totalWorkingMinutes: json['totalWorkingMinutes'] ?? 0,
      breakDurationMinutes: json['breakDurationMinutes'] ?? 0,
      lunchDurationMinutes: json['lunchDurationMinutes'] ?? 0,
      totalMinutes: json['totalMinutes'] ?? 0,
      workingMinutes: json['workingMinutes'] ?? 0,
      breakMinutes: json['breakMinutes'] ?? 0,
      status: json['status']?.toString() ?? 'ABSENT',
      overtimeMinutes: json['overtimeMinutes'] ?? 0,
      scheduledWorkMinutes: json['scheduledWorkMinutes'] ?? 0,
      workScheduleId: json['workScheduleId'],
      isLate: json['isLate'] ?? false,
      lateMinutes: json['lateMinutes'] ?? 0,
      isEarlyDeparture: json['isEarlyDeparture'] ?? false,
      earlyDepartureMinutes: json['earlyDepartureMinutes'] ?? 0,
    );
  }
}
