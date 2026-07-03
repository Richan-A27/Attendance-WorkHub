class PayrollRecord {
  final int id;
  final int employeeId;
  final int? payPeriodId;
  final int month;
  final int year;
  final double regularHours;
  final double overtimeHours;
  final double paidHours;
  final double breakHours;
  final double hourlyRate;
  final double overtimeMultiplier;
  final double grossPay;
  final double deductions;
  final double bonuses;
  final double netPay;
  final String status;
  final String? processedDate;

  PayrollRecord({
    required this.id,
    required this.employeeId,
    this.payPeriodId,
    required this.month,
    required this.year,
    required this.regularHours,
    required this.overtimeHours,
    required this.paidHours,
    required this.breakHours,
    required this.hourlyRate,
    required this.overtimeMultiplier,
    required this.grossPay,
    required this.deductions,
    required this.bonuses,
    required this.netPay,
    required this.status,
    this.processedDate,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      id: json['id'],
      employeeId: json['employeeId'],
      payPeriodId: json['payPeriodId'],
      month: json['month'],
      year: json['year'],
      regularHours: (json['regularHours'] as num).toDouble(),
      overtimeHours: (json['overtimeHours'] as num).toDouble(),
      paidHours: (json['paidHours'] as num? ?? json['regularHours'] as num).toDouble(),
      breakHours: (json['breakHours'] as num? ?? 0).toDouble(),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      overtimeMultiplier: (json['overtimeMultiplier'] as num).toDouble(),
      grossPay: (json['grossPay'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      bonuses: (json['bonuses'] as num).toDouble(),
      netPay: (json['netPay'] as num).toDouble(),
      status: json['status'] ?? 'PENDING',
      processedDate: json['processedDate'],
    );
  }
}

