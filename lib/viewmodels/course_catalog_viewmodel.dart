import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../services/database_seeder.dart';
import '../services/service_providers.dart';
import '../utils/course_filter.dart';
import 'completed_courses_viewmodel.dart';

/// Trạng thái dữ liệu của SCR-04 (Course Catalog).
class CourseCatalogState {
  final List<CourseModel> allCourses;
  final List<String> passedCourseCodes;
  final String query;
  final String category;
  final bool onlyEligible;
  final String? replacingCourseCode;

  const CourseCatalogState({
    required this.allCourses,
    this.passedCourseCodes = const ['PRO192', 'MAD101', 'CSD201', 'DBI202', 'MAS291'],
    this.query = '',
    this.category = CourseFilter.categoryAll,
    this.onlyEligible = false,
    this.replacingCourseCode,
  });

  CourseCatalogState copyWith({
    List<CourseModel>? allCourses,
    List<String>? passedCourseCodes,
    String? query,
    String? category,
    bool? onlyEligible,
    String? replacingCourseCode,
    bool clearReplacingCourseCode = false,
  }) {
    return CourseCatalogState(
      allCourses: allCourses ?? this.allCourses,
      passedCourseCodes: passedCourseCodes ?? this.passedCourseCodes,
      query: query ?? this.query,
      category: category ?? this.category,
      onlyEligible: onlyEligible ?? this.onlyEligible,
      replacingCourseCode: clearReplacingCourseCode
          ? null
          : (replacingCourseCode ?? this.replacingCourseCode),
    );
  }

  List<CourseModel> get filteredCourses => CourseFilter.apply(
        allCourses,
        query: query,
        category: category,
        onlyEligible: onlyEligible,
        passedCourseCodes: passedCourseCodes,
      );

  bool get hasActiveFilter =>
      query.trim().isNotEmpty ||
      category != CourseFilter.categoryAll ||
      onlyEligible;
}

/// UC-14 / UC-15: ViewModel của SCR-04 (tìm kiếm & lọc danh mục môn mở).
class CourseCatalogViewModel extends AsyncNotifier<CourseCatalogState> {
  bool _pendingOnlyEligible = false;
  String? _pendingReplacingCode;

  @override
  Future<CourseCatalogState> build() {
    final uid = ref.watch(currentStudentUidProvider);
    return _load(uid);
  }

  Future<CourseCatalogState> _load(String uid) async {
    final courses = await ref.read(courseServiceProvider).getCourses();
    List<String> passed = DatabaseSeeder.getStudentByUid(uid).passedCourseCodes;
    try {
      final studentService = ref.read(studentServiceProvider);
      final profile = await studentService.getStudentProfile(uid);
      final completed = await studentService.getCompletedCourses(uid);
      passed = {...profile.passedCourseCodes, ...completed.map((c) => c.code)}.toList();
    } catch (_) {
      // Offline fallback
    }

    return CourseCatalogState(
      allCourses: courses,
      passedCourseCodes: passed,
      onlyEligible: _pendingOnlyEligible,
      replacingCourseCode: _pendingReplacingCode,
    );
  }

  Future<void> reload() async {
    final uid = ref.read(currentStudentUidProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(uid));
  }

  void setQuery(String query) {
    final current = state.value;
    if (current == null) return;
    final nextState = current.copyWith(query: query);
    state = AsyncData(nextState);
  }

  void setCategory(String category) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(category: category));
  }

  /// Bật/tắt filter môn đã xong tiên quyết
  void toggleOnlyEligible() {
    final current = state.value;
    if (current == null) return;
    final next = !current.onlyEligible;
    _pendingOnlyEligible = next;
    if (!next) {
      _pendingReplacingCode = null;
    }
    state = AsyncData(current.copyWith(
      onlyEligible: next,
      clearReplacingCourseCode: !next,
    ));
  }

  /// Cấu hình trực tiếp trạng thái filter môn đã xong tiên quyết (dùng khi vào từ [⇄ Đổi môn khác])
  void setOnlyEligible(bool value, {String? replacingCourseCode}) {
    _pendingOnlyEligible = value;
    _pendingReplacingCode = replacingCourseCode;
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(
        onlyEligible: value,
        replacingCourseCode: replacingCourseCode,
        clearReplacingCourseCode: replacingCourseCode == null,
      ));
    }
  }

  /// Nút "Xóa bộ lọc" ở trạng thái rỗng
  void clearFilters() {
    _pendingOnlyEligible = false;
    _pendingReplacingCode = null;
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      query: '',
      category: CourseFilter.categoryAll,
      onlyEligible: false,
      clearReplacingCourseCode: true,
    ));
  }
}

final courseCatalogViewModelProvider =
    AsyncNotifierProvider<CourseCatalogViewModel, CourseCatalogState>(
  CourseCatalogViewModel.new,
);
