import '../utils/gpa_calculator.dart';
import 'course_model.dart';

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
  final bool isPassed;

  const CompletedCourseModel({
    required this.code,
    required this.name,
    required this.credits,
    this.grade,
    this.gradeLetter,
    this.semesterIndex,
    this.semesterName,
    this.isPassed = true,
  });

  /// Kiểm tra xem môn học này đã đạt (pass) hay chưa
  bool get isActuallyPassed => isPassed && (grade == null || grade! >= 4.0);

  /// Điểm chữ chuẩn (A, B+, B, C+, C, D+, D, F)
  String get effectiveGradeLetter {
    if (gradeLetter != null && gradeLetter!.isNotEmpty) return gradeLetter!;
    if (grade != null) return GpaCalculator.grade10ToLetter(grade!);
    return 'Đạt';
  }

  /// GPA hệ 4.0 quy đổi từ điểm
  double get gpa4 {
    if (grade != null) return GpaCalculator.grade10ToGpa4(grade!);
    if (gradeLetter != null) return GpaCalculator.letterToGpa4(gradeLetter);
    return 0.0;
  }

  factory CompletedCourseModel.fromMap(Map<String, dynamic> map, String docId) {
    final grade = (map['grade'] as num?)?.toDouble();
    final isPassedVal = map['isPassed'] as bool?;
    final gradeLetter = (map['gradeLetter'] as String?) ??
        (grade != null ? GpaCalculator.grade10ToLetter(grade) : null);
    return CompletedCourseModel(
      code: (map['code'] as String?) ?? docId,
      name: (map['name'] as String?) ?? '',
      credits: (map['credits'] as num?)?.toInt() ?? 0,
      grade: grade,
      gradeLetter: gradeLetter,
      semesterIndex: (map['semesterIndex'] as num?)?.toInt(),
      semesterName: map['semesterName'] as String?,
      isPassed: isPassedVal ?? (grade == null || grade >= 4.0),
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
      'isPassed': isPassed,
    };
  }
}

/// Dữ liệu nghiệm thu kết quả môn học cuối kỳ (SCR-07).
class CourseGradeItem {
  final CourseModel course;
  final bool isPassed;
  final double grade;

  const CourseGradeItem({
    required this.course,
    required this.isPassed,
    required this.grade,
  });

  CourseGradeItem copyWith({
    CourseModel? course,
    bool? isPassed,
    double? grade,
  }) {
    return CourseGradeItem(
      course: course ?? this.course,
      isPassed: isPassed ?? this.isPassed,
      grade: grade ?? this.grade,
    );
  }
}
