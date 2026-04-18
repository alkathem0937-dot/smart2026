/// Hearing Model
class HearingModel {
  final int? id;
  final int lawsuitId;
  final String? lawsuitNumber;
  final DateTime hearingDate;
  final String? hijriDate;
  final String? hearingTime;
  final String notes;
  final String? judgeName;
  final String hearingType;
  final bool isSynced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Archive fields
  final String archiveStatus;
  final DateTime? archiveDate;
  final String? archiveReason;
  final Map<String, dynamic>? archivedBy;
  final bool isDeleted;
  final DateTime? deletedAt;

  HearingModel({
    this.id,
    required this.lawsuitId,
    this.lawsuitNumber,
    required this.hearingDate,
    this.hijriDate,
    this.hearingTime,
    required this.notes,
    this.judgeName,
    this.hearingType = 'main',
    this.isSynced = true,
    this.createdAt,
    this.updatedAt,
    this.archiveStatus = 'active',
    this.archiveDate,
    this.archiveReason,
    this.archivedBy,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory HearingModel.fromJson(Map<String, dynamic> json) {
    return HearingModel(
      id: json['id'],
      lawsuitId: json['lawsuit'] is int 
          ? json['lawsuit'] as int
          : (json['lawsuit'] is Map ? (json['lawsuit'] as Map)['id'] : null) ?? json['lawsuit_id'] ?? 0,
      lawsuitNumber: json['lawsuit'] is Map 
          ? (json['lawsuit'] as Map)['case_number'] as String?
          : null,
      hearingDate: json['hearing_date'] != null 
          ? DateTime.parse(json['hearing_date']) 
          : DateTime.now(),
      hijriDate: json['hijri_date'],
      hearingTime: json['hearing_time'],
      notes: json['notes'] ?? '',
      judgeName: json['judge_name'],
      hearingType: json['hearing_type'] ?? 'main',
      isSynced: json['is_synced'] is int 
          ? (json['is_synced'] == 1) 
          : (json['is_synced'] ?? true),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      archiveStatus: json['archive_status'] ?? 'active',
      archiveDate: json['archive_date'] != null 
          ? DateTime.parse(json['archive_date']) 
          : null,
      archiveReason: json['archive_reason'],
      archivedBy: json['archived_by'] as Map<String, dynamic>?,
      isDeleted: json['is_deleted'] is int 
          ? (json['is_deleted'] == 1) 
          : (json['is_deleted'] ?? false),
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'lawsuit_id': lawsuitId,
      'hearing_date': hearingDate.toIso8601String().split('T')[0],
      if (hijriDate != null) 'hijri_date': hijriDate,
      if (hearingTime != null) 'hearing_time': hearingTime,
      'notes': notes,
      if (judgeName != null) 'judge_name': judgeName,
      'hearing_type': hearingType,
      'is_synced': isSynced ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
      'archive_status': archiveStatus,
      if (archiveDate != null) 'archive_date': archiveDate?.toIso8601String(),
      if (archiveReason != null) 'archive_reason': archiveReason,
      'is_deleted': isDeleted ? 1 : 0,
      if (deletedAt != null) 'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  String get typeDisplay {
    switch (hearingType) {
      case 'preliminary':
        return 'تمهيدية';
      case 'main':
        return 'رئيسية';
      case 'decision':
        return 'قرار';
      case 'adjourned':
        return 'مؤجلة';
      case 'other':
        return 'أخرى';
      default:
        return 'غير محدد';
    }
  }

  String get archiveStatusDisplay {
    switch (archiveStatus) {
      case 'active':
        return 'نشط';
      case 'semi_active':
        return 'شبه نشط';
      case 'archived':
        return 'محفوظ';
      default:
        return 'غير محدد';
    }
  }
}
