import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import '../utils/grade_target.dart';
import '../viewmodels/course_catalog_viewmodel.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';
import '../widgets/widgets.dart';

/// UC-23, UC-24, UC-25: SCR-06B — Selected Courses & SCR-06B_Resolved
/// - Trạng thái lỗi (UC-23): Nút Lưu BỊ KHÓA xám "🔒 Giải quyết N xung đột để lưu",
///   môn xung đột viền đỏ có nút [⇄ Đổi môn khác].
/// - Khắc phục xung đột (UC-24): Đổi môn hoặc hạ mục tiêu điểm để tải <= 25h Cân bằng ✅,
///   NÚT LƯU MỞ KHÓA MÀU XANH ACTIVE "Lưu Kế Hoạch Học Tập".
/// - Lưu kế hoạch (UC-25): Ghi vào Cloud Firestore study_plans và chuyển hướng sang SCR-07.
class SelectedCoursesScreen extends ConsumerWidget {
  const SelectedCoursesScreen({super.key});

  static String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? '${hours.toInt()}h'
        : '${hours.toStringAsFixed(1)}h';
  }

  void _handleReplaceCourse(BuildContext context, CourseModel conflictCourse) {
    Navigator.of(context).pushNamed(
      '/catalog',
      arguments: {
        'replacingCourseCode': conflictCourse.code,
        'onlyEligible': true,
      },
    );
  }

  void _openCatalogToAdd(BuildContext context, WidgetRef ref) {
    ref
        .read(courseCatalogViewModelProvider.notifier)
        .setOnlyEligible(false, replacingCourseCode: null);
    Navigator.of(context).pushNamed('/catalog');
  }

  void _showChangeTargetSheet(
    BuildContext context,
    WidgetRef ref,
    CourseModel course,
  ) {
    final vm = ref.read(planAnalyzerViewModelProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đổi mục tiêu điểm: ${course.name} (${course.code})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Điều chỉnh mục tiêu điểm giúp cân bằng quỹ thời gian tự học mỗi tuần.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final option in GradeTargetOption.all) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Icon(
                      course.selectedGradeTarget == option.code
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: course.selectedGradeTarget == option.code
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      'Mục tiêu: ${option.title} (${option.threshold})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Tự học: ${GradeTargetOption.formatHours(option.hoursFor(course))}/tuần • ${option.note}',
                    ),
                    onTap: () {
                      vm.updateCourseTarget(course.code, option);
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSavePlan(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(planAnalyzerViewModelProvider.notifier);
    final success = await vm.savePlan();

    if (!context.mounted) return;

    if (success) {
      final state = ref.read(planAnalyzerViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Đã lưu Kế hoạch học tập ${state.plan.semester} (${state.courseCount} môn) vào Cloud Firestore!',
          ),
          backgroundColor: AppColors.successBorder,
          duration: const Duration(seconds: 2),
        ),
      );

      // Chuyển hướng sang SCR-07 Tổng kết kế hoạch kỳ (UC-25)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/summary',
        ModalRoute.withName('/home'),
      );
    } else {
      final state = ref.read(planAnalyzerViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.errorMessage ?? 'Không thể lưu kế hoạch. Vui lòng thử lại.',
          ),
          backgroundColor: AppColors.dangerBorder,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planAnalyzerViewModelProvider);
    final vm = ref.read(planAnalyzerViewModelProvider.notifier);
    final bool hasConflict = state.hasConflict;

    return MainScaffold(
      showBottomBar: false,
      appBar: AppTopBar(
        title: 'Môn Đã Chọn',
        subtitle: '${state.plan.semester} • Quản lý danh sách môn',
        showBack: true,
        actions: [
          if (!hasConflict)
            TextButton.icon(
              onPressed: () => _openCatalogToAdd(context, ref),
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              label: const Text(
                'Thêm môn',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          if (state.courseCount > 0)
            IconButton(
              tooltip: 'Xóa toàn bộ môn đã chọn',
              onPressed: vm.clearPlan,
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      // Nút chân trang: Khóa khi còn lỗi (UC-23) - Mở khóa xanh khi đã giải quyết (UC-24)
      dockedFooter: state.courseCount == 0
          ? AppPrimaryButton(
              label: '+ Chọn môn học từ danh mục',
              semanticsLabel: 'Chọn môn học từ danh mục',
              onPressed: () => _openCatalogToAdd(context, ref),
            )
          : hasConflict
              ? AppPrimaryButton(
                  label: '🔒 Giải quyết ${state.conflictCount} xung đột để lưu',
                  semanticsLabel: 'Nút lưu bị khóa do có xung đột',
                  onPressed: null,
                )
              : AppPrimaryButton(
                  label: 'Lưu Kế Hoạch Học Tập',
                  semanticsLabel: 'Lưu Kế Hoạch Học Tập hợp lệ vào Firestore',
                  isLoading: state.isSaving,
                  onPressed: () => _handleSavePlan(context, ref),
                ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.bottomClearanceDockedBtn,
        ),
        children: [
          if ((state.plan.isRejected || state.plan.isAcceptanceRejected) &&
              state.plan.reviewReason != null &&
              state.plan.reviewReason!.trim().isNotEmpty) ...[
            AppAlertBanner(
              variant: AlertBannerVariant.danger,
              message:
                  '❌ Yêu cầu chỉnh sửa từ Cố vấn: ${state.plan.reviewReason}',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Thẻ Tổng quan (Overview Card)
          _SelectedOverviewCard(state: state),

          if (hasConflict) ...[
            const SizedBox(height: AppSpacing.md),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => AiAdvisorModalSheet.show(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '✨ Nhờ Cố vấn AI gợi ý hoán đổi môn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gemini & DeepSeek tự động tìm môn thay thế để hạ tải an toàn.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF4F46E5),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          // Tiêu đề danh sách
          Text(
            'Danh sách môn học (${state.courseCount})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          if (state.courseCount > 0) ...[
            const SizedBox(height: 2),
            const Text(
              'Chạm vào thẻ môn để đổi mục tiêu điểm (A / B / Qua môn)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          if (state.courseCount == 0)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.borderStructural),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: AppColors.textDisabled,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Chưa có môn học nào trong danh sách.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nhấn "+ Chọn môn học từ danh mục" bên dưới để thêm môn vào kế hoạch kỳ này.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            // Danh sách môn đã chọn
            for (final course in state.plan.selectedCourses) ...[
              Builder(
                builder: (ctx) {
                  final isViolated = !state.isCoursePrerequisiteMet(course);
                  final isOverloadFocus = !isViolated &&
                      state.prerequisiteViolations.isEmpty &&
                      state.isOverloaded &&
                      state.conflictCourse?.code == course.code;

                  final showCardConflict = isViolated || isOverloadFocus;
                  String? conflictMsg;
                  if (isViolated) {
                    conflictMsg =
                        'Lỗi: Chưa học tiên quyết ${course.prerequisiteCode} • ${course.credits} TC • ${_formatHours(course.plannedSelfStudyHours)}/tuần';
                  } else if (isOverloadFocus) {
                    conflictMsg =
                        'Quá tải: Môn chiếm ${_formatHours(course.plannedSelfStudyHours)}/tuần (vượt ngưỡng ${state.maxSafeThresholdHours.toInt()}h) • Đổi môn hoặc hạ mục tiêu điểm';
                  }

                  return CourseStrategyCard(
                    course: course,
                    variant: CourseCardVariant.selected,
                    hasConflict: showCardConflict,
                    conflictMessage: conflictMsg,
                    onTap: () => _showChangeTargetSheet(context, ref, course),
                    onReplace: showCardConflict
                        ? () => _handleReplaceCourse(context, course)
                        : null,
                    onRemove: () => vm.removeCourse(course),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

/// Thẻ tổng quan số môn, tín chỉ, khối lượng tự học
class _SelectedOverviewCard extends StatelessWidget {
  final PlanAnalyzerState state;

  const _SelectedOverviewCard({required this.state});

  static String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? '${hours.toInt()}h'
        : '${hours.toStringAsFixed(1)}h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasConflict = state.hasConflict;

    String conflictDetailText = '';
    if (state.prerequisiteViolations.isNotEmpty) {
      conflictDetailText =
          '⚠️ ${state.prerequisiteViolations.length} môn vi phạm tiên quyết (${state.prerequisiteViolations.join(", ")})';
    } else if (state.isOverloaded) {
      conflictDetailText =
          '⚠️ Tổng giờ tự học vượt ngưỡng an toàn ${state.maxSafeThresholdHours.toInt()}h/tuần';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hasConflict ? AppColors.dangerSurface : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color:
              hasConflict ? AppColors.dangerBorder : AppColors.borderStructural,
          width: hasConflict ? 1.5 : 1.0,
        ),
        boxShadow: AppElevation.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.courseCount} Môn • ${state.totalCredits} Tín chỉ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              StatusBadge(
                label: hasConflict
                    ? '${state.conflictCount} Xung đột ⚠️'
                    : 'Cân bằng ✅',
                type: hasConflict
                    ? StatusBadgeType.danger
                    : StatusBadgeType.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasConflict
                ? (state.isOverloaded
                    ? 'Tổng khối lượng: ${_formatHours(state.totalHours)}/tuần (Quá tải)'
                    : 'Tổng khối lượng: ${_formatHours(state.totalHours)}/tuần (Lỗi tiên quyết)')
                : 'Tổng khối lượng: ${_formatHours(state.totalHours)} tự học/tuần (Cân bằng ✅)',
            style: theme.textTheme.bodyMedium
                ?.merge(tabularNumberStyle)
                .copyWith(
                  color:
                      hasConflict ? AppColors.dangerText : AppColors.successText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (hasConflict && conflictDetailText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.dangerBorder.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.dangerText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      conflictDetailText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.dangerText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
