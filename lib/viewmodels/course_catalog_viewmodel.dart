import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../services/service_providers.dart';
import '../utils/course_filter.dart';

/// Trạng thái dữ liệu của SCR-04 (Course Catalog).
class CourseCatalogState {
  final List<CourseModel> allCourses;
  final String query;
  final String category;

  const CourseCatalogState({
    required this.allCourses,
    this.query = '',
    this.category = CourseFilter.categoryAll,
  });

  CourseCatalogState copyWith({String? query, String? category}) {
    return CourseCatalogState(
      allCourses: allCourses,
      query: query ?? this.query,
      category: category ?? this.category,
    );
  }

  List<CourseModel> get filteredCourses =>
      CourseFilter.apply(allCourses, query: query, category: category);

  bool get hasActiveFilter =>
      query.trim().isNotEmpty || category != CourseFilter.categoryAll;
}

/// UC-14 / UC-15: ViewModel của SCR-04 (tìm kiếm & lọc danh mục môn mở).
class CourseCatalogViewModel extends AsyncNotifier<CourseCatalogState> {
  @override
  Future<CourseCatalogState> build() => _load();

  Future<CourseCatalogState> _load() async {
    final courses = await ref.read(courseServiceProvider).getCourses();
    return CourseCatalogState(allCourses: courses);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void setQuery(String query) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: query));
  }

  void setCategory(String category) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(category: category));
  }

  /// Nút "Xóa bộ lọc" ở trạng thái rỗng
  void clearFilters() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: '', category: CourseFilter.categoryAll));
  }
}

final courseCatalogViewModelProvider =
    AsyncNotifierProvider<CourseCatalogViewModel, CourseCatalogState>(
  CourseCatalogViewModel.new,
);
