import '../models/completed_course_model.dart';

/// Tiện ích tính toán GPA theo chuẩn thang điểm 4 của Bộ GD-ĐT và Đại học FPT
/// dựa trên điểm hệ 10 và số tín chỉ của từng môn.
class GpaCalculator {
  /// Quy đổi điểm hệ 10 sang thang điểm 4
  static double grade10ToGpa4(double grade) {
    if (grade >= 8.5) return 4.0;
    if (grade >= 8.0) return 3.5;
    if (grade >= 7.0) return 3.0;
    if (grade >= 6.5) return 2.5;
    if (grade >= 5.5) return 2.0;
    if (grade >= 5.0) return 1.5;
    if (grade >= 4.0) return 1.0;
    return 0.0;
  }

  /// Quy đổi điểm hệ 10 sang điểm chữ
  static String grade10ToLetter(double grade) {
    if (grade >= 8.5) return 'A';
    if (grade >= 8.0) return 'B+';
    if (grade >= 7.0) return 'B';
    if (grade >= 6.5) return 'C+';
    if (grade >= 5.5) return 'C';
    if (grade >= 5.0) return 'D+';
    if (grade >= 4.0) return 'D';
    return 'F';
  }

  /// Quy đổi điểm chữ sang thang điểm 4 (dùng cho trường hợp môn chỉ có điểm chữ)
  static double letterToGpa4(String? letter) {
    switch (letter?.toUpperCase().trim()) {
      case 'A':
        return 4.0;
      case 'B+':
        return 3.5;
      case 'B':
        return 3.0;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'D+':
        return 1.5;
      case 'D':
        return 1.0;
      case 'F':
      default:
        return 0.0;
    }
  }

  /// Kiểm tra xem môn học có đạt (qua môn) hay không (điểm >= 4.0 hoặc điểm chữ != F)
  static bool isPassingGrade({double? grade, String? letter}) {
    if (grade != null) {
      return grade >= 4.0;
    }
    if (letter != null) {
      return letter.toUpperCase().trim() != 'F';
    }
    return true;
  }

  /// Tính GPA tích lũy bình quân gia quyền theo tín chỉ từ danh sách các môn đã học.
  /// Môn rớt (F / điểm < 4.0) vẫn được tính vào GPA (với GPA = 0.0).
  /// Trả về 0.0 nếu chưa có môn nào hoặc tổng tín chỉ = 0.
  static double calculateGpa(List<CompletedCourseModel> courses) {
    if (courses.isEmpty) return 0.0;

    double totalWeightedGpa = 0.0;
    int totalCredits = 0;

    for (final course in courses) {
      final double gpa;
      if (course.grade != null) {
        gpa = grade10ToGpa4(course.grade!);
      } else if (course.gradeLetter != null) {
        gpa = letterToGpa4(course.gradeLetter);
      } else {
        // Môn đã đạt sẵn nhưng chưa có điểm -> bỏ qua không tính vào GPA tích lũy
        continue;
      }

      final credits = course.credits > 0 ? course.credits : 3;
      totalWeightedGpa += gpa * credits;
      totalCredits += credits;
    }

    if (totalCredits == 0) return 0.0;
    final result = totalWeightedGpa / totalCredits;
    return double.parse(result.toStringAsFixed(2));
  }
}
