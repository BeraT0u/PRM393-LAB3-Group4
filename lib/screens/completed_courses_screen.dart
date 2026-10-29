import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/completed_course_model.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/completed_course_rules.dart';
import '../viewmodels/completed_courses_viewmodel.dart';
import '../widgets/widgets.dart';

/// UC-13 / UC-13B: SCR-03 — Môn Đã Học (Completed Courses) & modal thêm môn theo kỳ.
class CompletedCoursesScreen extends ConsumerWidget {
  const CompletedCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(completedCoursesViewModelProvider);
    final vm = ref.read(completedCoursesViewModelProvider.notifier);

    return MainScaffold(
      currentTabIndex: 1,
      appBar: const AppTopBar(
        title: 'Môn Đã Học',
        subtitle: 'Tiến độ tích lũy tín chỉ tốt nghiệp',
      ),
      dockedFooter: async.hasValue
          ? AppPrimaryButton(
              label: 'Thêm môn đã học',
              leadingIcon: Icons.add_rounded,
              onPressed: () => _openAddSheet(context),
            )
          : null,
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppSkeletonLoading(itemCount: 4),
        ),
        error: (e, _) => AppErrorState(
          message: 'Không thể tải danh sách môn đã học. Vui lòng thử lại.',
          onRetry: vm.reload,
        ),
        data: (state) => _CompletedCoursesBody(state: state, onFilter: vm.selectFilter),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => const AddCompletedCourseSheet(),
    );
  }
}

class _CompletedCoursesBody extends StatelessWidget {
  final CompletedCoursesState state;
  final ValueChanged<String> onFilter;

  const _CompletedCoursesBody({required this.state, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    final courses = state.visibleCourses;
    final isAll = state.selectedFilter == CompletedCoursesState.filterAll;
    final hint = state.unlockHint;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.bottomClearanceDockedBtn,
      ),
      children: [
        if (state.profile.isNewStudent) ...[
          const AppAlertBanner(
            variant: AlertBannerVariant.warning,
            message: 'Hồ sơ học tập mới - Chưa có dữ liệu. Vui lòng thiết lập '
                'thông tin cá nhân và cập nhật các môn học đã hoàn thành.',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _ProgressCard(state: state),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.lock_open_rounded, size: 16, color: AppColors.successText),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successText,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppFilterChips(
          categories: state.filterLabels,
          selectedCategory: state.selectedFilter,
          onSelected: onFilter,
        ),
        const SizedBox(height: AppSpacing.md),
        if (courses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: AppEmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Chưa có môn nào',
              subtitle: isAll
                  ? 'Bấm "Thêm môn đã học" để khai báo các môn bạn đã hoàn thành.'
                  : 'Không có môn nào trong bộ lọc "${state.selectedFilter}".',
              actionLabel: 'Xóa bộ lọc',
              onAction: isAll ? null : () => onFilter(CompletedCoursesState.filterAll),
            ),
          )
        else
          for (final c in courses) ...[
            _CompletedCourseTile(course: c),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final CompletedCoursesState state;

  const _ProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = state.profile;

    return Semantics(
      container: true,
      label: 'Tiến độ tích lũy ${p.accumulatedCredits} trên ${p.totalGraduationCredits} '
          'tín chỉ, ${state.progressPercent} phần trăm',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.borderStructural),
          boxShadow: AppElevation.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p.accumulatedCredits}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  ' / ${p.totalGraduationCredits} TC',
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                StatusBadge(
                  label: '${state.progressPercent}%',
                  type: StatusBadgeType.primaryTonal,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 8,
                backgroundColor: AppColors.borderStructural,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'GPA hiện tại ${p.currentGpa.toStringAsFixed(2)} • '
              'Mục tiêu ${p.targetGpa.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedCourseTile extends StatelessWidget {
  final CompletedCourseModel course;

  const _CompletedCourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semester = course.semesterIndex != null
        ? 'Kỳ ${course.semesterIndex}'
        : (course.semesterName ?? 'Chưa phân kỳ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderStructural),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.code,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (course.name.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusBadge(label: semester, type: StatusBadgeType.neutral),
                    if (course.credits > 0)
                      StatusBadge(label: '${course.credits} TC', type: StatusBadgeType.primaryTonal),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (course.gradeLetter != null)
            StatusBadge(
              label: 'Điểm ${course.gradeLetter}',
              type: StatusBadgeType.success,
              icon: Icons.check_circle_rounded,
            )
          else
            const StatusBadge(
              label: 'Đã đạt',
              type: StatusBadgeType.success,
              icon: Icons.check_circle_rounded,
            ),
        ],
      ),
    );
  }
}

/// UC-13B: Modal thêm môn đã học theo kỳ — cảnh báo ràng buộc ngay khi chọn.
class AddCompletedCourseSheet extends ConsumerStatefulWidget {
  const AddCompletedCourseSheet({super.key});

  @override
  ConsumerState<AddCompletedCourseSheet> createState() => _AddCompletedCourseSheetState();
}

class _AddCompletedCourseSheetState extends ConsumerState<AddCompletedCourseSheet> {
  final _gradeController = TextEditingController(text: '8.0');
  int _semester = 1;
  CourseModel? _course;
  String? _submitError;
  bool _saving = false;

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final course = _course;
    if (course == null) return;
    setState(() {
      _saving = true;
      _submitError = null;
    });

    final grade = double.tryParse(_gradeController.text.trim().replaceAll(',', '.'));
    final error = await ref.read(completedCoursesViewModelProvider.notifier).addCompletedCourse(
          semesterIndex: _semester,
          course: course,
          grade: grade,
        );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _submitError = error;
      });
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Đã thêm ${course.code} vào Kỳ $_semester (+${course.credits} TC)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(completedCoursesViewModelProvider).value;
    final vm = ref.read(completedCoursesViewModelProvider.notifier);
    final addable = state?.addableCourses ?? const <CourseModel>[];

    final ruleError = _course == null
        ? null
        : vm.validateAdd(semesterIndex: _semester, course: _course!);
    final bannerMessage = ruleError ?? _submitError;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thêm môn đã học',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chọn kỳ, môn và điểm. Kỳ N chỉ thêm được khi đã có Kỳ 1…N-1 '
              'và môn tiên quyết đã hoàn thành ở kỳ trước.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<int>(
              value: _semester,
              decoration: const InputDecoration(labelText: 'Kỳ học'),
              items: [
                for (var s = CompletedCourseRules.minSemester;
                    s <= CompletedCourseRules.maxSemester;
                    s++)
                  DropdownMenuItem(value: s, child: Text('Kỳ $s')),
              ],
              onChanged: (v) => setState(() {
                _semester = v ?? _semester;
                _submitError = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<CourseModel>(
              value: addable.contains(_course) ? _course : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Môn học'),
              items: [
                for (final c in addable)
                  DropdownMenuItem(
                    value: c,
                    child: Text('${c.code} — ${c.name}', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                _course = v;
                _submitError = null;
              }),
            ),
            if (_course?.prerequisiteCode != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tiên quyết: ${_course!.prerequisiteCode}',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _gradeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Điểm (thang 10)'),
              onChanged: (_) => setState(() => _submitError = null),
            ),
            if (bannerMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppAlertBanner(message: bannerMessage),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Hủy',
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Thêm môn',
                    height: AppSpacing.minTouchTarget,
                    isLoading: _saving,
                    loadingLabel: 'Đang lưu...',
                    onPressed: (_course == null || ruleError != null) ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
