import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import '../viewmodels/course_catalog_viewmodel.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';
import '../widgets/widgets.dart';

/// UC-20, UC-21, UC-22: SCR-06A — Workload & Strategy Analyzer (Phân Tích Kế Hoạch)
/// - Ẩn hoàn toàn Bottom Navigation Bar.
/// - Khi KHÔNG báo đỏ (!state.hasConflict): hiển thị nút "+ Thêm môn" ở phía trên góc phải AppBar.
/// - Khi báo đỏ (state.hasConflict): ẩn nút "+ Thêm môn", hiện banner báo động đỏ quá tải / vi phạm tiên quyết.
/// - Hỗ trợ bắt đầu từ 0 môn được chọn và thêm dần từng môn cho tới khi báo đỏ.
class PlanAnalyzerScreen extends ConsumerStatefulWidget {
  const PlanAnalyzerScreen({super.key});

  @override
  ConsumerState<PlanAnalyzerScreen> createState() => _PlanAnalyzerScreenState();
}

class _PlanAnalyzerScreenState extends ConsumerState<PlanAnalyzerScreen> {
  bool _appliedRouteArg = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_appliedRouteArg) {
      _appliedRouteArg = true;
      final incoming = ModalRoute.of(context)?.settings.arguments;
      if (incoming is CourseModel) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(planAnalyzerViewModelProvider.notifier)
              .applyIncomingCourse(incoming);
        });
      }
    }
  }

  void _openSelectedCourses() {
    Navigator.of(context).pushNamed('/selected-courses');
  }

  void _openCatalogToAddCourse() {
    ref
        .read(courseCatalogViewModelProvider.notifier)
        .setOnlyEligible(false, replacingCourseCode: null);
    Navigator.of(context).pushNamed('/catalog');
  }

  String _buildConflictBannerMessage(PlanAnalyzerState state) {
    final hasPrereqViolation = state.prerequisiteViolations.isNotEmpty;
    if (hasPrereqViolation && state.isOverloaded) {
      return '⚠️ Cảnh báo: Vi phạm tiên quyết & Quá tải!';
    }
    if (hasPrereqViolation) {
      return '⚠️ Cảnh báo: Vi phạm điều kiện môn tiên quyết!';
    }
    return '⚠️ Cảnh báo: Quá tải khối lượng tự học (${_formatHoursNumber(state.totalHours)}h/tuần > ${state.maxSafeThresholdHours.toInt()}h)!';
  }

  static String _formatHoursNumber(double hours) {
    return hours == hours.roundToDouble()
        ? '${hours.toInt()}'
        : hours.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planAnalyzerViewModelProvider);
    final vm = ref.read(planAnalyzerViewModelProvider.notifier);

    return MainScaffold(
      showBottomBar: false,
      appBar: AppTopBar(
        title: 'Phân Tích Kế Hoạch',
        subtitle: '${state.plan.semester} • Workload Analyzer',
        showBack: true,
        actions: [
          if (!state.hasConflict)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: TextButton.icon(
                key: const Key('btn_add_course_top_right'),
                onPressed: _openCatalogToAddCourse,
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
            ),
        ],
      ),
      dockedFooter: state.courseCount == 0
          ? AppPrimaryButton(
              label: '+ Chọn môn học đầu tiên',
              semanticsLabel: 'Chọn môn học đầu tiên từ danh mục',
              onPressed: _openCatalogToAddCourse,
            )
          : AppPrimaryButton(
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
            // UC-20: Banner trạng thái kế hoạch (Báo đỏ / Chưa chọn môn / Cân bằng)
            if (state.hasConflict)
              AppAlertBanner(
                variant: AlertBannerVariant.danger,
                message: _buildConflictBannerMessage(state),
                onTap: _openSelectedCourses,
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.dangerText,
                ),
              )
            else if (state.courseCount == 0)
              AppAlertBanner(
                variant: AlertBannerVariant.warning,
                message:
                    'Chưa có môn học nào được chọn. Nhấn "Thêm môn" ở góc trên phải để bắt đầu lập kế hoạch!',
                onTap: _openCatalogToAddCourse,
              )
            else
              const AppAlertBanner(
                variant: AlertBannerVariant.success,
                message: 'Kế hoạch học tập cân bằng & hợp lệ (0 Xung đột) ✅',
              ),
            const SizedBox(height: AppSpacing.lg),

            // UC-21: Thẻ Đo lường Khối lượng (Workload Meter)
            _WorkloadMeterCard(state: state),

            if (state.hasConflict) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEFF6FF),
                      Color(0xFFF5F3FF),
                    ],
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
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Cố vấn AI (Gemini & DeepSeek)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Phân tích rủi ro & tự động đề xuất đổi môn cân bằng giờ học.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => AiAdvisorModalSheet.show(context),
                      child: const Text(
                        'Tư vấn ngay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // UC-22: Danh sách phân bổ môn học
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Phân bổ thời gian môn học (${state.courseCount})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${state.totalCredits} Tín chỉ',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.merge(tabularNumberStyle)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (state.courseCount == 0)
              _EmptyPlanAnalyzerCard(
                onAddCourse: _openCatalogToAddCourse,
                onLoadSampleConflict: vm.loadSampleConflictPlan,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.plan.selectedCourses.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final course = state.plan.selectedCourses[index];
                  final isViolated = !state.isCoursePrerequisiteMet(course);
                  final isOverloadFocus = !isViolated &&
                      state.prerequisiteViolations.isEmpty &&
                      state.isOverloaded &&
                      state.conflictCourse?.code == course.code;

                  final hasCardConflict = isViolated || isOverloadFocus;
                  String? conflictMsg;
                  if (isViolated) {
                    conflictMsg =
                        'Tự học: +${_formatHoursNumber(course.plannedSelfStudyHours)}h/tuần • LỖI: Chưa học tiên quyết ${course.prerequisiteCode}';
                  } else if (isOverloadFocus) {
                    conflictMsg =
                        'Tự học: +${_formatHoursNumber(course.plannedSelfStudyHours)}h/tuần • CẢNH BÁO: Gây vượt ngưỡng ${state.maxSafeThresholdHours.toInt()}h/tuần';
                  }

                  return CourseStrategyCard(
                    course: course,
                    variant: CourseCardVariant.analyzer,
                    hasConflict: hasCardConflict,
                    conflictMessage: conflictMsg,
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

class _EmptyPlanAnalyzerCard extends StatelessWidget {
  final VoidCallback onAddCourse;
  final VoidCallback onLoadSampleConflict;

  const _EmptyPlanAnalyzerCard({
    required this.onAddCourse,
    required this.onLoadSampleConflict,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderStructural),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlueTonal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.playlist_add_check_circle_outlined,
              color: AppColors.primaryBlue,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chưa có môn học nào được chọn',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bạn có thể bắt đầu từ 0 môn và thêm từng môn từ danh mục. Hệ thống sẽ tự động lưu nháp ở local và báo đỏ ngay khi vượt ngưỡng 25h/tuần hoặc thiếu môn tiên quyết.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onAddCourse,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm môn từ danh mục'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              minimumSize: const Size(double.infinity, 46),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onLoadSampleConflict,
            icon: const Icon(Icons.science_outlined, size: 16),
            label: const Text('Nạp nhanh tổ hợp 4 môn xung đột mẫu (34h)'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// UC-21: Thẻ Workload Meter đo lường tổng giờ tự học so với ngưỡng an toàn
class _WorkloadMeterCard extends StatelessWidget {
  final PlanAnalyzerState state;

  const _WorkloadMeterCard({required this.state});

  static String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? '${hours.toInt()}'
        : hours.toStringAsFixed(1);
  }

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

    return Semantics(
      container: true,
      label: 'Workload Meter: tổng ${totalHours.toInt()} giờ tự học mỗi tuần, '
          '${isOverloaded ? 'vượt' : 'trong'} ngưỡng an toàn ${threshold.toInt()} giờ',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isOverloaded
                ? AppColors.dangerBorder.withValues(alpha: 0.6)
                : AppColors.borderStructural,
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
                  type: isOverloaded
                      ? StatusBadgeType.danger
                      : StatusBadgeType.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tổng giờ tự học: ${_formatHours(totalHours)} giờ / tuần',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    isOverloaded ? AppColors.dangerText : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isOverloaded
                  ? 'Vượt ngưỡng an toàn (Khuyến nghị: ${threshold.toInt()}h/tuần)'
                  : 'Nằm trong ngưỡng tự học an toàn (Tối đa: ${threshold.toInt()}h/tuần)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isOverloaded
                    ? AppColors.dangerText
                    : AppColors.textSecondary,
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
                  widthFactor: isOverloaded ? safeRatio : totalRatio,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOverloaded
                          ? AppColors.primaryBlue
                          : AppColors.successBorder,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(6),
                        right: totalRatio <= safeRatio
                            ? const Radius.circular(6)
                            : Radius.zero,
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
                    color: isOverloaded
                        ? AppColors.dangerText
                        : AppColors.primaryBlue,
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
      ),
    );
  }
}
