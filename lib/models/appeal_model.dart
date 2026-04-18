/// Appeal Model
class AppealModel {
  final int? id;
  final int lawsuitId;
  final String? lawsuitNumber;
  final String appealType;
  final String appealNumber;
  final String appealReasons;
  final String appealRequests;
  final String higherCourt;
  final String status;
  final DateTime appealDate;
  final String? hijriDate;
  final String submittedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppealModel({
    this.id,
    required this.lawsuitId,
    this.lawsuitNumber,
    required this.appealType,
    required this.appealNumber,
    required this.appealReasons,
    required this.appealRequests,
    required this.higherCourt,
    required this.status,
    required this.appealDate,
    this.hijriDate,
    required this.submittedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AppealModel.fromJson(Map<String, dynamic> json) {
    return AppealModel(
      id: json['id'],
      lawsuitId: json['lawsuit'] is int 
          ? json['lawsuit'] as int
          : (json['lawsuit'] is Map ? (json['lawsuit'] as Map)['id'] : null) ?? json['lawsuit_id'] ?? 0,
      lawsuitNumber: json['lawsuit'] is Map 
          ? (json['lawsuit'] as Map)['case_number'] as String?
          : null,
      appealType: json['appeal_type'] ?? '',
      appealNumber: json['appeal_number'] ?? '',
      appealReasons: json['appeal_reasons'] ?? '',
      appealRequests: json['appeal_requests'] ?? '',
      higherCourt: json['higher_court'] ?? '',
      status: json['status'] ?? 'pending',
      appealDate: json['appeal_date'] != null 
          ? DateTime.parse(json['appeal_date']) 
          : DateTime.now(),
      hijriDate: json['hijri_date'],
      submittedBy: json['submitted_by'] ?? '',
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
      'lawsuit': lawsuitId,
      'appeal_type': appealType,
      'appeal_number': appealNumber,
      'appeal_reasons': appealReasons,
      'appeal_requests': appealRequests,
      'higher_court': higherCourt,
      'status': status,
      'appeal_date': appealDate.toIso8601String().split('T')[0],
      if (hijriDate != null) 'hijri_date': hijriDate,
      'submitted_by': submittedBy,
    };
  }

  String get appealTypeDisplay {
    switch (appealType) {
      case 'primary':
        return 'ابتدائي';
      case 'appeal':
        return 'استئناف';
      case 'cassation':
        return 'تمييز';
      case 'constitutional':
        return 'دستوري';
      case 'other':
        return 'أخرى';
      default:
        return appealType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'under_review':
        return 'قيد المراجعة';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'withdrawn':
        return 'مسحوب';
      case 'closed':
        return 'مغلق';
      default:
        return status;
    }
  }
}

