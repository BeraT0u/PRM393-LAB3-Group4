import '../models/completed_course_model.dart';
import '../models/course_model.dart';

/// UC-13B: Quy tắc nghiệp vụ khi khai báo môn đã học theo kỳ (SCR-03).
/// Hàm thuần Dart (không phụ thuộc Firebase) để dễ unit test.
class CompletedCourseRules {
  static const int minSemester = 1;
  static const int maxSemester = 9;
  static const double minPassGrade = 4.0;
  static const double maxGrade = 10.0;

  /// Kiểm tra thêm [course] vào Kỳ [semesterIndex].
  ///
  /// - [completed]: các môn đã khai báo (có thể kèm `semesterIndex == null`).
  /// - [legacyPassedCodes]: mã môn đã đạt trong hồ sơ nhưng chưa phân kỳ,
  ///   coi như đã hoàn thành ở các kỳ trước.
  ///
  /// Trả về `null` nếu hợp lệ, ngược lại là thông báo lỗi tiếng Việt.
  static String? validateAdd({
    required int semesterIndex,
    required CourseModel course,
    required List<CompletedCourseModel> completed,
    Set<String> legacyPassedCodes = const {},
  }) {
    if (semesterIndex < minSemester || semesterIndex > maxSemester) {
      return 'Kỳ học phải nằm trong khoảng $minSemester–$maxSemester.';
    }

    // 0. Không khai báo trùng môn đã học (tránh cộng tín chỉ 2 lần)
    final alreadyDone = legacyPassedCodes.contains(course.code) ||
        completed.any((c) => c.code == course.code);
    if (alreadyDone) {
      return 'Môn ${course.code} đã có trong danh sách môn đã học.';
    }

    // 1. Ràng buộc tiến trình kỳ: kỳ N cần có đủ kỳ 1..N-1
    for (var k = minSemester; k < semesterIndex; k++) {
      final hasSemester = completed.any((c) => c.semesterIndex == k);
      if (!hasSemester) {
        return 'Không thể thêm môn vào Kỳ $semesterIndex khi Kỳ $k chưa có môn '
            'nào hoàn thành. Vui lòng khai báo Kỳ $k trước!';
      }
    }

    // 2. Ràng buộc tiên quyết: phải hoàn thành ở kỳ trước (< N)
    final prereq = course.prerequisiteCode?.trim();
    if (prereq != null && prereq.isNotEmpty) {
      final satisfied = legacyPassedCodes.contains(prereq) ||
          completed.any((c) =>
              c.code == prereq &&
              (c.semesterIndex == null || c.semesterIndex! < semesterIndex));
      if (!satisfied) {
        return 'Không thể thêm môn ${course.code} vào Kỳ $semesterIndex vì '
            'chưa hoàn thành môn tiên quyết $prereq ở các kỳ trước.';
      }
    }

    return null;
  }

  /// Kiểm tra điểm nhập vào (thang 10, đạt từ 4.0).
  static String? validateGrade(double? grade) {
    if (grade == null) return 'Vui lòng nhập điểm hợp lệ (ví dụ 8.5).';
    if (grade < minPassGrade || grade > maxGrade) {
      return 'Điểm môn đã học phải từ $minPassGrade đến $maxGrade.';
    }
    return null;
  }
}
