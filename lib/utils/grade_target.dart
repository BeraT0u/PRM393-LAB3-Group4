import '../models/course_model.dart';

/// UC-18: Mục tiêu điểm (A / B / Qua môn) và khối lượng tự học tương ứng.
///
/// Giờ tự học lấy theo tỉ lệ so với mức A của môn
/// (`defaultSelfStudyHours`), làm tròn 0.5h. Với PRM393 (8h): A = 8h, B = 5h, Qua môn = 3.5h.
class GradeTargetOption {
  /// Giá trị lưu trong `CourseModel.selectedGradeTarget`: 'A', 'B', 'PASS'
  final String code;
  final String title;
  final String threshold;
  final String note;
  final double factor;

  const GradeTargetOption({
    required this.code,
    required this.title,
    required this.threshold,
    required this.note,
    required this.factor,
  });

  double hoursFor(CourseModel course) {
    final raw = course.defaultSelfStudyHours * factor;
    return (raw * 2).round() / 2;
  }

  static const GradeTargetOption gradeA = GradeTargetOption(
    code: 'A',
    title: 'Điểm A',
    threshold: '8.5+',
    note: 'Hoàn thành sớm Đồ án',
    factor: 1.0,
  );
  static const GradeTargetOption gradeB = GradeTargetOption(
    code: 'B',
    title: 'Điểm B',
    threshold: '7.0+',
    note: 'Cân bằng giữa học và làm',
    factor: 0.625,
  );
  static const GradeTargetOption pass = GradeTargetOption(
    code: 'PASS',
    title: 'Qua môn',
    threshold: '5.5+',
    note: 'Đủ điều kiện qua môn',
    factor: 0.4375,
  );

  static const List<GradeTargetOption> all = [gradeA, gradeB, pass];

  /// Tìm theo mã; mã lạ hoặc rỗng quay về mức A.
  static GradeTargetOption fromCode(String? code) {
    return all.firstWhere((o) => o.code == code, orElse: () => gradeA);
  }

  /// Định dạng giờ: 8 -> "8h", 3.5 -> "3.5h"
  static String formatHours(double hours) {
    return hours == hours.roundToDouble() ? '${hours.toInt()}h' : '${hours}h';
  }
}
