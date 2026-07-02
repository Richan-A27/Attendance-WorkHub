class Employee {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? role;
  final double? hourlyRate;
  final bool active;
  final String? lastSynced;
  final String? createdAt;

  Employee({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role,
    this.hourlyRate,
    required this.active,
    this.lastSynced,
    this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      hourlyRate: json['hourlyRate'] != null
          ? (json['hourlyRate'] as num).toDouble()
          : null,
      active: json['active'] ?? true,
      lastSynced: json['lastSynced'],
      createdAt: json['createdAt'],
    );
  }
}
