import 'course_model.dart';

class StudyPlanModel {
  final String id;
  final String userId;
  final String studentName;
  final String studentCode;
  final String studentEmail;
  final String semesterName;
  final List<CourseModel> selectedCourses;
  final double maxSafeThresholdHours;
  final double targetGpa;
  final int tuitionFee;
  final bool isSaved;
  final String status; // 'draft' | 'pending' | 'approved' | 'rejected' | 'pending_acceptance' | 'acceptance_rejected' | 'completed'
  final String? reviewReason;
  final String? reviewedBy;
  final List<Map<String, dynamic>> submittedGrades;
  final bool isCompleted;
  final String? pdfDownloadUrl;
  final DateTime updatedAt;

  const StudyPlanModel({
    required this.id,
    required this.userId,
    this.studentName = '',
    this.studentCode = '',
    this.studentEmail = '',
    this.semesterName = 'Fall 2024',
    required this.selectedCourses,
    this.maxSafeThresholdHours = 25.0,
    this.targetGpa = 3.65,
    this.tuitionFee = 14250000,
    this.isSaved = false,
    this.status = 'draft',
    this.reviewReason,
    this.reviewedBy,
    this.submittedGrades = const [],
    this.isCompleted = false,
    this.pdfDownloadUrl,
    required this.updatedAt,
  });

  String get semester => semesterName;

  int get totalCredits => selectedCourses.fold(0, (sum, c) => sum + c.credits);

  double get totalSelfStudyHours =>
      selectedCourses.fold(0.0, (sum, c) => sum + c.plannedSelfStudyHours);

  bool get isOverloaded => totalSelfStudyHours > maxSafeThresholdHours;

  bool get isDraft => status == 'draft' && !isSaved;
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPendingAcceptance => status == 'pending_acceptance';
  bool get isAcceptanceRejected => status == 'acceptance_rejected';
  bool get isFullyCompleted => status == 'completed' || isCompleted;

  /// Kiểm tra xem có môn nào vi phạm tiên quyết dựa trên danh sách các môn đã học
  List<String> getPrerequisiteViolations(List<String> passedCodes) {
    final violations = <String>[];
    for (final course in selectedCourses) {
      if (course.prerequisiteCode != null &&
          !passedCodes.contains(course.prerequisiteCode)) {
        violations.add(
          '${course.code} (chưa học tiên quyết ${course.prerequisiteCode})',
        );
      }
    }
    return violations;
  }

  bool hasConflict(List<String> passedCodes) {
    return isOverloaded || getPrerequisiteViolations(passedCodes).isNotEmpty;
  }

  StudyPlanModel copyWith({
    String? id,
    String? userId,
    String? studentName,
    String? studentCode,
    String? studentEmail,
    String? semesterName,
    List<CourseModel>? selectedCourses,
    double? maxSafeThresholdHours,
    double? targetGpa,
    int? tuitionFee,
    bool? isSaved,
    String? status,
    String? reviewReason,
    String? reviewedBy,
    List<Map<String, dynamic>>? submittedGrades,
    bool? isCompleted,
    String? pdfDownloadUrl,
    DateTime? updatedAt,
  }) {
    return StudyPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
      studentEmail: studentEmail ?? this.studentEmail,
      semesterName: semesterName ?? this.semesterName,
      selectedCourses: selectedCourses ?? this.selectedCourses,
      maxSafeThresholdHours:
          maxSafeThresholdHours ?? this.maxSafeThresholdHours,
      targetGpa: targetGpa ?? this.targetGpa,
      tuitionFee: tuitionFee ?? this.tuitionFee,
      isSaved: isSaved ?? this.isSaved,
      status: status ?? this.status,
      reviewReason: reviewReason ?? this.reviewReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      submittedGrades: submittedGrades ?? this.submittedGrades,
      isCompleted: isCompleted ?? this.isCompleted,
      pdfDownloadUrl: pdfDownloadUrl ?? this.pdfDownloadUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      if (studentName.isNotEmpty) 'studentName': studentName,
      if (studentCode.isNotEmpty) 'studentCode': studentCode,
      if (studentEmail.isNotEmpty) 'studentEmail': studentEmail,
      'semesterName': semesterName,
      'courses': selectedCourses.map((c) => c.toMap()).toList(),
      'totalCredits': totalCredits,
      'totalSelfStudyHours': totalSelfStudyHours,
      'maxSafeThresholdHours': maxSafeThresholdHours,
      'targetGpa': targetGpa,
      'tuitionFee': tuitionFee,
      'isSaved': isSaved,
      'status': status,
      'isCompleted': isCompleted,
      if (reviewReason != null) 'reviewReason': reviewReason,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (submittedGrades.isNotEmpty) 'submittedGrades': submittedGrades,
      'pdfDownloadUrl': pdfDownloadUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    try {
      // Hỗ trợ Firestore Timestamp (.toDate())
      return (raw as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  factory StudyPlanModel.fromMap(Map<String, dynamic> map, String docId) {
    final coursesList = (map['courses'] as List<dynamic>?)
            ?.map(
              (e) => CourseModel.fromMap(
                Map<String, dynamic>.from(e as Map),
                (e['id'] ?? e['code'] ?? '') as String,
              ),
            )
            .toList() ??
        [];

    final gradesList = (map['submittedGrades'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];

    final rawStatus = map['status'] as String?;
    final isSavedVal = map['isSaved'] == true ||
        (rawStatus != null && rawStatus != 'draft');
    final resolvedStatus =
        rawStatus ?? (isSavedVal ? 'pending' : 'draft');

    return StudyPlanModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      studentName: map['studentName'] as String? ??
          (map['fullName'] as String? ?? ''),
      studentCode: map['studentCode'] as String? ??
          (map['studentId'] as String? ?? ''),
      studentEmail: map['studentEmail'] as String? ?? (map['email'] as String? ?? ''),
      semesterName: map['semesterName'] as String? ?? 'Fall 2024',
      selectedCourses: coursesList,
      maxSafeThresholdHours:
          (map['maxSafeThresholdHours'] as num?)?.toDouble() ?? 25.0,
      targetGpa: (map['targetGpa'] as num?)?.toDouble() ?? 3.65,
      tuitionFee: (map['tuitionFee'] as num?)?.toInt() ?? 14250000,
      isSaved: isSavedVal,
      status: resolvedStatus,
      reviewReason: map['reviewReason'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      submittedGrades: gradesList,
      isCompleted:
          map['isCompleted'] == true || resolvedStatus == 'completed',
      pdfDownloadUrl: map['pdfDownloadUrl'] as String?,
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }
}
