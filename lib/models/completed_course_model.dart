/// Môn đã hoàn thành của sinh viên (document trong `students/{uid}/completed_courses`).
class CompletedCourseModel {
  final String code;
  final String name;
  final int credits;
  final double? grade;
  final String? gradeLetter;

  /// Kỳ học 1..9. `null` = chưa phân kỳ (môn có sẵn trong hồ sơ persona
  /// hoặc được nghiệm thu từ kế hoạch học kỳ, chỉ có `semesterName`).
  final int? semesterIndex;
  final String? semesterName;

  const CompletedCourseModel({
    required this.code,
    required this.name,
    required this.credits,
    this.grade,
    this.gradeLetter,
    this.semesterIndex,
    this.semesterName,
  });

  factory CompletedCourseModel.fromMap(Map<String, dynamic> map, String docId) {
    return CompletedCourseModel(
      code: (map['code'] as String?) ?? docId,
      name: (map['name'] as String?) ?? '',
      credits: (map['credits'] as num?)?.toInt() ?? 0,
      grade: (map['grade'] as num?)?.toDouble(),
      gradeLetter: map['gradeLetter'] as String?,
      semesterIndex: (map['semesterIndex'] as num?)?.toInt(),
      semesterName: map['semesterName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'credits': credits,
      'grade': grade,
      'gradeLetter': gradeLetter,
      'semesterIndex': semesterIndex,
      'semesterName': semesterName,
    };
  }
}
