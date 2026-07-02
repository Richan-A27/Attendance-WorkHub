class CompanyProfile {
  final int? id;
  final String companyName;
  final String? address;
  final String? contactEmail;
  final String? contactPhone;
  final String? taxId;

  CompanyProfile({
    this.id,
    required this.companyName,
    this.address,
    this.contactEmail,
    this.contactPhone,
    this.taxId,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: json['id'],
      companyName: json['companyName'] ?? '',
      address: json['address'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      taxId: json['taxId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'address': address,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'taxId': taxId,
    };
  }
}
