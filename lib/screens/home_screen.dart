import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_seeder.dart';
import '../services/service_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../viewmodels/completed_courses_viewmodel.dart';
import '../viewmodels/course_catalog_viewmodel.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';
import '../widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _shortGreetingName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]} ${parts.last}';
    }
    return fullName.trim().isEmpty ? 'Sinh viên' : fullName.trim();
  }

  static String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? '${hours.toInt()}h'
        : '${hours.toStringAsFixed(1)}h';
  }

  static bool _isStudyTipsEnabled() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseRemoteConfig.instance.getBool('enable_study_tips');
      }
    } catch (_) {
      // Fallback mặc định bật khi offline/test
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentStudentUidProvider);
    final completedAsync = ref.watch(completedCoursesViewModelProvider);

    final profile = completedAsync.value?.profile ??
        ref.read(studentServiceProvider).getCachedProfile(uid) ??
        DatabaseSeeder.getStudentByUid(uid);
    final planState = ref.watch(planAnalyzerViewModelProvider);

    final focusCourse = planState.plan.selectedCourses.isNotEmpty
        ? planState.plan.selectedCourses.first
        : null;

    final activeSemester = (completedAsync.value != null &&
            (uid != DatabaseSeeder.defaultStudent.uid ||
                completedAsync.value!.completed.isNotEmpty))
        ? completedAsync.value!.currentSemesterName
        : planState.plan.semester;
    final semesterHeader = activeSemester.toLowerCase().startsWith('học kỳ') ||
            activeSemester.toLowerCase().startsWith('kỳ')
        ? '📅 Kế hoạch $activeSemester'
        : '📅 Kế hoạch kỳ $activeSemester';
    final targetGpaLabel = profile.targetGpa > 0
        ? profile.targetGpa.toStringAsFixed(2)
        : 'Chưa có thông tin';

    final enableStudyTips = _isStudyTipsEnabled();

    return MainScaffold(
      currentTabIndex: 0,
      appBar: AppBar(
        backgroundColor: AppColors.canvasBg,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 64.0,
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primaryBlue,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'EduPlan',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Phân tích kế hoạch kỳ',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/plan-analyzer'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () async {
          final completedVm =
              ref.read(completedCoursesViewModelProvider.notifier);
          final catalogVm = ref.read(courseCatalogViewModelProvider.notifier);
          await completedVm.reload();
          await catalogVm.reload();

        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.bottomClearanceWithBar,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UC-10: Lời chào sinh viên động theo tài khoản đang đăng nhập
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.control),
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed('/profile'),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryBlueTonal,
                      backgroundImage: profile.avatarUrl != null &&
                              profile.avatarUrl!.startsWith('http')
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: !(profile.avatarUrl != null &&
                              profile.avatarUrl!.startsWith('http'))
                          ? Text(
                              profile.avatarInitials,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào ${_shortGreetingName(profile.fullName)} 👋',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            'Tích lũy: ${profile.accumulatedCredits}/${profile.totalGraduationCredits} TC • GPA mục tiêu: $targetGpaLabel',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (profile.isNewStudent) ...[
                AppAlertBanner(
                  variant: AlertBannerVariant.warning,
                  message:
                      '👋 Tài khoản mới (0 TC): Hãy cập nhật hồ sơ cá nhân hoặc thêm các môn đã học ở mục "Đã học" để mở khóa tiên quyết!',
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/profile'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Thẻ Kế hoạch học tập kỳ hiện tại (Local Draft / Cloud Saved)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: planState.hasConflict
                      ? AppColors.dangerSurface
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: planState.hasConflict
                        ? AppColors.dangerBorder
                        : AppColors.borderStructural,
                    width: planState.hasConflict ? 1.5 : 1.0,
                  ),
                  boxShadow: AppElevation.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            semesterHeader,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        StatusBadge(
                          label: planState.courseCount == 0
                              ? '0 Môn (Bắt đầu)'
                              : (planState.hasConflict
                                  ? '${planState.conflictCount} Xung đột ⚠️'
                                  : (planState.plan.isSaved
                                      ? 'Đã lưu Cloud ✅'
                                      : 'Bản nháp Local ✅')),
                          type: planState.courseCount == 0
                              ? StatusBadgeType.neutral
                              : (planState.hasConflict
                                  ? StatusBadgeType.danger
                                  : StatusBadgeType.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      planState.courseCount == 0
                          ? 'Chưa chọn môn học nào cho kỳ này'
                          : 'Đã chọn ${planState.courseCount} môn • ${planState.totalCredits} TC • Tự học ${_formatHours(planState.totalHours)}/tuần',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: planState.hasConflict
                            ? AppColors.dangerText
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planState.courseCount == 0
                          ? 'Bắt đầu thêm từng môn từ danh mục Tìm Môn để phân tích khối lượng tự học.'
                          : 'Các môn đang chọn: ${planState.plan.selectedCourses.map((c) => c.code).join(", ")}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.onPrimaryWhite,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/plan-analyzer'),
                          icon: const Icon(Icons.analytics_outlined, size: 18),
                          label: Text(
                            planState.courseCount == 0
                                ? 'Mở Phân tích Kế hoạch'
                                : 'Phân tích (${planState.courseCount} môn)',
                          ),
                        ),
                        if (!planState.hasConflict)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              side: const BorderSide(
                                color: AppColors.primaryBlue,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/catalog'),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Thêm môn'),
                          ),
                        if (planState.courseCount > 0 && !planState.hasConflict)
                          TextButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/summary'),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 18,
                            ),
                            label: const Text('Tổng kết & PDF'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // UC-11: Hero Card Trọng tâm học tập (Từ các môn thực tế trong kế hoạch hoặc báo chưa có thông tin)
              if (focusCourse != null)
                Semantics(
                  button: true,
                  label:
                      'Trọng tâm học tập môn ${focusCourse.name}, chạm để xem chi tiết chiến lược môn',
                  child: Material(
                    color: AppColors.surfaceCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      side: const BorderSide(color: AppColors.borderStructural),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () => Navigator.of(context).pushNamed(
                        '/course-detail',
                        arguments: focusCourse.code,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '🔥 Trọng tâm học tập',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successSurface,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    'Mục tiêu: Điểm ${focusCourse.selectedGradeTarget}',
                                    style: const TextStyle(
                                      color: AppColors.successText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${focusCourse.name} (${focusCourse.code})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              focusCourse.studyTips.isNotEmpty
                                  ? focusCourse.studyTips.first
                                  : 'Chưa có thông tin mô tả chiến lược cho môn học này.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Tự học dự kiến: ${_formatHours(focusCourse.plannedSelfStudyHours)}/tuần',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.borderStructural),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔥 Trọng tâm học tập',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Chưa có thông tin môn học trọng tâm',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn chưa chọn môn học nào trong kế hoạch kỳ này. Hãy thêm môn từ danh mục Tìm Môn để hiển thị trọng tâm học tập.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

              // UC-12: Section Tips học tập (kết hợp Remote Config toggle enable_study_tips)
              if (enableStudyTips) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '💡 Tips học tập kỳ này',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (planState.plan.selectedCourses.isNotEmpty)
                  for (final c in planState.plan.selectedCourses.take(3)) ...[
                    _buildTipCard(
                      context,
                      subject: c.code,
                      tip: c.studyTips.isNotEmpty
                          ? c.studyTips.first
                          : 'Duy trì đều đặn ${_formatHours(c.plannedSelfStudyHours)} tự học mỗi tuần để đạt mục tiêu ${c.selectedGradeTarget}.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ]
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.borderStructural),
                    ),
                    child: Text(
                      'Chưa có thông tin gợi ý học tập. Khi bạn thêm các môn học vào kế hoạch, hệ thống sẽ trích xuất gợi ý chiến lược tương ứng từ cơ sở dữ liệu.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context, {
    required String subject,
    required String tip,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.warningText,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            tip,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.warningText),
          ),
        ],
      ),
    );
  }
}
