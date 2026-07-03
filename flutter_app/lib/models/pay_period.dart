class PayPeriod {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;

  const PayPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  factory PayPeriod.fromJson(Map<String, dynamic> json) {
    return PayPeriod(
      id: json['id'],
      name: json['name'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? 'OPEN',
      createdAt: json['createdAt'] ?? '',
    );
  }

  /// Returns a human-readable label combining name and date range.
  String get label => '$name ($startDate → $endDate)';

  /// True when the period is still editable (OPEN or PROCESSING).
  bool get isEditable => status == 'OPEN' || status == 'PROCESSING';

  /// True when the period has been paid out.
  bool get isPaid => status == 'PAID';
}
