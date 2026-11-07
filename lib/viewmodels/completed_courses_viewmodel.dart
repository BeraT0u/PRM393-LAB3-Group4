import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/completed_course_model.dart';
import '../models/course_model.dart';
import '../models/student_profile_model.dart';
import '../services/database_seeder.dart';
import '../services/service_providers.dart';
import '../services/student_service.dart';
import '../utils/app_logger.dart';
import '../utils/completed_course_rules.dart';
import '../utils/gpa_calculator.dart';
import 'course_catalog_viewmodel.dart';
import 'plan_analyzer_viewmodel.dart';

/// Quản lý UID sinh viên đang đăng nhập (ưu tiên tài khoản Google đang đăng nhập thực tế).
class CurrentStudentUidNotifier extends Notifier<String> {
  @override
  String build() {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser != null && currentUser.uid.isNotEmpty) {
      return currentUser.uid;
    }
    return DatabaseSeeder.defaultStudent.uid;
  }

  void setUid(String uid) {
    if (state != uid) {
      state = uid;
    }
  }

  void clear() {
    state = '';
  }
}

final currentStudentUidProvider =
    NotifierProvider<CurrentStudentUidNotifier, String>(
  CurrentStudentUidNotifier.new,
);

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

  CompletedCoursesState copyWith({
    StudentProfileModel? profile,
    List<CompletedCourseModel>? completed,
    Set<String>? legacyPassedCodes,
    List<CourseModel>? catalog,
    String? selectedFilter,
  }) {
    return CompletedCoursesState(
      profile: profile ?? this.profile,
      completed: completed ?? this.completed,
      legacyPassedCodes: legacyPassedCodes ?? this.legacyPassedCodes,
      catalog: catalog ?? this.catalog,
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

  /// GPA tính tự động từ danh sách môn đã hoàn thành
  double get calculatedGpa {
    final validCourses = completed.where((c) => c.grade != null || c.gradeLetter != null).toList();
    if (validCourses.isNotEmpty) {
      return GpaCalculator.calculateGpa(validCourses);
    }
    return profile.currentGpa;
  }

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

  Set<String> get passedCodes => {
        ...profile.passedCourseCodes,
        ...completed.where((c) => c.isActuallyPassed).map((c) => c.code),
      };

  /// Môn trong catalog có thể thêm (chưa học hoặc đã từng rớt cần học lại)
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

  /// Học kỳ hiện tại dựa trên dữ liệu các môn đã học (VD: Đã học Kỳ 1 -> Học kỳ 2)
  int get currentSemesterIndex =>
      StudentService.computeCurrentSemesterIndex(completed);

  String get currentSemesterName =>
      StudentService.computeCurrentSemesterName(completed);
}

/// UC-13 / UC-13B: ViewModel của SCR-03 (Môn Đã Học) & Hồ sơ học tập sinh viên.
class CompletedCoursesViewModel extends AsyncNotifier<CompletedCoursesState> {
  @override
  Future<CompletedCoursesState> build() {
    final uid = ref.watch(currentStudentUidProvider);
    return _load(uid: uid);
  }

  Future<CompletedCoursesState> _load({String? uid, String? filter}) async {
    final String activeUid = uid ?? ref.read(currentStudentUidProvider);
    final studentService = ref.read(studentServiceProvider);
    final courseService = ref.read(courseServiceProvider);

    final profile = await studentService.getStudentProfile(activeUid);
    final completed = await studentService.getCompletedCourses(activeUid);
    final catalog = await courseService.getCourses();

    final completedCodes = completed.map((c) => c.code).toSet();
    final legacy = profile.passedCourseCodes.where((c) => !completedCodes.contains(c)).toSet();

    final validCourses = completed.where((c) => c.grade != null || c.gradeLetter != null).toList();
    final realGpa = validCourses.isNotEmpty
        ? GpaCalculator.calculateGpa(validCourses)
        : profile.currentGpa;
    final uniquePassed = <String, CompletedCourseModel>{};
    for (final c in completed) {
      if (c.isActuallyPassed) {
        uniquePassed[c.code] = c;
      }
    }
    final realCredits = completed.isNotEmpty
        ? uniquePassed.values.fold<int>(0, (int total, c) => total + c.credits)
        : profile.accumulatedCredits;

    final syncedProfile = profile.copyWith(
      currentGpa: realGpa,
      accumulatedCredits: realCredits,
    );

    var next = CompletedCoursesState(
      profile: syncedProfile,
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
      final updatedState = await _load(uid: uid, filter: filter);
      state = AsyncData(updatedState);

      // Đồng bộ danh sách môn đã học và học kỳ mới sang CourseCatalog & PlanAnalyzer
      ref.read(planAnalyzerViewModelProvider.notifier).syncPassedCourses(
            updatedState.passedCodes.toList(),
            semesterName: updatedState.currentSemesterName,
          );
      ref.invalidate(courseCatalogViewModelProvider);
      return null;
    } on ArgumentError catch (e) {
      return e.message?.toString() ?? 'Dữ liệu không hợp lệ.';
    } catch (e, st) {
      AppLogger.error('Lỗi khi thêm môn đã học ${course.code}', e, st);
      return 'Không thể lưu môn học. Vui lòng thử lại.';
    }
  }

  /// Cập nhật thông tin cá nhân của sinh viên (từ SCR-08 Profile Settings)
  Future<void> updatePersonalInfo({
    required String fullName,
    required String studentId,
    String? major,
    String? cohort,
    String? email,
    String? avatarUrl,
    double? currentGpa,
    double? targetGpa,
    int? totalGraduationCredits,
  }) async {
    final uid = ref.read(currentStudentUidProvider);
    final updatedProfile = await ref.read(studentServiceProvider).updatePersonalInfo(
          uid: uid,
          fullName: fullName,
          studentId: studentId,
          major: major,
          cohort: cohort,
          email: email,
          avatarUrl: avatarUrl,
          currentGpa: currentGpa,
          targetGpa: targetGpa,
          totalGraduationCredits: totalGraduationCredits,
        );

    if (targetGpa != null && targetGpa > 0) {
      ref.read(planAnalyzerViewModelProvider.notifier).syncTargetGpa(targetGpa);
    }

    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(profile: updatedProfile));
    } else {
      state = AsyncData(await _load(uid: uid));
    }
  }

  /// Cập nhật công tắc cài đặt trên SCR-08
  Future<void> updateSettings({
    bool? notifyLabDeadlines,
    bool? notificationEnabled,
    bool? autoWarnWorkload,
    bool? syncGoogleCalendar,
    bool? calendarSyncEnabled,
  }) async {
    final uid = ref.read(currentStudentUidProvider);
    if (autoWarnWorkload != null) {
      ref
          .read(planAnalyzerViewModelProvider.notifier)
          .syncAutoWarnWorkload(autoWarnWorkload);
    }
    final optimistic = state.value;
    if (optimistic != null) {
      state = AsyncData(
        optimistic.copyWith(
          profile: optimistic.profile.copyWith(
            notifyLabDeadlines:
                notifyLabDeadlines ?? notificationEnabled ?? optimistic.profile.notifyLabDeadlines,
            autoWarnWorkload: autoWarnWorkload ?? optimistic.profile.autoWarnWorkload,
            syncGoogleCalendar:
                syncGoogleCalendar ?? calendarSyncEnabled ?? optimistic.profile.syncGoogleCalendar,
          ),
        ),
      );
    }
    final updatedProfile = await ref.read(studentServiceProvider).updateSettings(
          uid: uid,
          notifyLabDeadlines: notifyLabDeadlines ?? notificationEnabled,
          autoWarnWorkload: autoWarnWorkload,
          syncGoogleCalendar: syncGoogleCalendar ?? calendarSyncEnabled,
        );
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(profile: updatedProfile));
    }
  }
}

final completedCoursesViewModelProvider =
    AsyncNotifierProvider<CompletedCoursesViewModel, CompletedCoursesState>(
  CompletedCoursesViewModel.new,
);
