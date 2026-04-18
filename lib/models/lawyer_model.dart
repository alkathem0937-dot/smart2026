class LawyerModel {
  final int? id;
  final int? userId;
  final String registrationNumber;
  final String name;
  final String grade;
  final String? branch;
  final String? phone;
  final String? governorate;
  final String? directorate;
  final String? neighborhood;
  final String? addressDetails;
  final String? officeType;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LawyerModel({
    this.id,
    this.userId,
    required this.registrationNumber,
    required this.name,
    required this.grade,
    this.branch,
    this.phone,
    this.governorate,
    this.directorate,
    this.neighborhood,
    this.addressDetails,
    this.officeType,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    return LawyerModel(
      id: json['id'],
      userId: json['user'],
      registrationNumber: json['registration_number'] ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      branch: json['branch'],
      phone: json['phone'],
      governorate: json['governorate'],
      directorate: json['directorate'],
      neighborhood: json['neighborhood'],
      addressDetails: json['address_details'],
      officeType: json['office_type'],
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user': userId,
      'registration_number': registrationNumber,
      'name': name,
      'grade': grade,
      if (branch != null) 'branch': branch,
      if (phone != null) 'phone': phone,
      if (governorate != null) 'governorate': governorate,
      if (directorate != null) 'directorate': directorate,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (addressDetails != null) 'address_details': addressDetails,
      if (officeType != null) 'office_type': officeType,
      if (notes != null) 'notes': notes,
    };
  }

  String get gradeDisplay {
    switch (grade) {
      case 'عليا':
        return 'عليا';
      case 'وسطى':
        return 'وسطى';
      case 'أولى':
        return 'أولى';
      default:
        return grade;
    }
  }

  String get fullAddress {
    final parts = <String>[];
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add(neighborhood!);
    if (directorate != null && directorate!.isNotEmpty) parts.add(directorate!);
    if (governorate != null && governorate!.isNotEmpty) parts.add(governorate!);
    if (addressDetails != null && addressDetails!.isNotEmpty) parts.add(addressDetails!);
    return parts.join(' - ');
  }
}
