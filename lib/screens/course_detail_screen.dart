import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/grade_target.dart';
import '../viewmodels/course_detail_viewmodel.dart';
import '../widgets/widgets.dart';

/// UC-16 → UC-19: SCR-05 — Course Strategy, Assessment & Study Tips.
/// - Ẩn hoàn toàn Bottom Navigation Bar, nút Back quay lại SCR-04.
/// - Nhận mã môn qua `Navigator.pushNamed('/course-detail', arguments: 'PRM393')`.
class CourseDetailScreen extends ConsumerWidget {
  final String courseCode;

  const CourseDetailScreen({super.key, required this.courseCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = courseDetailViewModelProvider(courseCode);
    final async = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final state = async.value;

    return MainScaffold(
      showBottomBar: false,
      appBar: AppTopBar(
        title: 'Chiến Lược Môn',
        subtitle: courseCode,
        showBack: true,
        actions: [
          if (state != null)
            IconButton(
              tooltip: state.isFavorite ? 'Bỏ ghim môn' : 'Ghim môn',
              icon: Icon(
                state.isFavorite ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: state.isFavorite ? AppColors.primaryBlue : AppColors.textSecondary,
              ),
              onPressed: vm.toggleFavorite,
            ),
        ],
      ),
      dockedFooter: state == null
          ? null
          : _ActionFooter(
              isFavorite: state.isFavorite,
              onFavorite: vm.toggleFavorite,
              onAddToPlan: () {
                Navigator.of(context).pushNamed(
                  '/plan-analyzer',
                  arguments: state.plannedCourse,
                );
              },
            ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppSkeletonLoading(itemCount: 3),
        ),
        error: (e, _) => AppErrorState(
          title: 'Không tìm thấy môn học',
          message: 'Không thể tải thông tin môn $courseCode. Vui lòng thử lại.',
          onRetry: vm.reload,
        ),
        data: (data) => _DetailBody(state: data, onSelectTarget: vm.selectTarget),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final CourseDetailState state;
  final ValueChanged<GradeTargetOption> onSelectTarget;

  const _DetailBody({required this.state, required this.onSelectTarget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = state.course;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.bottomClearanceDockedBtn,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UC-16: Header môn & 3 badge thông số
          Text(
            '${course.name} (${course.code})',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusBadge(label: '${course.credits} Tín chỉ', type: StatusBadgeType.neutral),
              StatusBadge(
                label: 'Độ khó: ${_difficulty(course.difficulty)}/5 ⭐',
                type: StatusBadgeType.warning,
              ),
              _prerequisiteBadge(),
            ],
          ),

          // UC-17: Cấu trúc điểm
          if (course.assessmentBreakdown.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('📊 Cấu trúc điểm & Đánh giá', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in course.assessmentBreakdown.entries) ...[
                  Expanded(child: _AssessmentBox(label: e.key, percent: e.value)),
                  if (e.key != course.assessmentBreakdown.keys.last)
                    const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ],

          // UC-17: Tips học tập
          if (course.studyTips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('💡 Tips học tập từ Khóa trên', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _TipsCard(tips: course.studyTips),
          ],

          // UC-18: Chọn mục tiêu & khối lượng
          const SizedBox(height: AppSpacing.xl),
          Text('🎯 Chọn Mục tiêu & Khối lượng', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            container: true,
            label: 'Chọn mục tiêu điểm',
            child: Column(
              children: [
                for (final option in GradeTargetOption.all) ...[
                  _GradeTargetCard(
                    option: option,
                    hours: option.hoursFor(course),
                    selected: option.code == state.target.code,
                    onTap: () => onSelectTarget(option),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Giờ tự học dự kiến: ${GradeTargetOption.formatHours(state.plannedHours)}/tuần',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _prerequisiteBadge() {
    final prereq = state.prerequisiteCode;
    if (prereq == null) {
      return const StatusBadge(label: 'Không có tiên quyết', type: StatusBadgeType.neutral);
    }
    return state.prerequisiteMet
        ? StatusBadge(label: 'Tiên quyết: $prereq ✅', type: StatusBadgeType.success)
        : StatusBadge(label: 'Tiên quyết: $prereq ❌ chưa học', type: StatusBadgeType.danger);
  }

  static String _difficulty(double d) =>
      d == d.roundToDouble() ? '${d.toInt()}' : d.toStringAsFixed(1);
}

class _AssessmentBox extends StatelessWidget {
  final String label;
  final int percent;

  const _AssessmentBox({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label $percent phần trăm',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.borderStructural),
        ),
        child: Column(
          children: [
            Text(
              '$percent%',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final List<String> tips;

  const _TipsCard({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.warningText, fontSize: 14)),
                Expanded(
                  child: Text(
                    tips[i],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.warningText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeTargetCard extends StatelessWidget {
  final GradeTargetOption option;
  final double hours;
  final bool selected;
  final VoidCallback onTap;

  const _GradeTargetCard({
    required this.option,
    required this.hours,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoursLabel = GradeTargetOption.formatHours(hours);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: 'Mục tiêu ${option.title} ${option.threshold}, đầu tư $hoursLabel mỗi tuần',
      child: Material(
        color: selected ? AppColors.primaryBlueTonal.withValues(alpha: 0.45) : AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: selected ? AppColors.primaryBlue : AppColors.borderStructural,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mục tiêu: ${option.title} (${option.threshold})',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đầu tư $hoursLabel/tuần • ${option.note}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// UC-19: Docked Action Footer — nút Yêu thích (48dp) + nút chính "Thêm vào Kế hoạch" (52dp).
class _ActionFooter extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onAddToPlan;

  const _ActionFooter({
    required this.isFavorite,
    required this.onFavorite,
    required this.onAddToPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          toggled: isFavorite,
          label: isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
          child: SizedBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.surfaceCard,
                side: BorderSide(
                  color: isFavorite ? AppColors.dangerBorder : AppColors.borderStructural,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
              ),
              onPressed: onFavorite,
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.dangerBorder : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppPrimaryButton(
            label: 'Thêm vào Kế hoạch',
            leadingIcon: Icons.add_task_rounded,
            onPressed: onAddToPlan,
          ),
        ),
      ],
    );
  }
}
