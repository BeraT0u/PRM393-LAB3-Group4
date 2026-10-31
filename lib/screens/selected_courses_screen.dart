import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';
import '../widgets/widgets.dart';

/// UC-23, UC-24, UC-25: SCR-06B — Selected Courses & SCR-06B_Resolved
/// - Trạng thái lỗi (UC-23): Nút Lưu BỊ KHÓA xám "🔒 Giải quyết 1 xung đột để lưu",
///   môn IAE201 viền đỏ có nút [⇄ Đổi môn khác].
/// - Khắc phục xung đột (UC-24): Đổi sang PRM323, tải giảm về 26h Cân bằng ✅,
///   NÚT LƯU MỞ KHÓA MÀU XANH ACTIVE "Lưu Kế Hoạch Học Tập".
/// - Lưu kế hoạch (UC-25): Ghi vào Cloud Firestore study_plans và chuyển hướng sang SCR-07.
class SelectedCoursesScreen extends ConsumerWidget {
  const SelectedCoursesScreen({super.key});

  void _handleReplaceCourse(BuildContext context, CourseModel conflictCourse) {
    Navigator.of(context).pushNamed(
      '/catalog',
      arguments: {
        'replacingCourseCode': conflictCourse.code,
        'onlyEligible': true,
      },
    );
  }

  Future<void> _handleSavePlan(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(planAnalyzerViewModelProvider.notifier);
    final success = await vm.savePlan();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Đã lưu Kế hoạch học tập Fall 2024 vào Cloud Firestore!'),
          backgroundColor: AppColors.successBorder,
          duration: Duration(seconds: 2),
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
          content: Text(state.errorMessage ?? 'Không thể lưu kế hoạch. Vui lòng thử lại.'),
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
      appBar: const AppTopBar(
        title: 'Môn Đã Chọn',
        subtitle: 'Fall 2024 • Quản lý danh sách môn',
        showBack: true,
      ),
      // Nút chân trang: Khóa khi còn lỗi (UC-23) - Mở khóa xanh khi đã giải quyết (UC-24)
      dockedFooter: hasConflict
          ? const AppPrimaryButton(
              label: '🔒 Giải quyết 1 xung đột để lưu',
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
          // Thẻ Tổng quan (Overview Card)
          _SelectedOverviewCard(state: state),
          const SizedBox(height: AppSpacing.xl),

          // Tiêu đề danh sách
          Text(
            'Danh sách môn học (${state.courseCount})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Danh sách môn đã chọn
          for (final course in state.plan.selectedCourses) ...[
            Builder(
              builder: (ctx) {
                final isViolated = course.prerequisiteCode != null &&
                    !state.passedCourseCodes.contains(course.prerequisiteCode);

                return CourseStrategyCard(
                  course: course,
                  variant: CourseCardVariant.selected,
                  hasConflict: isViolated,
                  conflictMessage: isViolated
                      ? 'Lỗi: Chưa học tiên quyết ${course.prerequisiteCode} • ${course.credits} TC • ${course.plannedSelfStudyHours.toInt()}h/tuần'
                      : null,
                  onReplace: isViolated
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasConflict = state.hasConflict;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hasConflict ? AppColors.dangerSurface : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: hasConflict ? AppColors.dangerBorder : AppColors.borderStructural,
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
                label: hasConflict ? '1 Xung đột ⚠️' : 'Cân bằng ✅',
                type: hasConflict ? StatusBadgeType.danger : StatusBadgeType.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasConflict
                ? 'Tổng khối lượng: ${state.totalHours.toInt()}h/tuần (Quá tải)'
                : 'Tổng khối lượng: ${state.totalHours.toInt()}h tự học/tuần (Cân bằng ✅)',
            style: theme.textTheme.bodyMedium?.merge(tabularNumberStyle).copyWith(
                  color: hasConflict ? AppColors.dangerText : AppColors.successText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (hasConflict) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.dangerBorder.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.dangerText),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '⚠️ 1 môn vi phạm tiên quyết (IAE201 cần NWC203)',
                      style: TextStyle(fontSize: 12, color: AppColors.dangerText, fontWeight: FontWeight.bold),
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
