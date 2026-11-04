import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../models/study_plan_model.dart';
import '../services/analytics_service.dart';
import '../services/database_seeder.dart';
import '../services/plan_service.dart';
import '../services/service_providers.dart';
import '../utils/grade_target.dart';
import 'completed_courses_viewmodel.dart';
import 'course_catalog_viewmodel.dart';

class PlanAnalyzerState {
  final StudyPlanModel plan;
  final List<String> passedCourseCodes;
  final double maxSafeThresholdHours;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool hasReplacedConflict;

  const PlanAnalyzerState({
    required this.plan,
    this.passedCourseCodes = const ['PRO192', 'MAD101', 'CSD201', 'DBI202', 'MAS291'],
    this.maxSafeThresholdHours = 25.0,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.hasReplacedConflict = false,
  });

  bool get isOverloaded =>
      plan.totalSelfStudyHours >
      (hasReplacedConflict ? 26.0 : maxSafeThresholdHours);

  List<String> get prerequisiteViolations =>
      plan.getPrerequisiteViolations(passedCourseCodes);

  bool get hasConflict => isOverloaded || prerequisiteViolations.isNotEmpty;

  int get conflictCount =>
      prerequisiteViolations.length +
      (isOverloaded && prerequisiteViolations.isEmpty ? 1 : 0);

  int get totalCredits => plan.totalCredits;
  double get totalHours => plan.totalSelfStudyHours;
  int get courseCount => plan.selectedCourses.length;

  bool isCoursePrerequisiteMet(CourseModel course) {
    return course.prerequisiteCode == null ||
        passedCourseCodes.contains(course.prerequisiteCode);
  }

  /// Môn học đang gây xung đột ưu tiên (vi phạm tiên quyết trước, sau đó đến môn nặng nhất khi quá tải)
  CourseModel? get conflictCourse {
    for (final c in plan.selectedCourses) {
      if (c.prerequisiteCode != null &&
          !passedCourseCodes.contains(c.prerequisiteCode)) {
        return c;
      }
    }
    if (isOverloaded && plan.selectedCourses.isNotEmpty) {
      final sorted = List<CourseModel>.from(plan.selectedCourses)
        ..sort((a, b) => b.plannedSelfStudyHours.compareTo(a.plannedSelfStudyHours));
      return sorted.first;
    }
    return null;
  }

  PlanAnalyzerState copyWith({
    StudyPlanModel? plan,
    List<String>? passedCourseCodes,
    double? maxSafeThresholdHours,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? hasReplacedConflict,
  }) {
    return PlanAnalyzerState(
      plan: plan ?? this.plan,
      passedCourseCodes: passedCourseCodes ?? this.passedCourseCodes,
      maxSafeThresholdHours: maxSafeThresholdHours ?? this.maxSafeThresholdHours,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      hasReplacedConflict: hasReplacedConflict ?? this.hasReplacedConflict,
    );
  }
}

class PlanAnalyzerViewModel extends Notifier<PlanAnalyzerState> {
  late PlanService _planService;
  late AnalyticsService _analyticsService;

  @override
  PlanAnalyzerState build() {
    _planService = ref.watch(planServiceProvider);
    _analyticsService = ref.watch(analyticsServiceProvider);
    final uid = ref.watch(currentStudentUidProvider);

    // Lấy ngưỡng an toàn từ Remote Config (mặc định 25.0h)
    double safeHours = 25.0;
    try {
      if (Firebase.apps.isNotEmpty) {
        final rc = FirebaseRemoteConfig.instance;
        final val = rc.getDouble('max_safe_workload_hours');
        if (val > 0) safeHours = val;
      }
    } catch (_) {
      safeHours = 25.0;
    }

    final initialPlan = _planService
        .getLocalDraftPlan(userId: uid, maxSafeThresholdHours: safeHours)
        .copyWith(maxSafeThresholdHours: safeHours);

    final fallbackStudent = DatabaseSeeder.getStudentByUid(uid);
    final initialState = PlanAnalyzerState(
      plan: initialPlan,
      passedCourseCodes: fallbackStudent.passedCourseCodes,
      maxSafeThresholdHours: safeHours,
    );

    if (initialState.hasConflict && initialState.conflictCourse != null) {
      _analyticsService.logDetectPlanConflict(
        totalHours: initialState.totalHours.toInt(),
        violatedCourseId: initialState.conflictCourse!.code,
        conflictType: initialState.isOverloaded
            ? (initialState.prerequisiteViolations.isNotEmpty
                ? 'overload_and_prerequisite'
                : 'overload')
            : 'prerequisite',
      );
    }

    Future.microtask(() => _syncStudentPassedCourses(uid));

    return initialState;
  }

