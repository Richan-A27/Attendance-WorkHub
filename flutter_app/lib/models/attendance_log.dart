class AttendanceLog {
  final int id;
  final int employeeId;
  final String punchTime;
  final String? verifyMode;
  final String? status;
  final String? createdAt;

  AttendanceLog({
    required this.id,
    required this.employeeId,
    required this.punchTime,
    this.verifyMode,
    this.status,
    this.createdAt,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'],
      employeeId: json['employeeId'],
      punchTime: json['punchTime'],
      verifyMode: json['verifyMode']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['createdAt'],
    );
  }
}
