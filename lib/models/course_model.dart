class CourseModel {
  final String id;
  final String code;
  final String name;
  final int credits;
  final double difficulty; // Thang điểm 5 (VD: 4.0 ⭐)
  final int defaultSelfStudyHours; // Giờ tự học mặc định mỗi tuần
  final String? prerequisiteCode; // Mã môn tiên quyết (VD: PRO192, NWC203)
  final String category; // Chuyên ngành SE, Cơ sở ngành, v.v.
  final Map<String, int> assessmentBreakdown; // VD: {"Đồ án": 40, "Lab": 30, "FE": 30}
  final List<String> studyTips; // Mẹo học tập
  final String selectedGradeTarget; // 'A', 'B', 'PASS'
  final double plannedSelfStudyHours; // Giờ tự học ứng với mục tiêu điểm

  const CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.difficulty,
    required this.defaultSelfStudyHours,
    this.prerequisiteCode,
    required this.category,
    required this.assessmentBreakdown,
    required this.studyTips,
    this.selectedGradeTarget = 'A',
    required this.plannedSelfStudyHours,
  });

  CourseModel copyWith({
    String? id,
    String? code,
    String? name,
    int? credits,
    double? difficulty,
    int? defaultSelfStudyHours,
    String? prerequisiteCode,
    String? category,
    Map<String, int>? assessmentBreakdown,
    List<String>? studyTips,
    String? selectedGradeTarget,
    double? plannedSelfStudyHours,
  }) {
    return CourseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      difficulty: difficulty ?? this.difficulty,
      defaultSelfStudyHours: defaultSelfStudyHours ?? this.defaultSelfStudyHours,
      prerequisiteCode: prerequisiteCode ?? this.prerequisiteCode,
      category: category ?? this.category,
      assessmentBreakdown: assessmentBreakdown ?? this.assessmentBreakdown,
      studyTips: studyTips ?? this.studyTips,
      selectedGradeTarget: selectedGradeTarget ?? this.selectedGradeTarget,
      plannedSelfStudyHours: plannedSelfStudyHours ?? this.plannedSelfStudyHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'credits': credits,
      'difficulty': difficulty,
      'defaultSelfStudyHours': defaultSelfStudyHours,
      'prerequisiteCode': prerequisiteCode,
      'category': category,
      'assessmentBreakdown': assessmentBreakdown,
      'studyTips': studyTips,
      'selectedGradeTarget': selectedGradeTarget,
      'plannedSelfStudyHours': plannedSelfStudyHours,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map, String docId) {
    return CourseModel(
      id: docId,
      code: map['code'] ?? docId,
      name: map['name'] ?? '',
      credits: (map['credits'] as num?)?.toInt() ?? 3,
      difficulty: (map['difficulty'] as num?)?.toDouble() ?? 3.0,
      defaultSelfStudyHours: (map['defaultSelfStudyHours'] as num?)?.toInt() ?? 5,
      prerequisiteCode: map['prerequisiteCode'],
      category: map['category'] ?? 'Chuyên ngành SE',
      assessmentBreakdown: Map<String, int>.from(map['assessmentBreakdown'] ?? {}),
      studyTips: List<String>.from(map['studyTips'] ?? []),
      selectedGradeTarget: map['selectedGradeTarget'] ?? 'A',
      plannedSelfStudyHours: (map['plannedSelfStudyHours'] as num?)?.toDouble() ?? 8.0,
    );
  }
}
