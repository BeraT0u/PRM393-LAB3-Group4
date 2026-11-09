import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/completed_course_model.dart';
import '../models/course_model.dart';
import '../utils/gpa_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../viewmodels/semester_summary_viewmodel.dart';
import '../widgets/widgets.dart';

/// SCR-07: Màn hình Tổng Kết Kế Hoạch Kỳ & Xuất Blueprint PDF (Nhóm 5)
/// - UC-26: Thẻ Hero KPI (5 Môn, 15 TC, GPA 3.65, 26h tự học, Học phí 14.250.000đ), khôi phục Bottom Bar
/// - UC-26B: Nút "✅ Đã Hoàn Thành Kỳ Học" tự động lưu môn vào Môn Đã Học & cộng dồn tín chỉ
/// - UC-27: Danh sách 5 môn học kèm mục tiêu điểm (A / B+) và tích xanh tiên quyết
/// - UC-28: Tạo tài liệu PDF Blueprint A4 Kế hoạch học tập
/// - UC-29: Upload file PDF lên Firebase Storage reports/{uid}/... & hiển thị progress
/// - UC-30: Hộp thoại xem trước / in ấn PDF và Đồng bộ Google Calendar
class SemesterSummaryScreen extends ConsumerWidget {
  const SemesterSummaryScreen({super.key});

