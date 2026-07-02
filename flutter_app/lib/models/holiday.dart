class Holiday {
  final int? id;
  final String date; // YYYY-MM-DD
  final String description;
  final String type;

  Holiday({
    this.id,
    required this.date,
    required this.description,
    this.type = 'PUBLIC',
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'],
      date: json['date'],
      description: json['description'],
      type: json['type'] ?? 'PUBLIC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'description': description,
      'type': type,
    };
  }
}
