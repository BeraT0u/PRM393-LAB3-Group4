import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';
import '../widgets/widgets.dart';

/// UC-20, UC-21, UC-22: SCR-06A — Workload & Strategy Analyzer (Phân Tích Kế Hoạch)
/// - Ẩn hoàn toàn Bottom Navigation Bar.
/// - Hiển thị banner báo động đỏ quá tải & vi phạm tiên quyết (UC-20).
/// - Thẻ Workload Meter đo lường tổng giờ tự học (34h/tuần vượt ngưỡng 25h) (UC-21).
/// - Danh sách 4 thẻ môn phân bổ: 3 môn hợp lệ và 1 thẻ lỗi đỏ IAE201 (UC-22).
/// - Nút chân trang: "Điều chỉnh kế hoạch (4 môn) ➔" điều hướng sang SCR-06B.
class PlanAnalyzerScreen extends ConsumerStatefulWidget {
  const PlanAnalyzerScreen({super.key});

  @override
  ConsumerState<PlanAnalyzerScreen> createState() => _PlanAnalyzerScreenState();
}

class _PlanAnalyzerScreenState extends ConsumerState<PlanAnalyzerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final incoming = ModalRoute.of(context)?.settings.arguments as CourseModel?;
      if (incoming != null) {
        ref.read(planAnalyzerViewModelProvider.notifier).applyIncomingCourse(incoming);
      }
    });
  }

  void _openSelectedCourses() {
    Navigator.of(context).pushNamed('/selected-courses');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planAnalyzerViewModelProvider);

    return MainScaffold(
      showBottomBar: false,
      appBar: const AppTopBar(
        title: 'Phân Tích Kế Hoạch',
        subtitle: 'Fall 2024 • Workload Analyzer',
        showBack: true,
      ),
      dockedFooter: AppPrimaryButton(
        label: 'Điều chỉnh kế hoạch (${state.courseCount} môn) ➔',
        semanticsLabel: 'Điều chỉnh kế hoạch ${state.courseCount} môn',
        onPressed: _openSelectedCourses,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.bottomClearanceDockedBtn,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UC-20: Banner báo động đỏ quá tải & vi phạm tiên quyết
            if (state.hasConflict)
              AppAlertBanner(
                variant: AlertBannerVariant.danger,
                message: '⚠️ Cảnh báo: Vi phạm tiên quyết & Quá tải!',
                onTap: _openSelectedCourses,
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.dangerText,
                ),
              )
            else
              const AppAlertBanner(
                variant: AlertBannerVariant.success,
                message: 'Kế hoạch học tập cân bằng & hợp lệ (0 Xung đột) ✅',
              ),
            const SizedBox(height: AppSpacing.lg),

            // UC-21: Thẻ Đo lường Khối lượng (Workload Meter)
            _WorkloadMeterCard(state: state),
            const SizedBox(height: AppSpacing.xl),

            // UC-22: Danh sách phân bổ môn học
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Phân bổ thời gian môn học (${state.courseCount})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${state.totalCredits} Tín chỉ',
                  style: Theme.of(context).textTheme.bodySmall?.merge(tabularNumberStyle).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.plan.selectedCourses.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final course = state.plan.selectedCourses[index];
                final isViolated = course.prerequisiteCode != null &&
                    !state.passedCourseCodes.contains(course.prerequisiteCode);

                return CourseStrategyCard(
                  course: course,
                  variant: CourseCardVariant.analyzer,
                  hasConflict: isViolated,
                  conflictMessage: isViolated
                      ? 'Tự học: +${course.plannedSelfStudyHours.toInt()}h/tuần • LỖI: Chưa học tiên quyết ${course.prerequisiteCode}'
                      : null,
                  onTap: _openSelectedCourses,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// UC-21: Thẻ Workload Meter đo lường tổng giờ tự học so với ngưỡng an toàn
class _WorkloadMeterCard extends StatelessWidget {
  final PlanAnalyzerState state;

  const _WorkloadMeterCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHours = state.totalHours;
    final threshold = state.maxSafeThresholdHours;
    final isOverloaded = state.isOverloaded;

    // Tính tỉ lệ thanh đo (tối đa lấy mốc 40h để biểu diễn)
    const double maxScale = 40.0;
    final double safeRatio = (threshold / maxScale).clamp(0.0, 1.0);
    final double totalRatio = (totalHours / maxScale).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isOverloaded ? AppColors.dangerBorder.withValues(alpha: 0.6) : AppColors.borderStructural,
          width: isOverloaded ? 1.5 : 1.0,
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
                'Workload Meter',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              StatusBadge(
                label: isOverloaded ? 'Quá tải ⚠️' : 'Cân bằng ✅',
                type: isOverloaded ? StatusBadgeType.danger : StatusBadgeType.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tổng giờ tự học: ${totalHours.toInt()} giờ / tuần',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isOverloaded ? AppColors.dangerText : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isOverloaded
                ? 'Vượt ngưỡng an toàn (Khuyến nghị: ${threshold.toInt()}h/tuần)'
                : 'Nằm trong ngưỡng tự học an toàn (Tối đa: ${threshold.toInt()}h/tuần)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isOverloaded ? AppColors.dangerText : AppColors.textSecondary,
              fontWeight: isOverloaded ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Thanh tiến trình phân đoạn trực quan (Visual Split Progress Bar)
          Stack(
            children: [
              // Thanh nền tổng thể
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.borderStructural,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Đoạn mức an toàn (Xanh)
              FractionallySizedBox(
                widthFactor: safeRatio,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOverloaded ? AppColors.primaryBlue : AppColors.successBorder,
                    borderRadius: BorderRadius.horizontal(
                      left: const Radius.circular(6),
                      right: totalRatio <= safeRatio ? const Radius.circular(6) : Radius.zero,
                    ),
                  ),
                ),
              ),
              // Đoạn vượt ngưỡng quá tải (Đỏ)
              if (isOverloaded)
                FractionallySizedBox(
                  widthFactor: totalRatio,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.dangerBorder,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Chỉ số ghi chú chân thanh đo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0h',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                'Ngưỡng an toàn: ${threshold.toInt()}h',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isOverloaded ? AppColors.dangerText : AppColors.primaryBlue,
                ),
              ),
              const Text(
                '40h',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
