class AttendanceBreak {
  final int id;
  final int employeeId;
  final String attendanceDate;
  final int breakNumber;
  final String breakStart;
  final String breakEnd;
  final int durationMinutes;

  AttendanceBreak({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    required this.breakNumber,
    required this.breakStart,
    required this.breakEnd,
    required this.durationMinutes,
  });

  factory AttendanceBreak.fromJson(Map<String, dynamic> json) {
    return AttendanceBreak(
      id: json['id'],
      employeeId: json['employeeId'],
      attendanceDate: json['attendanceDate'],
      breakNumber: json['breakNumber'],
      breakStart: json['breakStart'],
      breakEnd: json['breakEnd'],
      durationMinutes: json['durationMinutes'],
    );
  }
}
