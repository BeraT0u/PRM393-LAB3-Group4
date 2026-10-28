import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../services/service_providers.dart';
import '../utils/grade_target.dart';
import 'completed_courses_viewmodel.dart' show currentStudentUidProvider;

/// Trạng thái dữ liệu của SCR-05 (Course Strategy).
class CourseDetailState {
  final CourseModel course;
  final GradeTargetOption target;
  final bool isFavorite;

  /// `true` nếu không có tiên quyết hoặc sinh viên đã hoàn thành môn tiên quyết.
  final bool prerequisiteMet;

  const CourseDetailState({
    required this.course,
    required this.target,
    this.isFavorite = false,
    this.prerequisiteMet = true,
  });

  CourseDetailState copyWith({GradeTargetOption? target, bool? isFavorite}) {
    return CourseDetailState(
      course: course,
      target: target ?? this.target,
      isFavorite: isFavorite ?? this.isFavorite,
      prerequisiteMet: prerequisiteMet,
    );
  }

  String? get prerequisiteCode {
    final code = course.prerequisiteCode?.trim();
    return (code == null || code.isEmpty) ? null : code;
  }

  /// Giờ tự học dự kiến theo mục tiêu điểm đang chọn
  double get plannedHours => target.hoursFor(course);

  /// Môn kèm mục tiêu điểm và giờ tự học đã chọn, gửi sang SCR-06A khi "Thêm vào Kế hoạch".
  CourseModel get plannedCourse => course.copyWith(
        selectedGradeTarget: target.code,
        plannedSelfStudyHours: plannedHours,
      );
}

/// UC-16 → UC-19: ViewModel của SCR-05, theo từng mã môn ([courseCode]).
class CourseDetailViewModel extends AsyncNotifier<CourseDetailState> {
  final String courseCode;

  CourseDetailViewModel(this.courseCode);

  @override
  Future<CourseDetailState> build() async {
    final course = await ref.read(courseServiceProvider).getCourseById(courseCode);
    if (course == null) {
      throw StateError('Không tìm thấy môn học $courseCode');
    }

    var prerequisiteMet = true;
    final prereq = course.prerequisiteCode?.trim();
    if (prereq != null && prereq.isNotEmpty) {
      final uid = ref.read(currentStudentUidProvider);
      final studentService = ref.read(studentServiceProvider);
      final profile = await studentService.getStudentProfile(uid);
      final completed = await studentService.getCompletedCourses(uid);
      final passed = {...profile.passedCourseCodes, ...completed.map((c) => c.code)};
      prerequisiteMet = passed.contains(prereq);
    }

    return CourseDetailState(
      course: course,
      target: GradeTargetOption.fromCode(course.selectedGradeTarget),
      prerequisiteMet: prerequisiteMet,
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  void selectTarget(GradeTargetOption target) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(target: target));
  }

  void toggleFavorite() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isFavorite: !current.isFavorite));
  }
}

final courseDetailViewModelProvider =
    AsyncNotifierProvider.family<CourseDetailViewModel, CourseDetailState, String>(
  CourseDetailViewModel.new,
);
