import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/completed_course_model.dart';
import '../models/course_model.dart';
import '../models/student_profile_model.dart';
import '../services/database_seeder.dart';
import '../services/service_providers.dart';
import '../utils/app_logger.dart';
import '../utils/completed_course_rules.dart';

/// UID sinh viên đang đăng nhập.
/// TODO(UC-09): thay bằng uid thật từ Google Sign-In / Persona khi hoàn tất đăng nhập.
final currentStudentUidProvider = Provider<String>((ref) {
  return DatabaseSeeder.defaultStudent.uid;
});

/// Trạng thái dữ liệu của SCR-03 (Môn Đã Học).
class CompletedCoursesState {
  static const String filterAll = 'Tất cả';
  static const String filterUnassigned = 'Chưa phân kỳ';

  final StudentProfileModel profile;
  final List<CompletedCourseModel> completed;
  final Set<String> legacyPassedCodes;
  final List<CourseModel> catalog;
  final String selectedFilter;

  const CompletedCoursesState({
    required this.profile,
    required this.completed,
    required this.legacyPassedCodes,
    required this.catalog,
    this.selectedFilter = filterAll,
  });

  CompletedCoursesState copyWith({String? selectedFilter}) {
    return CompletedCoursesState(
      profile: profile,
      completed: completed,
      legacyPassedCodes: legacyPassedCodes,
      catalog: catalog,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  /// Tiến độ tích lũy 0..1 (VD: 90/145 = 62%)
  double get progress {
    final total = profile.totalGraduationCredits;
    if (total <= 0) return 0;
    return (profile.accumulatedCredits / total).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  /// Các môn có sẵn trong hồ sơ nhưng chưa nằm trong `completed_courses`,
  /// hiển thị ở nhóm "Chưa phân kỳ".
  List<CompletedCourseModel> get legacyCourses {
    return legacyPassedCodes.map((code) {
      final info = catalog.where((c) => c.code == code).firstOrNull;
      return CompletedCourseModel(
        code: code,
        name: info?.name ?? '',
        credits: info?.credits ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  List<CompletedCourseModel> get _allCourses => [...completed, ...legacyCourses];

  /// Các kỳ đã có dữ liệu, tăng dần
  List<int> get semestersWithData {
    final set = completed.map((c) => c.semesterIndex).whereType<int>().toSet();
    return set.toList()..sort();
  }

  bool get hasUnassigned => _allCourses.any((c) => c.semesterIndex == null);

  /// Nhãn các filter chip: Tất cả, Kỳ 1.., Chưa phân kỳ
  List<String> get filterLabels => [
        filterAll,
        for (final s in semestersWithData) 'Kỳ $s',
        if (hasUnassigned) filterUnassigned,
      ];

  List<CompletedCourseModel> get visibleCourses {
    final all = _allCourses;
    List<CompletedCourseModel> result;
    if (selectedFilter == filterAll) {
      result = all;
    } else if (selectedFilter == filterUnassigned) {
      result = all.where((c) => c.semesterIndex == null).toList();
    } else {
      final idx = int.tryParse(selectedFilter.replaceFirst('Kỳ ', ''));
      result = all.where((c) => c.semesterIndex == idx).toList();
    }
    result.sort((a, b) {
      final sa = a.semesterIndex ?? 999;
      final sb = b.semesterIndex ?? 999;
      return sa != sb ? sa.compareTo(sb) : a.code.compareTo(b.code);
    });
    return result;
  }

  Set<String> get passedCodes =>
      {...profile.passedCourseCodes, ...completed.map((c) => c.code)};

  /// Môn trong catalog có thể thêm (chưa học)
  List<CourseModel> get addableCourses =>
      catalog.where((c) => !passedCodes.contains(c.code)).toList();

  /// Dòng chú thích mở khóa, VD: "Đã hoàn thành PRO192 → mở khóa PRM393"
  String? get unlockHint {
    final passed = passedCodes;
    for (final c in catalog) {
      final req = c.prerequisiteCode?.trim();
      if (req != null && req.isNotEmpty && passed.contains(req) && !passed.contains(c.code)) {
        return 'Đã hoàn thành $req → mở khóa ${c.code}';
      }
    }
    return null;
  }
}

/// UC-13 / UC-13B: ViewModel của SCR-03 (Môn Đã Học).
class CompletedCoursesViewModel extends AsyncNotifier<CompletedCoursesState> {
  @override
  Future<CompletedCoursesState> build() => _load();

  Future<CompletedCoursesState> _load({String? filter}) async {
    final uid = ref.read(currentStudentUidProvider);
    final studentService = ref.read(studentServiceProvider);
    final courseService = ref.read(courseServiceProvider);

    final profile = await studentService.getStudentProfile(uid);
    final completed = await studentService.getCompletedCourses(uid);
    final catalog = await courseService.getCourses();

    final completedCodes = completed.map((c) => c.code).toSet();
    final legacy = profile.passedCourseCodes.where((c) => !completedCodes.contains(c)).toSet();

    var next = CompletedCoursesState(
      profile: profile,
      completed: completed,
      legacyPassedCodes: legacy,
      catalog: catalog,
    );
    // Giữ filter đang chọn nếu vẫn còn hợp lệ
    if (filter != null && next.filterLabels.contains(filter)) {
      next = next.copyWith(selectedFilter: filter);
    }
    return next;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void selectFilter(String filter) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedFilter: filter));
  }

  /// Kiểm tra trước khi thêm (dùng cho cảnh báo trực tiếp trong modal)
  String? validateAdd({required int semesterIndex, required CourseModel course}) {
    final current = state.value;
    if (current == null) return 'Dữ liệu chưa sẵn sàng.';
    return CompletedCourseRules.validateAdd(
      semesterIndex: semesterIndex,
      course: course,
      completed: current.completed,
      legacyPassedCodes: current.legacyPassedCodes,
    );
  }

  /// Thêm môn đã học vào [semesterIndex]. Trả về `null` nếu thành công,
  /// ngược lại là thông báo lỗi để hiển thị cho người dùng.
  Future<String?> addCompletedCourse({
    required int semesterIndex,
    required CourseModel course,
    required double? grade,
  }) async {
    final ruleError = validateAdd(semesterIndex: semesterIndex, course: course);
    if (ruleError != null) return ruleError;
    final gradeError = CompletedCourseRules.validateGrade(grade);
    if (gradeError != null) return gradeError;

    final uid = ref.read(currentStudentUidProvider);
    try {
      await ref.read(studentServiceProvider).addCompletedCourse(
            uid: uid,
            semesterIndex: semesterIndex,
            course: course,
            grade: grade!,
          );
      final filter = state.value?.selectedFilter;
      state = AsyncData(await _load(filter: filter));
      return null;
    } on ArgumentError catch (e) {
      return e.message?.toString() ?? 'Dữ liệu không hợp lệ.';
    } catch (e, st) {
      AppLogger.error('Lỗi khi thêm môn đã học ${course.code}', e, st);
      return 'Không thể lưu môn học. Vui lòng thử lại.';
    }
  }
}

final completedCoursesViewModelProvider =
    AsyncNotifierProvider<CompletedCoursesViewModel, CompletedCoursesState>(
  CompletedCoursesViewModel.new,
);
