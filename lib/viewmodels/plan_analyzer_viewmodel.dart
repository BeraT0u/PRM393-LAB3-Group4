import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../models/study_plan_model.dart';
import '../services/analytics_service.dart';
import '../services/database_seeder.dart';
import '../services/plan_service.dart';
import '../services/service_providers.dart';

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

  bool get isOverloaded => plan.totalSelfStudyHours > maxSafeThresholdHours;

  List<String> get prerequisiteViolations =>
      plan.getPrerequisiteViolations(passedCourseCodes);

  bool get hasConflict => isOverloaded || prerequisiteViolations.isNotEmpty;

  int get totalCredits => plan.totalCredits;
  double get totalHours => plan.totalSelfStudyHours;
  int get courseCount => plan.selectedCourses.length;

  /// Môn học đang vi phạm tiên quyết (nếu có)
  CourseModel? get conflictCourse {
    for (final c in plan.selectedCourses) {
      if (c.prerequisiteCode != null &&
          !passedCourseCodes.contains(c.prerequisiteCode)) {
        return c;
      }
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
  late final PlanService _planService;
  late final AnalyticsService _analyticsService;

  @override
  PlanAnalyzerState build() {
    _planService = ref.watch(planServiceProvider);
    _analyticsService = ref.watch(analyticsServiceProvider);

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

    final initialPlan = DatabaseSeeder.getInitialConflictPlan(DatabaseSeeder.defaultStudent.uid)
        .copyWith(maxSafeThresholdHours: safeHours);

    final initialState = PlanAnalyzerState(
      plan: initialPlan,
      passedCourseCodes: DatabaseSeeder.defaultStudent.passedCourseCodes,
      maxSafeThresholdHours: safeHours,
    );

    // Ghi nhận sự kiện phát hiện xung đột nếu có
    if (initialState.hasConflict && initialState.conflictCourse != null) {
      _analyticsService.logDetectPlanConflict(
        totalHours: initialState.totalHours.toInt(),
        violatedCourseId: initialState.conflictCourse!.code,
        conflictType: initialState.isOverloaded ? 'overload_and_prerequisite' : 'prerequisite',
      );
    }

    return initialState;
  }

  /// Cập nhật môn được thêm từ SCR-05 (nếu có)
  void applyIncomingCourse(CourseModel incomingCourse) {
    final currentCourses = List<CourseModel>.from(state.plan.selectedCourses);
    final existingIndex = currentCourses.indexWhere((c) => c.code == incomingCourse.code);

    if (existingIndex >= 0) {
      currentCourses[existingIndex] = incomingCourse;
    } else {
      currentCourses.add(incomingCourse);
    }

    final updatedPlan = state.plan.copyWith(
      selectedCourses: currentCourses,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(plan: updatedPlan);

    if (state.hasConflict && state.conflictCourse != null) {
      _analyticsService.logDetectPlanConflict(
        totalHours: state.totalHours.toInt(),
        violatedCourseId: state.conflictCourse!.code,
        conflictType: state.isOverloaded ? 'overload_and_prerequisite' : 'prerequisite',
      );
    }
  }

  /// Khắc phục xung đột: Hoán đổi môn lỗi (IAE201) sang môn thay thế (mặc định PRM323)
  void replaceConflictCourse({CourseModel? replacement}) {
    final conflict = state.conflictCourse;
    final targetReplacement = replacement ??
        DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'PRM323');

    final updatedCourses = state.plan.selectedCourses.map((c) {
      if (conflict != null && c.code == conflict.code) {
        return targetReplacement;
      }
      return c;
    }).toList();

    // Nếu không tìm thấy bằng conflictCourse, thay thế IAE201 trực tiếp nếu có
    if (conflict == null) {
      final idx = updatedCourses.indexWhere((c) => c.code == 'IAE201');
      if (idx >= 0) {
        updatedCourses[idx] = targetReplacement;
      }
    }

    final resolvedPlan = state.plan.copyWith(
      selectedCourses: updatedCourses,
      maxSafeThresholdHours: 28.0,
      isSaved: false,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      plan: resolvedPlan,
      maxSafeThresholdHours: 28.0,
      hasReplacedConflict: true,
      errorMessage: null,
    );

    _analyticsService.logResolvePlanConflict(
      oldCourseId: conflict?.code ?? 'IAE201',
      newCourseId: targetReplacement.code,
      newTotalHours: resolvedPlan.totalSelfStudyHours.toInt(),
    );
  }

  /// Xóa một môn học khỏi kế hoạch
  void removeCourse(CourseModel course) {
    final updatedCourses = state.plan.selectedCourses.where((c) => c.code != course.code).toList();
    final updatedPlan = state.plan.copyWith(
      selectedCourses: updatedCourses,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(plan: updatedPlan);
  }

  /// Lưu kế hoạch học tập hợp lệ lên Cloud Firestore (UC-25)
  Future<bool> savePlan() async {
    if (state.hasConflict) {
      state = state.copyWith(errorMessage: 'Vui lòng giải quyết xung đột trước khi lưu!');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final planToSave = state.plan.copyWith(
        isSaved: true,
        updatedAt: DateTime.now(),
      );

      await _planService.saveStudyPlan(planToSave);
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
}

final planAnalyzerViewModelProvider =
    NotifierProvider<PlanAnalyzerViewModel, PlanAnalyzerState>(PlanAnalyzerViewModel.new);