  Future<void> _syncStudentPassedCourses(String uid) async {
    try {
      final studentService = ref.read(studentServiceProvider);
      final profile = await studentService.getStudentProfile(uid);
      final completed = await studentService.getCompletedCourses(uid);
      final merged = {
        ...profile.passedCourseCodes,
        ...completed.map((c) => c.code),
      }.toList();
      if (state.plan.userId == uid) {
        state = state.copyWith(passedCourseCodes: merged);
      }
    } catch (_) {
      // Giữ danh sách mặc định khi offline
    }
  }

  /// Đồng bộ trực tiếp danh sách mã môn đã đạt khi người dùng vừa thêm môn ở SCR-03
  void syncPassedCourses(List<String> passedCodes) {
    state = state.copyWith(passedCourseCodes: List<String>.from(passedCodes));
  }

  /// Tính lại học phí dựa trên tổng tín chỉ (950.000đ / tín chỉ)
  int _calculateTuition(List<CourseModel> courses) {
    final credits = courses.fold<int>(0, (sum, c) => sum + c.credits);
    return credits * 950000;
  }

  /// Cập nhật/thêm môn được chọn từ SCR-05 vào kế hoạch nháp ở local
  void applyIncomingCourse(CourseModel incomingCourse) {
    final currentCourses = List<CourseModel>.from(state.plan.selectedCourses);
    final existingIndex =
        currentCourses.indexWhere((c) => c.code == incomingCourse.code);

    if (existingIndex >= 0) {
      currentCourses[existingIndex] = incomingCourse;
    } else {
      currentCourses.add(incomingCourse);
    }

    final updatedPlan = state.plan.copyWith(
      selectedCourses: currentCourses,
      tuitionFee: _calculateTuition(currentCourses),
      isSaved: false,
      updatedAt: DateTime.now(),
    );

    _planService.saveLocalDraftPlan(updatedPlan);
    state = state.copyWith(plan: updatedPlan, errorMessage: null);

    _analyticsService.logAddCourseToPlan(
      courseId: incomingCourse.code,
      targetGrade: incomingCourse.selectedGradeTarget,
      weeklyHours: incomingCourse.plannedSelfStudyHours,
    );

    if (state.hasConflict && state.conflictCourse != null) {
      _analyticsService.logDetectPlanConflict(
        totalHours: state.totalHours.toInt(),
        violatedCourseId: state.conflictCourse!.code,
        conflictType: state.isOverloaded
            ? (state.prerequisiteViolations.isNotEmpty
                ? 'overload_and_prerequisite'
                : 'overload')
            : 'prerequisite',
      );
    }
  }

  /// Khắc phục xung đột: Hoán đổi môn xung đột sang môn thay thế (mặc định PRM323)
  void replaceConflictCourse({
    CourseModel? replacement,
    String? targetCodeToReplace,
  }) {
    final conflict = state.conflictCourse;
    final codeToReplace = targetCodeToReplace ?? conflict?.code ?? 'IAE201';
    final targetReplacement = replacement ??
        DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'PRM323');

    final updatedCourses = <CourseModel>[];
    bool replaced = false;

    for (final c in state.plan.selectedCourses) {
      if (!replaced && c.code == codeToReplace) {
        if (!updatedCourses.any((item) => item.code == targetReplacement.code)) {
          updatedCourses.add(targetReplacement);
        }
        replaced = true;
      } else if (c.code != targetReplacement.code) {
        updatedCourses.add(c);
      }
    }

    if (!replaced &&
        !updatedCourses.any((item) => item.code == targetReplacement.code)) {
      updatedCourses.add(targetReplacement);
    }

    final resolvedPlan = state.plan.copyWith(
      selectedCourses: updatedCourses,
      tuitionFee: _calculateTuition(updatedCourses),
      isSaved: false,
      updatedAt: DateTime.now(),
    );

    _planService.saveLocalDraftPlan(resolvedPlan);

    state = state.copyWith(
      plan: resolvedPlan,
      hasReplacedConflict: true,
      errorMessage: null,
    );

