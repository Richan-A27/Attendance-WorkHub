class AttendanceSession {
  final int id;
  final int employeeId;
  final String sessionDate;
  final int sessionNumber;
  final String punchIn;
  final String? punchOut;
  final int? durationMinutes;
  final bool isLunchBreak;

  AttendanceSession({
    required this.id,
    required this.employeeId,
    required this.sessionDate,
    required this.sessionNumber,
    required this.punchIn,
    this.punchOut,
    this.durationMinutes,
    required this.isLunchBreak,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'],
      employeeId: json['employeeId'],
      sessionDate: json['sessionDate'],
      sessionNumber: json['sessionNumber'],
      punchIn: json['punchIn'],
      punchOut: json['punchOut'],
      durationMinutes: json['durationMinutes'],
      isLunchBreak: json['isLunchBreak'] ?? false,
    );
  }
}
