import '../models/course_model.dart';

/// Bộ lọc môn học dùng chung cho SCR-04 (Course Catalog): từ khóa + chip danh mục + điều kiện tiên quyết.
class CourseFilter {
  static const String categoryAll = 'Tất cả';
  static const String categorySE = 'Chuyên ngành SE';
  static const String categoryBasic = 'Cơ sở';

  static const List<String> categories = [categoryAll, categorySE, categoryBasic];

  static List<CourseModel> apply(
    List<CourseModel> courses, {
    String query = '',
    String category = categoryAll,
    bool onlyEligible = false,
    List<String> passedCourseCodes = const [],
  }) {
    final cleanQuery = query.trim().toLowerCase();

    return courses.where((c) {
      final matchesQuery = cleanQuery.isEmpty ||
          c.code.toLowerCase().contains(cleanQuery) ||
          c.name.toLowerCase().contains(cleanQuery);

      final matchesCategory = category == categoryAll ||
          (category == categorySE && c.category.contains('SE')) ||
          (category == categoryBasic &&
              (c.category.contains('Cơ sở') || c.category.contains('Toán')));

      // Lọc các môn đã xong tiên quyết (hoặc không yêu cầu tiên quyết)
      final matchesEligible = !onlyEligible ||
          c.prerequisiteCode == null ||
          passedCourseCodes.contains(c.prerequisiteCode);

      return matchesQuery && matchesCategory && matchesEligible;
    }).toList();
  }
}