  static final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  Future<void> _handleExportPdf(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(semesterSummaryViewModelProvider.notifier);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final bytes = await vm.generateAndExportPdf();

    if (!context.mounted) return;

    if (bytes != null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('🎉 Đã xuất PDF Blueprint A4 và lưu trữ lên Cloud Storage thành công!'),
          backgroundColor: AppColors.successBorder,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      final state = ref.read(semesterSummaryViewModelProvider);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Không thể xuất file PDF. Vui lòng thử lại.'),
          backgroundColor: AppColors.dangerBorder,
        ),
      );
    }
  }

  Future<void> _confirmCompleteSemester(BuildContext context, WidgetRef ref) async {
    final state = ref.read(semesterSummaryViewModelProvider);
    final vm = ref.read(semesterSummaryViewModelProvider.notifier);


    final results = await showDialog<List<CourseGradeItem>>(
      context: context,
      builder: (dialogCtx) => _CompleteSemesterDialog(state: state),
    );

    if (results != null && context.mounted) {
      final success = await vm.completeSemester(results);
      if (!context.mounted) return;

      if (success) {
        final updatedState = ref.read(semesterSummaryViewModelProvider);
        final passedCount = results.where((r) => r.isPassed && r.grade >= 4.0).length;
        final addedCredits = results
            .where((r) => r.isPassed && r.grade >= 4.0)
            .fold<int>(0, (sum, r) => sum + r.course.credits);

        final snackText = updatedState.plan.isPendingAcceptance
            ? '📨 Đã gửi bảng điểm nghiệm thu ($passedCount/${results.length} môn đạt) lên Web Admin chờ Cố vấn duyệt!'
            : '🎉 Nghiệm thu hoàn tất! Đạt $passedCount/${results.length} môn (+$addedCredits TC).';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackText),
            backgroundColor: AppColors.successBorder,
            duration: const Duration(seconds: 3),
          ),
        );

        // Điều hướng sang SCR-03 Completed Courses để thấy trạng thái chờ duyệt / thành quả (UC-26B)
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/completed-courses',
          ModalRoute.withName('/home'),
        );
      }
    }
  }

  Widget? _buildReviewStatusBanner(SemesterSummaryState state) {
    final plan = state.plan;
    if (plan.isPending) {
      return const AppAlertBanner(
        variant: AlertBannerVariant.warning,
        message:
            '⏳ Kế hoạch học tập đã được gửi và đang chờ Cố vấn học tập phê duyệt trên cổng Web Admin.',
      );
    }
    if (plan.isRejected) {
      return AppAlertBanner(
        variant: AlertBannerVariant.danger,
        message:
            '❌ Cố vấn yêu cầu chỉnh sửa kế hoạch: ${plan.reviewReason ?? "Vui lòng điều chỉnh lại danh sách môn học và gửi duyệt lại."}',
      );
    }
    if (plan.isPendingAcceptance) {
      return const AppAlertBanner(
        variant: AlertBannerVariant.warning,
        message:
            '⏳ Đã gửi bảng điểm nghiệm thu kỳ học! Vui lòng chờ Cố vấn xác nhận trên cổng Web Admin để cộng tín chỉ vào hồ sơ.',
      );
    }
    if (plan.isAcceptanceRejected) {
      return AppAlertBanner(
        variant: AlertBannerVariant.danger,
        message:
            '❌ Cố vấn yêu cầu kiểm tra lại điểm nghiệm thu: ${plan.reviewReason ?? "Vui lòng nhập lại điểm chính xác."}',
      );
    }
    if (plan.isApproved &&
        plan.reviewReason != null &&
        plan.reviewReason!.trim().isNotEmpty) {
      return AppAlertBanner(
        variant: AlertBannerVariant.success,
        message: '✅ Cố vấn đã phê duyệt kế hoạch: "${plan.reviewReason}"',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(semesterSummaryViewModelProvider);
    final theme = Theme.of(context);
    final statusBanner = _buildReviewStatusBanner(state);

    return MainScaffold(
      // UC-26: Khôi phục thanh Bottom Navigation Bar 4 tab
      showBottomBar: true,
      currentTabIndex: -1,
      appBar: AppTopBar(
        title: 'Tổng Kết Kế Hoạch',
        subtitle: 'SCR-07: ${state.plan.semesterName} • Lộ trình tối ưu',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.bottomClearanceWithBar,
        ),
        children: [
          if (statusBanner != null) ...[
            statusBanner,
            const SizedBox(height: AppSpacing.md),
          ],

          // UC-26: Thẻ Hero KPI
          _HeroKpiCard(state: state),
          const SizedBox(height: AppSpacing.xl),

          // UC-27: Danh mục 5 môn học kèm mục tiêu điểm & tích xanh
          _CourseListSection(
            courses: state.plan.selectedCourses,
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.xl),

          // UC-28, UC-29, UC-30: Xuất bản tài liệu PDF Blueprint A4 & Lưu trữ đám mây
          _ExportPdfCard(
            state: state,
            theme: theme,
            onExportPdf: () => _handleExportPdf(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),

          // UC-26B: Nghiệm thu hoàn thành kỳ học
          _CompleteSemesterCard(
            state: state,
            theme: theme,
            onComplete: () => _confirmCompleteSemester(context, ref),
          ),
        ],
      ),
    );
  }
}

/// UC-26: Thẻ Hero KPI Tổng Kết Kế Hoạch
class _HeroKpiCard extends StatelessWidget {
  final SemesterSummaryState state;

  const _HeroKpiCard({required this.state});

  StatusBadge _buildPlanBadge(SemesterSummaryState state) {
    final plan = state.plan;
    if (plan.isPending) {
      return const StatusBadge(
        label: 'Chờ cố vấn duyệt ⏳',
        type: StatusBadgeType.warning,
      );
    }
    if (plan.isRejected) {
      return const StatusBadge(
        label: 'Yêu cầu sửa ❌',
        type: StatusBadgeType.danger,
      );
    }
    if (plan.isPendingAcceptance) {
      return const StatusBadge(
        label: 'Chờ duyệt điểm ⏳',
        type: StatusBadgeType.warning,
      );
    }
    if (plan.isAcceptanceRejected) {
      return const StatusBadge(
        label: 'Sửa điểm nghiệm thu ❌',
        type: StatusBadgeType.danger,
      );
    }
    return const StatusBadge(
      label: 'Lộ trình hợp lệ ✅',
      type: StatusBadgeType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tuitionFormatted = SemesterSummaryScreen._currencyFormat.format(state.tuitionFee);

    return Container(
      width: double.infinity,
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
          // Header Thẻ: Tên kỳ học & Tag trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: AppColors.primaryBlue, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Kỳ học: ${state.plan.semesterName}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildPlanBadge(state),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderStructural),
          const SizedBox(height: AppSpacing.md),

          // Lưới 4 chỉ số KPI (2 hàng x 2 cột)
          Row(
            children: [
              Expanded(
                child: _KpiBox(
                  icon: Icons.auto_stories_rounded,
                  iconColor: AppColors.primaryBlue,
                  label: 'Môn & Tín chỉ',
                  value: '${state.courseCount} Môn • ${state.totalCredits} TC',
                  highlight: false,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _KpiBox(
                  icon: Icons.stars_rounded,
                  iconColor: const Color(0xFFD97706), // Vàng đậm
                  label: 'GPA Mục tiêu',
                  value: '${state.targetGpa.toStringAsFixed(2)} / 4.0',
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _KpiBox(
                  icon: Icons.timer_rounded,
                  iconColor: AppColors.successBorder,
                  label: 'Tự học / tuần',
                  value: '${state.totalHours.toInt()}h • Cân bằng',
                  highlight: false,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _KpiBox(
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.primaryBlue,
                  label: 'Học phí ước tính',
                  value: tuitionFormatted,
                  highlight: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Khối hiển thị 1 thông số KPI nhỏ gọn
class _KpiBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool highlight;

  const _KpiBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primaryBlueTonal.withValues(alpha: 0.3) : AppColors.canvasBg,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color: highlight ? AppColors.primaryBlue.withValues(alpha: 0.3) : AppColors.borderStructural,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.primaryBlue : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// UC-27: Danh mục 5 môn học kèm mục tiêu điểm & tích xanh tiên quyết
class _CourseListSection extends StatelessWidget {
  final List<CourseModel> courses;
  final ThemeData theme;

  const _CourseListSection({
    required this.courses,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Danh sách môn học (${courses.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Đạt điều kiện tiên quyết ✅',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.successBorder,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tất cả các môn đã được đối chiếu hợp lệ với danh mục đã học',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        // Danh sách thẻ môn học
        for (final course in courses) ...[
          _SummaryCourseCard(course: course),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Thẻ môn học rút gọn trên màn hình SCR-07
class _SummaryCourseCard extends StatelessWidget {
  final CourseModel course;

  const _SummaryCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final gradeTarget = course.selectedGradeTarget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderStructural),
      ),
      child: Row(
        children: [
          // Icon tích xanh tiên quyết
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),

          // Thông tin môn
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      course.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.canvasBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderStructural),
                      ),
                      child: Text(
                        '${course.credits} TC',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Giờ tự học & Badge mục tiêu điểm
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueTonal,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Text(
                  'Mục tiêu: $gradeTarget',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${course.plannedSelfStudyHours.toInt()}h / tuần',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// UC-28, UC-29, UC-30: Thẻ Hành Động Xuất Bản PDF & Đồng Bộ
class _ExportPdfCard extends StatelessWidget {
  final SemesterSummaryState state;
  final ThemeData theme;
  final VoidCallback onExportPdf;

  const _ExportPdfCard({
    required this.state,
    required this.theme,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: AppColors.dangerBorder, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tài Liệu Kế Hoạch & In Ấn',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tự động kết xuất bản vẽ Blueprint chuẩn khổ A4 (210×297 mm) gồm bảng KPI, cấu trúc điểm 40/30/30 và lưu trữ bảo mật trên Firebase Cloud Storage.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Hiển thị thanh tiến trình tải lên nếu đang upload (UC-29)
          if (state.isUploadingPdf) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đang upload lên Cloud Storage...',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                    ),
                    Text(
                      '${(state.uploadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: state.uploadProgress > 0 ? state.uploadProgress : null,
                  backgroundColor: AppColors.primaryBlueTonal,
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ],

          // Nút Xuất PDF A4 (UC-28 & UC-30)
          AppPrimaryButton(
            label: '📄 Xuất PDF Kế Hoạch & Chiến Lược (A4)',
            semanticsLabel: 'Nút xuất bản tài liệu PDF Blueprint A4 và in ấn',
            isLoading: state.isGeneratingPdf || state.isUploadingPdf,
            loadingLabel: state.isUploadingPdf ? 'Đang tải lên Cloud...' : 'Đang khởi tạo PDF...',
            onPressed: (state.isGeneratingPdf || state.isUploadingPdf) ? null : onExportPdf,
          ),

          // Thông báo nếu đã có URL lưu trữ trên Cloud Storage
          if (state.pdfDownloadUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvasBg,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.borderStructural),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: AppColors.successBorder, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Bản PDF đã lưu tại reports/{uid}/... trên Cloud Storage',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

/// UC-26B: Thẻ Nghiệm Thu Kỳ Học ("Đã hoàn thành kỳ học")
class _CompleteSemesterCard extends StatelessWidget {
  final SemesterSummaryState state;
  final ThemeData theme;
  final VoidCallback onComplete;

  const _CompleteSemesterCard({
    required this.state,
    required this.theme,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final plan = state.plan;
    final bool canSubmitAcceptance =
        (plan.isApproved || plan.isAcceptanceRejected) &&
            !state.isCompleted &&
            !state.isCompletingSemester &&
            state.courseCount > 0;

    String descriptionText;
    String buttonLabel;
    IconData buttonIcon = Icons.task_alt_rounded;

    if (state.isCompletingSemester) {
      descriptionText = 'Đang gửi bảng điểm nghiệm thu học kỳ lên hệ thống...';
      buttonLabel = 'Đang gửi nghiệm thu...';
    } else if (state.isCompleted || plan.isFullyCompleted) {
      descriptionText =
          'Học kỳ này đã được nghiệm thu! Toàn bộ ${state.courseCount} môn học đã được chuyển vào danh mục Môn Đã Học (SCR-03) và số tín chỉ đã được tích lũy vào hồ sơ.';
      buttonLabel = 'Kỳ học đã hoàn thành';
      buttonIcon = Icons.done_all_rounded;
    } else if (plan.isPendingAcceptance) {
      descriptionText =
          'Bảng điểm của ${state.courseCount} môn học đã được gửi lên cổng Web Admin. Số tín chỉ (${state.totalCredits} TC) và GPA sẽ tự động cập nhật vào hồ sơ ngay khi Cố vấn học tập xác nhận nghiệm thu.';
      buttonLabel = '⏳ Đang Chờ Cố Vấn Duyệt Điểm';
      buttonIcon = Icons.hourglass_top_rounded;
    } else if (plan.isPending || plan.isDraft) {
      descriptionText =
          'Kế hoạch học tập ${plan.semesterName} đang chờ Cố vấn học tập phê duyệt trên cổng Web Admin. Bạn chỉ có thể nộp bảng điểm nghiệm thu sau khi kế hoạch được duyệt.';
      buttonLabel = '🔒 Chờ Cố Vấn Duyệt Kế Hoạch';
      buttonIcon = Icons.lock_clock_rounded;
    } else if (plan.isRejected) {
      descriptionText =
          'Kế hoạch học tập này đã bị Cố vấn yêu cầu chỉnh sửa. Vui lòng quay lại điều chỉnh danh sách môn học và gửi duyệt lại trước khi nghiệm thu.';
      buttonLabel = '❌ Kế Hoạch Cần Chỉnh Sửa';
      buttonIcon = Icons.error_outline_rounded;
    } else {
      descriptionText =
          'Đã hoàn tất học kỳ ${plan.semesterName}? Nhấn nút bên dưới để nhập điểm số và gửi yêu cầu nghiệm thu ${state.courseCount} môn (${state.totalCredits} TC) lên Cố vấn học tập.';
      buttonLabel = '✅ Đã Hoàn Thành Kỳ Học';
      buttonIcon = Icons.task_alt_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: (state.isCompleted || plan.isFullyCompleted)
              ? AppColors.successBorder
              : AppColors.borderStructural,
        ),
        boxShadow: AppElevation.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                (state.isCompleted || plan.isFullyCompleted)
                    ? Icons.check_circle_rounded
                    : Icons.verified_outlined,
                color: (state.isCompleted || plan.isFullyCompleted)
                    ? AppColors.successBorder
                    : AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Nghiệm Thu Học Kỳ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            descriptionText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Nút Nghiệm Thu Kỳ Học
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: canSubmitAcceptance
                    ? const Color(0xFF16A34A)
                    : AppColors.borderStructural,
                foregroundColor:
                    canSubmitAcceptance ? Colors.white : AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                elevation: 0,
              ),
              icon: state.isCompletingSemester
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(buttonIcon),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: canSubmitAcceptance ? onComplete : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hộp thoại Nghiệm thu Học kỳ: Cho phép chọn trạng thái Đạt / Rớt và nhập điểm thang 10 cho từng môn.
class _CompleteSemesterDialog extends StatefulWidget {
  final SemesterSummaryState state;

  const _CompleteSemesterDialog({required this.state});

  @override
  State<_CompleteSemesterDialog> createState() => _CompleteSemesterDialogState();
}

class _CompleteSemesterDialogState extends State<_CompleteSemesterDialog> {
  late final Map<String, CourseGradeItem> _items;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _items = {};
    _controllers = {};
    for (final c in widget.state.plan.selectedCourses) {
      final defaultGrade = c.selectedGradeTarget == 'A'
          ? 8.5
          : (c.selectedGradeTarget == 'B' ? 7.5 : 6.0);
      _items[c.code] = CourseGradeItem(
        course: c,
        isPassed: true,
        grade: defaultGrade,
      );
      _controllers[c.code] = TextEditingController(text: defaultGrade.toStringAsFixed(1));
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _togglePassed(String code, bool passed) {
    setState(() {
      final current = _items[code]!;
      final newGrade = passed
          ? (current.grade < 4.0 ? 7.5 : current.grade)
          : (current.grade >= 4.0 ? 3.0 : current.grade);
      _items[code] = current.copyWith(isPassed: passed, grade: newGrade);
      _controllers[code]?.text = newGrade.toStringAsFixed(1);
    });
  }

  void _onGradeChanged(String code, String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) return;
    final clamped = parsed.clamp(0.0, 10.0);
    setState(() {
      final current = _items[code]!;
      _items[code] = current.copyWith(
        grade: clamped,
        isPassed: clamped >= 4.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsList = _items.values.toList();
    final passedCount = itemsList.where((i) => i.isPassed && i.grade >= 4.0).length;
    final passedCredits = itemsList
        .where((i) => i.isPassed && i.grade >= 4.0)
        .fold<int>(0, (sum, i) => sum + i.course.credits);

    final completedEquiv = itemsList
        .map((i) => CompletedCourseModel(
              code: i.course.code,
              name: i.course.name,
              credits: i.course.credits,
              grade: i.grade,
              gradeLetter: GpaCalculator.grade10ToLetter(i.grade),
              isPassed: i.isPassed && i.grade >= 4.0,
            ))
        .toList();
    final semesterGpa = GpaCalculator.calculateGpa(completedEquiv);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.successBorder, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Nghiệm Thu Kỳ Học',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn đã hoàn thành học kỳ ${widget.state.plan.semesterName}?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Hệ thống sẽ tự động chuyển ${widget.state.courseCount} môn học (${widget.state.totalCredits} TC) '
                'vào danh mục "Môn Đã Học" (SCR-03). Hãy chọn trạng thái hoàn thành và nhập điểm thang 10 cho từng môn:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              for (final item in itemsList) ...[
                _buildCourseItemRow(item, theme),
                const SizedBox(height: AppSpacing.md),
              ],
              const Divider(),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.canvasBg,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Đạt: $passedCount/${itemsList.length} môn (+$passedCredits TC)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'GPA kỳ: ${semesterGpa.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(itemsList),
          child: const Text('Xác nhận hoàn thành'),
        ),
      ],
    );
  }

  Widget _buildCourseItemRow(CourseGradeItem item, ThemeData theme) {
    final c = item.course;
    final isPassed = item.isPassed && item.grade >= 4.0;
    final letter = GpaCalculator.grade10ToLetter(item.grade);
    final gpa4 = GpaCalculator.grade10ToGpa4(item.grade);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isPassed ? Colors.transparent : Colors.red.withValues(alpha: 0.05),
        border: Border.all(
          color: isPassed ? AppColors.borderStructural : AppColors.dangerBorder.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${c.code} — ${c.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(
                label: '${c.credits} TC',
                type: StatusBadgeType.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: const Text('Đạt', style: TextStyle(fontSize: 12)),
                    selected: isPassed,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    selectedColor: AppColors.successBorder.withValues(alpha: 0.2),
                    onSelected: (val) => _togglePassed(c.code, true),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('Rớt', style: TextStyle(fontSize: 12)),
                    selected: !isPassed,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    selectedColor: Colors.red.withValues(alpha: 0.2),
                    onSelected: (val) => _togglePassed(c.code, false),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72,
                    height: 38,
                    child: TextField(
                      controller: _controllers[c.code],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Điểm',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => _onGradeChanged(c.code, val),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusBadge(
                    label: isPassed ? '$letter (${gpa4.toStringAsFixed(1)})' : 'F (0.0)',
                    type: isPassed ? StatusBadgeType.success : StatusBadgeType.danger,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
