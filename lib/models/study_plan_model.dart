import 'course_model.dart';

class StudyPlanModel {
  final String id;
  final String userId;
  final String semesterName;
  final List<CourseModel> selectedCourses;
  final double maxSafeThresholdHours;
  final double targetGpa;
  final int tuitionFee;
  final bool isSaved;
  final String? pdfDownloadUrl;
  final DateTime updatedAt;

  const StudyPlanModel({
    required this.id,
    required this.userId,
    this.semesterName = 'Fall 2024',
    required this.selectedCourses,
    this.maxSafeThresholdHours = 25.0,
    this.targetGpa = 3.65,
    this.tuitionFee = 14250000,
    this.isSaved = false,
    this.pdfDownloadUrl,
    required this.updatedAt,
  });

  int get totalCredits => selectedCourses.fold(0, (sum, c) => sum + c.credits);

  double get totalSelfStudyHours =>
      selectedCourses.fold(0.0, (sum, c) => sum + c.plannedSelfStudyHours);

  bool get isOverloaded => totalSelfStudyHours > maxSafeThresholdHours;

  /// Kiểm tra xem có môn nào vi phạm tiên quyết dựa trên danh sách các môn đã học
  List<String> getPrerequisiteViolations(List<String> passedCodes) {
    final violations = <String>[];
    for (final course in selectedCourses) {
      if (course.prerequisiteCode != null &&
          !passedCodes.contains(course.prerequisiteCode)) {
        violations.add('${course.code} (chưa học tiên quyết ${course.prerequisiteCode})');
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
    String? semesterName,
    List<CourseModel>? selectedCourses,
    double? maxSafeThresholdHours,
    double? targetGpa,
    int? tuitionFee,
    bool? isSaved,
    String? pdfDownloadUrl,
    DateTime? updatedAt,
  }) {
    return StudyPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterName: semesterName ?? this.semesterName,
      selectedCourses: selectedCourses ?? this.selectedCourses,
      maxSafeThresholdHours: maxSafeThresholdHours ?? this.maxSafeThresholdHours,
      targetGpa: targetGpa ?? this.targetGpa,
      tuitionFee: tuitionFee ?? this.tuitionFee,
      isSaved: isSaved ?? this.isSaved,
      pdfDownloadUrl: pdfDownloadUrl ?? this.pdfDownloadUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterName': semesterName,
      'courses': selectedCourses.map((c) => c.toMap()).toList(),
      'maxSafeThresholdHours': maxSafeThresholdHours,
      'targetGpa': targetGpa,
      'tuitionFee': tuitionFee,
      'isSaved': isSaved,
      'pdfDownloadUrl': pdfDownloadUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudyPlanModel.fromMap(Map<String, dynamic> map, String docId) {
    final coursesList = (map['courses'] as List<dynamic>?)
            ?.map((e) => CourseModel.fromMap(Map<String, dynamic>.from(e), e['id'] ?? ''))
            .toList() ??
        [];

    return StudyPlanModel(
      id: docId,
      userId: map['userId'] ?? '',
      semesterName: map['semesterName'] ?? 'Fall 2024',
      selectedCourses: coursesList,
      maxSafeThresholdHours: (map['maxSafeThresholdHours'] as num?)?.toDouble() ?? 25.0,
      targetGpa: (map['targetGpa'] as num?)?.toDouble() ?? 3.65,
      tuitionFee: (map['tuitionFee'] as num?)?.toInt() ?? 14250000,
      isSaved: map['isSaved'] ?? false,
      pdfDownloadUrl: map['pdfDownloadUrl'],
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
