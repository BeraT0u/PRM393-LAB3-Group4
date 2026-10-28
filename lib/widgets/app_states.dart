import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_button.dart';

/// UC-06: Trạng thái Shimmer Loading (Skeleton), Empty State, Error State & Logout Dialog

/// 1. Shimmer Skeleton Loading cho danh sách thẻ môn học (SCR-04_Loading)
class AppSkeletonLoading extends StatelessWidget {
  final int itemCount;

  const AppSkeletonLoading({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải danh sách dữ liệu',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.borderStructural),
            ),
            child: Shimmer.fromColors(
              baseColor: AppColors.borderStructural,
              highlightColor: AppColors.surfaceCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 220,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.borderStructural,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 170,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.borderStructural,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.borderStructural,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 2. Empty State khi tìm kiếm không ra kết quả hoặc kỳ học trống (SCR-04_Empty / SCR-03)
class AppEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const AppEmptyState({
    super.key,
    this.title = 'Không tìm thấy môn học nào',
    this.subtitle = 'Không có môn học nào khớp với từ khóa hoặc bộ lọc hiện tại.',
    this.actionLabel = 'Xóa bộ lọc',
    this.onAction,
    this.icon = Icons.search_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EAD8),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderStructural),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppSecondaryButton(
                  label: actionLabel!,
                  icon: Icons.filter_alt_off_outlined,
                  fullWidth: false,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 3. Error State kèm nút Retry theo đúng Rubric chấm điểm Lab 3
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'Không thể tải dữ liệu',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: '$title. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.dangerSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dangerBorder.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 32,
                  color: AppColors.dangerText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: 160,
                  child: AppPrimaryButton(
                    label: 'Thử lại',
                    leadingIcon: Icons.refresh_rounded,
                    height: 48,
                    onPressed: onRetry,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 4. Modal Dialog Xác nhận Đăng xuất (Overlay_Logout.png)
class LogoutConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirmLogout;

  const LogoutConfirmDialog({
    super.key,
    required this.onConfirmLogout,
  });

  static Future<bool?> show(BuildContext context, {required VoidCallback onConfirm}) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (ctx) => LogoutConfirmDialog(
        onConfirmLogout: () {
          Navigator.of(ctx).pop(true);
          onConfirm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.borderStructural, width: 1.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đăng xuất tài khoản?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Bạn có chắc chắn muốn đăng xuất? Bạn sẽ cần đăng nhập lại bằng tài khoản trường để tiếp tục đồng bộ lịch học.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Hủy',
                      semanticsLabel: 'Hủy đăng xuất',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppDestructiveButton(
                      label: 'Đăng xuất',
                      semanticsLabel: 'Xác nhận đăng xuất',
                      isOutlined: false,
                      onPressed: onConfirmLogout,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
