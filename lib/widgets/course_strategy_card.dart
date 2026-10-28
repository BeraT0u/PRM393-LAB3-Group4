import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'status_badge.dart';

enum CourseCardVariant {
  catalog,   // SCR-04: Tìm môn & nút "Chiến lược >"
  analyzer,  // SCR-06A: Phân tích kế hoạch & cảnh báo đỏ
  selected,  // SCR-06B: Môn đã chọn & nút "⇄ Đổi môn khác" / xóa
  completed, // SCR-03: Môn đã hoàn thành & mở khóa tiên quyết
  summary,   // SCR-07: Thẻ tổng kết kỳ học gọn gàng
}

/// UC-02: Thẻ môn học chiến lược (CourseStrategyCard) & State vi phạm viền đỏ
class CourseStrategyCard extends StatelessWidget {
  final CourseModel course;
  final CourseCardVariant variant;
  final bool hasConflict;
  final String? conflictMessage;
  final String? completedScoreLabel;
  final String? unlockNote;
  final VoidCallback? onTap;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  const CourseStrategyCard({
    super.key,
    required this.course,
    this.variant = CourseCardVariant.catalog,
    this.hasConflict = false,
    this.conflictMessage,
    this.completedScoreLabel,
    this.unlockNote,
    this.onTap,
    this.onReplace,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool isErrorCard = hasConflict &&
        (variant == CourseCardVariant.analyzer || variant == CourseCardVariant.selected);

    final Color bgColor = isErrorCard ? AppColors.dangerSurface : AppColors.surfaceCard;
    final Color borderColor = isErrorCard ? AppColors.dangerBorder : AppColors.borderStructural;
    final double borderWidth = isErrorCard ? 1.5 : 1.0;

    return Semantics(
      container: true,
      label: '${course.name} (${course.code})',
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _buildVariantContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantContent(BuildContext context) {
    switch (variant) {
      case CourseCardVariant.catalog:
        return _buildCatalogContent(context);
      case CourseCardVariant.analyzer:
        return _buildAnalyzerContent(context);
      case CourseCardVariant.selected:
        return _buildSelectedContent(context);
      case CourseCardVariant.completed:
        return _buildCompletedContent(context);
      case CourseCardVariant.summary:
        return _buildSummaryContent(context);
    }
  }

  /// SCR-04: Danh mục môn học
  Widget _buildCatalogContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${course.name} (${course.code})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${course.credits} TC • Độ khó: ${course.difficulty.toInt()}/5 ⭐ • Tự học: ${course.defaultSelfStudyHours}h/tuần',
          style: theme.textTheme.bodyMedium?.merge(tabularNumberStyle).copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTonalButton(
          label: 'Chiến lược >',
          semanticsLabel: 'Xem chiến lược môn ${course.code}',
          onPressed: onTap,
        ),
      ],
    );
  }

  /// SCR-06A: Phân tích kế hoạch (Bình thường vs Xung đột đỏ)
  Widget _buildAnalyzerContent(BuildContext context) {
    final theme = Theme.of(context);

    if (hasConflict) {
      final msg = conflictMessage ??
          'Tự học: +${course.plannedSelfStudyHours.toInt()}h/tuần • LỖI: Chưa học tiên quyết ${course.prerequisiteCode ?? "NWC203"}';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.dangerText, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${course.code} (${course.name})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dangerText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            msg,
            style: theme.textTheme.bodyMedium?.merge(tabularNumberStyle).copyWith(
                  color: AppColors.dangerText,
                ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${course.code} • Mục tiêu ${course.selectedGradeTarget}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tự học: ${course.plannedSelfStudyHours.toInt()}h/tuần',
          style: theme.textTheme.bodyMedium?.merge(tabularNumberStyle).copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  /// SCR-06B: Môn đã chọn (Có nút [⇄ Đổi môn khác] và nút xóa thùng rác 🗑️)
  Widget _buildSelectedContent(BuildContext context) {
    final theme = Theme.of(context);

    if (hasConflict) {
      final msg = conflictMessage ??
          'Lỗi: Chưa học tiên quyết ${course.prerequisiteCode ?? "NWC203"} • ${course.credits} TC • ${course.plannedSelfStudyHours.toInt()}h/tuần';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.warning_rounded, color: AppColors.dangerText, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${course.name} (${course.code})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dangerText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg,
                      style: theme.textTheme.bodyMedium?.merge(tabularNumberStyle).copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppDestructiveButton(
                label: '⇄ Đổi môn khác',
                semanticsLabel: 'Đổi môn khác thay cho ${course.code}',
                isOutlined: true,
                fullWidth: false,
                onPressed: onReplace,
              ),
              if (onRemove != null)
                Semantics(
                  button: true,
                  label: 'Xóa môn ${course.code}',
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerBorder),
                    onPressed: onRemove,
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${course.name} (${course.code})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mục tiêu: ${course.selectedGradeTarget} • Tự học: ${course.plannedSelfStudyHours.toInt()}h/tuần',
                style: theme.textTheme.bodyMedium?.merge(tabularNumberStyle).copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        if (onRemove != null)
          Semantics(
            button: true,
            label: 'Xóa môn ${course.code}',
            child: Container(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              decoration: BoxDecoration(
                color: AppColors.dangerSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerBorder),
                onPressed: onRemove,
              ),
            ),
          ),
      ],
    );
  }

  /// SCR-03: Môn đã hoàn thành
  Widget _buildCompletedContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${course.name} (${course.code})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(
              label: completedScoreLabel ?? '8.8 (A) ✅',
              type: StatusBadgeType.success,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${course.credits} Tín chỉ • ${course.category}',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        if (unlockNote != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            unlockNote!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.successText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// SCR-07: Tổng kết kế hoạch kỳ
  Widget _buildSummaryContent(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.successBorder, size: 22),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${course.name} (${course.code})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${course.credits} TC • Tự học: ${course.plannedSelfStudyHours.toInt()}h/tuần',
                style: theme.textTheme.bodyMedium?.merge(tabularNumberStyle).copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        StatusBadge(
          label: 'Mục tiêu ${course.selectedGradeTarget}',
          type: StatusBadgeType.success,
        ),
      ],
    );
  }
}