    _analyticsService.logResolvePlanConflict(
      oldCourseId: codeToReplace,
      newCourseId: targetReplacement.code,
      newTotalHours: resolvedPlan.totalSelfStudyHours.toInt(),
    );
  }

  /// Đổi mục tiêu điểm (A / B / PASS) của một môn ngay trong kế hoạch
  void updateCourseTarget(String courseCode, GradeTargetOption target) {
    final updatedCourses = state.plan.selectedCourses.map((c) {
      if (c.code == courseCode) {
        return c.copyWith(
          selectedGradeTarget: target.code,
          plannedSelfStudyHours: target.hoursFor(c),
        );
      }
      return c;
    }).toList();

    final updatedPlan = state.plan.copyWith(
      selectedCourses: updatedCourses,
      isSaved: false,
      updatedAt: DateTime.now(),
    );

    _planService.saveLocalDraftPlan(updatedPlan);
    state = state.copyWith(plan: updatedPlan, errorMessage: null);
  }

  /// Xóa một môn học khỏi kế hoạch nháp ở local
  void removeCourse(CourseModel course) {
    final updatedCourses =
        state.plan.selectedCourses.where((c) => c.code != course.code).toList();
    final updatedPlan = state.plan.copyWith(
      selectedCourses: updatedCourses,
      tuitionFee: _calculateTuition(updatedCourses),
      isSaved: false,
      updatedAt: DateTime.now(),
    );
    _planService.saveLocalDraftPlan(updatedPlan);
    state = state.copyWith(plan: updatedPlan, errorMessage: null);
  }

  /// Xóa toàn bộ môn trong kế hoạch để chọn lại từ đầu (0 môn)
  void clearPlan() {
    final uid = ref.read(currentStudentUidProvider);
    _planService.clearLocalDraftPlan(uid);
    final emptyPlan = _planService.getLocalDraftPlan(
      userId: uid,
      maxSafeThresholdHours: state.maxSafeThresholdHours,
    );
    state = state.copyWith(
      plan: emptyPlan,
      hasReplacedConflict: false,
      errorMessage: null,
    );
  }

  /// Nạp nhanh tổ hợp 4 môn xung đột mẫu (34h/tuần + IAE201 thiếu tiên quyết)
  void loadSampleConflictPlan() {
    final uid = ref.read(currentStudentUidProvider);
    final samplePlan = DatabaseSeeder.getInitialConflictPlan(uid).copyWith(
      maxSafeThresholdHours: state.maxSafeThresholdHours,
    );
    _planService.saveLocalDraftPlan(samplePlan);
    state = state.copyWith(
      plan: samplePlan,
      hasReplacedConflict: false,
      errorMessage: null,
    );
    if (state.hasConflict && state.conflictCourse != null) {
      _analyticsService.logDetectPlanConflict(
        totalHours: state.totalHours.toInt(),
        violatedCourseId: state.conflictCourse!.code,
        conflictType: state.isOverloaded
            ? (state.prerequisiteViolations.isNotEmpty
                ? 'overload_and_prerequisite'
                : 'overload')
            : 'prerequisite',
      );
    }
  }

  /// Lưu kế hoạch học tập hợp lệ lên Cloud Firestore (UC-25)
  Future<bool> savePlan() async {
    if (state.courseCount == 0) {
      state = state.copyWith(
        errorMessage: 'Vui lòng chọn ít nhất 1 môn học trước khi lưu kế hoạch!',
      );
      return false;
    }

    if (state.hasConflict) {
      state = state.copyWith(
        errorMessage: 'Vui lòng giải quyết xung đột trước khi lưu!',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final planToSave = state.plan.copyWith(
        isSaved: true,
        updatedAt: DateTime.now(),
      );

      await _planService.saveStudyPlan(planToSave);
      await _analyticsService.logSaveStudyPlan(
        planId: planToSave.id,
        courseCount: planToSave.selectedCourses.length,
        totalCredits: planToSave.totalCredits,
        totalHours: planToSave.totalSelfStudyHours,
      );
      state = state.copyWith(isSaving: false, plan: planToSave);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Lưu thất bại: $e',
      );
      return false;
    }
  }

  /// Cập nhật URL file PDF sau khi tải lên Firebase Storage thành công (UC-29)
  Future<void> updatePlanPdfUrl(String downloadUrl) async {
    final updatedPlan = state.plan.copyWith(
      pdfDownloadUrl: downloadUrl,
      updatedAt: DateTime.now(),
    );
    _planService.saveLocalDraftPlan(updatedPlan);
    state = state.copyWith(plan: updatedPlan);
    await _planService.saveStudyPlan(updatedPlan);
  }

  /// Đánh dấu hoàn thành kỳ học hiện tại: chuyển các môn trong kế hoạch sang Đã học (SCR-03)
  Future<bool> completeCurrentSemester() async {
    if (state.courseCount == 0) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final uid = ref.read(currentStudentUidProvider);
      final studentService = ref.read(studentServiceProvider);
      await studentService.completeSemesterFromPlan(
        uid: uid,
        plan: state.plan,
      );
      clearPlan();
      ref.invalidate(completedCoursesViewModelProvider);
      ref.invalidate(courseCatalogViewModelProvider);
      await _syncStudentPassedCourses(uid);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Không thể hoàn tất kỳ học: $e',
      );
      return false;
    }
  }
}

final planAnalyzerViewModelProvider =
    NotifierProvider<PlanAnalyzerViewModel, PlanAnalyzerState>(
  PlanAnalyzerViewModel.new,
);
