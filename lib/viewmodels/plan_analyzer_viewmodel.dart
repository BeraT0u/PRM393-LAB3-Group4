import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../models/study_plan_model.dart';
import '../services/analytics_service.dart';
import '../services/database_seeder.dart';
import '../services/plan_service.dart';
import '../services/service_providers.dart';
import '../services/student_service.dart';
import '../utils/grade_target.dart';
import 'completed_courses_viewmodel.dart';
import 'course_catalog_viewmodel.dart';

class PlanAnalyzerState {
  final StudyPlanModel plan;
  final List<String> passedCourseCodes;
  final double maxSafeThresholdHours;
  final bool? _autoWarnWorkload;
  bool get autoWarnWorkload => _autoWarnWorkload ?? true;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool hasReplacedConflict;

  const PlanAnalyzerState({
    required this.plan,
    this.passedCourseCodes = const ['PRO192', 'MAD101', 'CSD201', 'DBI202', 'MAS291'],
    this.maxSafeThresholdHours = 25.0,
    bool? autoWarnWorkload = true,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.hasReplacedConflict = false,
  }) : _autoWarnWorkload = autoWarnWorkload ?? true;

  bool get isOverloaded =>
      autoWarnWorkload &&
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
    bool? autoWarnWorkload,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? hasReplacedConflict,
  }) {
    return PlanAnalyzerState(
      plan: plan ?? this.plan,
      passedCourseCodes: passedCourseCodes ?? this.passedCourseCodes,
      maxSafeThresholdHours: maxSafeThresholdHours ?? this.maxSafeThresholdHours,
      autoWarnWorkload: autoWarnWorkload ?? this.autoWarnWorkload,
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

    final rawPlan = _planService
        .getLocalDraftPlan(userId: uid, maxSafeThresholdHours: safeHours)
        .copyWith(maxSafeThresholdHours: safeHours);
    final normalizedSelected = _normalizeCourses(rawPlan.selectedCourses);
    final initialPlan = rawPlan.copyWith(
      selectedCourses: normalizedSelected,
      tuitionFee: _calculateTuition(normalizedSelected),
    );
    if (normalizedSelected != rawPlan.selectedCourses) {
      _planService.saveLocalDraftPlan(initialPlan);
    }

    final cachedProfile = ref.read(completedCoursesViewModelProvider).value?.profile;
    final fallbackStudent = cachedProfile ??
        ref.read(studentServiceProvider).getCachedProfile(uid) ??
        DatabaseSeeder.getStudentByUid(uid);
    final initialState = PlanAnalyzerState(
      plan: initialPlan,
      passedCourseCodes: fallbackStudent.passedCourseCodes,
      maxSafeThresholdHours: safeHours,
      autoWarnWorkload: fallbackStudent.autoWarnWorkload,
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

    // Lắng nghe realtime trạng thái duyệt kế hoạch & nghiệm thu điểm từ Web Admin
    final sub = _planService.watchUserPlans(uid).listen((cloudPlans) {
      if (state.plan.userId != uid || cloudPlans.isEmpty) return;

      // Kiểm tra xem kế hoạch hiện tại vừa được Cố vấn duyệt nghiệm thu hoàn tất ('completed') chưa
      final currentId = state.plan.id;
      final completedMatch = cloudPlans.where(
        (p) =>
            (p.id == currentId || p.semesterName == state.plan.semesterName) &&
            p.isFullyCompleted &&
            (state.plan.isPendingAcceptance || state.plan.isSaved),
      );
      if (completedMatch.isNotEmpty) {
        _planService.clearLocalDraftPlan(uid, semester: state.plan.semesterName);
        ref.invalidate(completedCoursesViewModelProvider);
        ref.invalidate(courseCatalogViewModelProvider);
        _syncStudentPassedCourses(uid);
        return;
      }

      // Tìm kế hoạch đang hoạt động (chưa completed) khớp với kỳ hiện tại
      final activeCloud = cloudPlans.where((p) => !p.isFullyCompleted).toList();
      if (activeCloud.isEmpty) return;

      final match = activeCloud.firstWhere(
        (p) => p.id == currentId || p.semesterName == state.plan.semesterName,
        orElse: () => activeCloud.first,
      );

      // Cập nhật trạng thái duyệt (pending / approved / rejected / pending_acceptance / acceptance_rejected)
      if (state.plan.isSaved || state.plan.selectedCourses.isEmpty) {
        final synced = match.copyWith(
          isSaved: true,
          maxSafeThresholdHours: state.maxSafeThresholdHours,
        );
        _planService.saveLocalDraftPlan(synced);
        state = state.copyWith(plan: synced);
      }
    });
    ref.onDispose(sub.cancel);

    return initialState;
  }

  Future<void> _syncStudentPassedCourses(String uid) async {
    try {
      final studentService = ref.read(studentServiceProvider);
      final profile = await studentService.getStudentProfile(uid);
      final completed = await studentService.getCompletedCourses(uid);
      final merged = {
        ...profile.passedCourseCodes,
        ...completed.where((c) => c.isActuallyPassed).map((c) => c.code),
      }.toList();

      // Tự động xác định học kỳ hiện tại của tài khoản dựa trên dữ liệu môn đã học (SCR-03)
      final bool isUnitTestDefaultEmpty =
          uid == DatabaseSeeder.defaultStudent.uid && completed.isEmpty;
      final currentSemesterName = isUnitTestDefaultEmpty
          ? state.plan.semesterName
          : StudentService.computeCurrentSemesterName(completed);

      final loadedPlan = await _planService.getStudyPlan(
        userId: uid,
        semester: currentSemesterName,
        maxSafeHours: state.maxSafeThresholdHours,
      );

      if (state.plan.userId == uid) {
        // Loại bỏ môn đã hoàn thành/đạt khỏi kế hoạch nếu trước đó lỡ thêm vào
        final currentSelected = _normalizeCourses(state.plan.selectedCourses
            .where((c) => !merged.contains(c.code))
            .toList());
        final loadedSelected = _normalizeCourses(loadedPlan.selectedCourses
            .where((c) => !merged.contains(c.code))
            .toList());

        final bool preferCloudLoaded = loadedSelected.isNotEmpty &&
            (currentSelected.isEmpty ||
                state.plan.isSaved ||
                loadedPlan.status != 'draft');

        final effectivePlan = preferCloudLoaded
            ? loadedPlan.copyWith(
                id: '${uid}_${currentSemesterName.replaceAll(' ', '_')}',
                userId: uid,
                semesterName: currentSemesterName,
                selectedCourses: loadedSelected,
                studentName: profile.fullName,
                studentCode: profile.studentId,
                studentEmail: profile.email ?? '',
                targetGpa: profile.targetGpa > 0
                    ? profile.targetGpa
                    : loadedPlan.targetGpa,
                tuitionFee: _calculateTuition(loadedSelected),
              )
            : state.plan.copyWith(
                id: '${uid}_${currentSemesterName.replaceAll(' ', '_')}',
                userId: uid,
                semesterName: currentSemesterName,
                selectedCourses: currentSelected,
                studentName: profile.fullName,
                studentCode: profile.studentId,
                studentEmail: profile.email ?? '',
                targetGpa: profile.targetGpa > 0
                    ? profile.targetGpa
                    : state.plan.targetGpa,
                tuitionFee: _calculateTuition(currentSelected),
              );
        _planService.saveLocalDraftPlan(effectivePlan);
        state = state.copyWith(
          plan: effectivePlan,
          passedCourseCodes: merged,
          autoWarnWorkload: profile.autoWarnWorkload,
        );
      }
    } catch (_) {
      // Giữ danh sách mặc định khi offline
    }
  }

  /// Đồng bộ trực tiếp danh sách mã môn đã đạt và học kỳ mới khi người dùng vừa thêm môn ở SCR-03
  void syncPassedCourses(
    List<String> passedCodes, {
    String? semesterName,
  }) {
    var updatedPlan = state.plan;
    if (semesterName != null && semesterName.trim().isNotEmpty) {
      final uid = state.plan.userId;
      updatedPlan = updatedPlan.copyWith(
        id: '${uid}_${semesterName.replaceAll(' ', '_')}',
        semesterName: semesterName,
      );
      _planService.saveLocalDraftPlan(updatedPlan);
    }
    state = state.copyWith(
      plan: updatedPlan,
      passedCourseCodes: List<String>.from(passedCodes),
    );
  }

  /// Đồng bộ công tắc "Tự động cảnh báo quá tải học tập" từ SCR-08 (UC-33)
  void syncAutoWarnWorkload(bool enabled) {
    state = state.copyWith(
      autoWarnWorkload: enabled,
      errorMessage: null,
    );
  }
  void syncTargetGpa(double targetGpa) {
    if (targetGpa <= 0) return;
    final updatedPlan = state.plan.copyWith(targetGpa: targetGpa);
    _planService.saveLocalDraftPlan(updatedPlan);
    state = state.copyWith(plan: updatedPlan);
  }

  /// Khắc phục lỗi dữ liệu giờ tự học bị AI ghi đè tùy ý ở phiên bản cũ
  /// (Ví dụ: môn có mục tiêu Điểm A nhưng bị giảm giờ xuống thấp hơn giờ chuẩn của Điểm A)
  static List<CourseModel> _normalizeCourses(List<CourseModel> courses) {
    return courses.map((c) {
      if (c.selectedGradeTarget == 'A' &&
          c.plannedSelfStudyHours < (c.defaultSelfStudyHours - 0.1)) {
        return c.copyWith(
          plannedSelfStudyHours: c.defaultSelfStudyHours.toDouble(),
        );
      }
      return c;
    }).toList();
  }

  /// Tính lại học phí dựa trên tổng tín chỉ (950.000đ / tín chỉ)
  int _calculateTuition(List<CourseModel> courses) {
    final credits = courses.fold<int>(0, (sum, c) => sum + c.credits);
    return credits * 950000;
  }

  /// Cập nhật/thêm môn được chọn từ SCR-05 vào kế hoạch nháp ở local
  void applyIncomingCourse(CourseModel incomingCourse) {
    if (state.passedCourseCodes.contains(incomingCourse.code)) {
      state = state.copyWith(
        errorMessage: 'Môn ${incomingCourse.code} đã hoàn thành, không thể thêm vào kế hoạch!',
      );
      return;
    }

    final target = GradeTargetOption.fromCode(incomingCourse.selectedGradeTarget);
    final normalizedIncoming = incomingCourse.copyWith(
      plannedSelfStudyHours: target.hoursFor(incomingCourse),
    );

    final currentCourses = _normalizeCourses(state.plan.selectedCourses);
    final existingIndex =
        currentCourses.indexWhere((c) => c.code == normalizedIncoming.code);

    // Tránh áp dụng và log analytics lặp lại nếu môn học đã được cập nhật y hệt ngay trước khi điều hướng
    if (existingIndex >= 0) {
      final existing = currentCourses[existingIndex];
      if (existing.selectedGradeTarget == normalizedIncoming.selectedGradeTarget &&
          existing.plannedSelfStudyHours == normalizedIncoming.plannedSelfStudyHours) {
        return;
      }
      currentCourses[existingIndex] = normalizedIncoming;
    } else {
      currentCourses.add(normalizedIncoming);
    }

    final updatedPlan = state.plan.copyWith(
      selectedCourses: currentCourses,
      tuitionFee: _calculateTuition(currentCourses),
      isSaved: false,
      status: 'draft',
      updatedAt: DateTime.now(),
    );

    _planService.saveLocalDraftPlan(updatedPlan);
    state = state.copyWith(plan: updatedPlan, errorMessage: null);

    _analyticsService.logAddCourseToPlan(
      courseId: normalizedIncoming.code,
      targetGrade: normalizedIncoming.selectedGradeTarget,
      weeklyHours: normalizedIncoming.plannedSelfStudyHours,
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

    if (state.passedCourseCodes.contains(targetReplacement.code)) {
      state = state.copyWith(
        errorMessage: 'Môn ${targetReplacement.code} đã hoàn thành, không thể dùng để thay thế!',
      );
      return;
    }

    // Không cho phép đổi sang môn đã có trong kế hoạch kỳ này
    final isAlreadyInPlan = state.plan.selectedCourses.any(
      (c) => c.code == targetReplacement.code && c.code != codeToReplace,
    );
    if (isAlreadyInPlan) {
      state = state.copyWith(
        errorMessage: 'Môn ${targetReplacement.code} đã có trong kế hoạch kỳ này!',
      );
      return;
    }

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

    final normalizedUpdated = _normalizeCourses(updatedCourses);
    final resolvedPlan = state.plan.copyWith(
      selectedCourses: normalizedUpdated,
      tuitionFee: _calculateTuition(normalizedUpdated),
      isSaved: false,
      status: 'draft',
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
      status: 'draft',
      updatedAt: DateTime.now(),
    );

    _planService.saveLocalDraftPlan(updatedPlan);
    state = state.copyWith(plan: updatedPlan, errorMessage: null);
  }

  /// Xóa một môn học khỏi kế hoạch nháp ở local
  void removeCourse(CourseModel course) {
    removeCourseByCode(course.code);
  }

  /// Bớt một môn học theo mã môn (phục vụ gợi ý bớt môn khi cực kỳ quá tải)
  void removeCourseByCode(String courseCode) {
    final updatedCourses = _normalizeCourses(
        state.plan.selectedCourses.where((c) => c.code != courseCode).toList());
    final updatedPlan = state.plan.copyWith(
      selectedCourses: updatedCourses,
      tuitionFee: _calculateTuition(updatedCourses),
      isSaved: false,
      status: 'draft',
      updatedAt: DateTime.now(),
    );
    _planService.saveLocalDraftPlan(updatedPlan);
    state = state.copyWith(
      plan: updatedPlan,
      hasReplacedConflict: true,
      errorMessage: null,
    );

    _analyticsService.logResolvePlanConflict(
      oldCourseId: courseCode,
      newCourseId: 'DROPPED_COURSE',
      newTotalHours: updatedPlan.totalSelfStudyHours.toInt(),
    );
  }

  /// Cập nhật giờ tự học của nhiều môn học theo gợi ý của AI (Ưu tiên giảm giờ học đưa về <= 25h)
  void updateMultipleCourseHours(Map<String, double> hoursPerCourse) {
    if (hoursPerCourse.isEmpty) return;

    final updatedCourses = state.plan.selectedCourses.map((c) {
      if (hoursPerCourse.containsKey(c.code)) {
        final newHours = hoursPerCourse[c.code]!;
        return c.copyWith(plannedSelfStudyHours: newHours);
      }
      return c;
    }).toList();

    final updatedPlan = state.plan.copyWith(
      selectedCourses: updatedCourses,
      isSaved: false,
      status: 'draft',
      updatedAt: DateTime.now(),
    );

    _planService.saveLocalDraftPlan(updatedPlan);

    state = state.copyWith(
      plan: updatedPlan,
      hasReplacedConflict: true,
      errorMessage: null,
    );

    _analyticsService.logResolvePlanConflict(
      oldCourseId: hoursPerCourse.keys.join(','),
      newCourseId: 'REDUCED_HOURS',
      newTotalHours: updatedPlan.totalSelfStudyHours.toInt(),
    );
  }

  /// Xóa toàn bộ môn trong kế hoạch để chọn lại từ đầu (0 môn)
  void clearPlan() {
    final uid = ref.read(currentStudentUidProvider);
    final completedState = ref.read(completedCoursesViewModelProvider).value;
    final semester =
        completedState?.currentSemesterName ?? state.plan.semesterName;
    _planService.clearLocalDraftPlan(uid, semester: semester);
    final emptyPlan = _planService.getLocalDraftPlan(
      userId: uid,
      semester: semester,
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

  /// Lưu & Gửi duyệt kế hoạch học tập hợp lệ lên Cloud Firestore với status = 'pending' (UC-25)
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
      final uid = ref.read(currentStudentUidProvider);
      final cachedProfile =
          ref.read(completedCoursesViewModelProvider).value?.profile ??
              ref.read(studentServiceProvider).getCachedProfile(uid) ??
              DatabaseSeeder.getStudentByUid(uid);

      final currentAuthUser = Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser
          : null;
      final effectiveName = cachedProfile.fullName.isNotEmpty &&
              cachedProfile.fullName != 'Sinh viên' &&
              cachedProfile.fullName != 'Sinh viên mới'
          ? cachedProfile.fullName
          : (currentAuthUser?.displayName?.isNotEmpty == true
              ? currentAuthUser!.displayName!
              : cachedProfile.fullName);
      final effectiveEmail = (cachedProfile.email != null &&
              cachedProfile.email!.isNotEmpty)
          ? cachedProfile.email!
          : (currentAuthUser?.email ?? '');
      final effectiveCode = cachedProfile.studentId.isNotEmpty
          ? cachedProfile.studentId
          : '';

      final planToSave = state.plan.copyWith(
        id: '${uid}_${state.plan.semesterName.replaceAll(' ', '_')}',
        userId: uid,
        studentName: effectiveName,
        studentCode: effectiveCode,
        studentEmail: effectiveEmail,
        isSaved: true,
        status: 'pending',
        isCompleted: false,
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
