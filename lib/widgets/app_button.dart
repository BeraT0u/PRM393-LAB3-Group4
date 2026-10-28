import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// UC-01: Bộ nút bấm chuẩn Design System (Primary, Tonal, Destructive, Secondary)
/// Đảm bảo vùng chạm tối thiểu >= 48dp và tích hợp Semantics cho ARTEMIS E2E testing.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double height;
  final String? semanticsLabel;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 52.0,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null && !isLoading;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: semanticsLabel ?? label,
      child: SizedBox(
        width: double.infinity,
        height: height < AppSpacing.minTouchTarget ? AppSpacing.minTouchTarget : height,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isDisabled ? AppColors.borderStructural : AppColors.primaryBlue,
            disabledBackgroundColor: AppColors.borderStructural,
            foregroundColor: isDisabled ? AppColors.textSecondary : AppColors.onPrimaryWhite,
            disabledForegroundColor: AppColors.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            elevation: 0,
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        loadingLabel ?? 'Đang xử lý...',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDisabled ? AppColors.textSecondary : AppColors.onPrimaryWhite,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(trailingIcon, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Nút Tonal (Nền xanh nhạt #DBE1FF, chữ xanh đậm #1D4ED8 - dùng cho nút "Chiến lược >")
class AppTonalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticsLabel;

  const AppTonalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryBlueTonal,
            foregroundColor: AppColors.primaryBluePressed,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.primaryBluePressed),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBluePressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút Nguy hiểm / Cảnh báo đỏ (Dùng cho "Đăng xuất", "⇄ Đổi môn khác", "Xóa")
class AppDestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final IconData? icon;
  final bool fullWidth;
  final String? semanticsLabel;

  const AppDestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isOutlined = true,
    this.icon,
    this.fullWidth = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: isOutlined ? AppColors.dangerBorder : AppColors.onPrimaryWhite,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isOutlined ? AppColors.dangerBorder : AppColors.onPrimaryWhite,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: AppSpacing.minTouchTarget,
        child: isOutlined
            ? OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceCard,
                  foregroundColor: AppColors.dangerBorder,
                  minimumSize: const Size(0, AppSpacing.minTouchTarget),
                  side: const BorderSide(color: AppColors.dangerBorder, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
                onPressed: onPressed,
                child: buttonChild,
              )
            : FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dangerBorder,
                  foregroundColor: AppColors.onPrimaryWhite,
                  minimumSize: const Size(0, AppSpacing.minTouchTarget),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  elevation: 0,
                ),
                onPressed: onPressed,
                child: buttonChild,
              ),
      ),
    );
  }
}

/// Nút Phụ (Secondary Outlined Button - dùng cho nút "Hủy", "Xóa bộ lọc", "Chia sẻ")
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final String? semanticsLabel;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: AppSpacing.minTouchTarget,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surfaceCard,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(0, AppSpacing.minTouchTarget),
            side: const BorderSide(color: AppColors.borderStructural, width: 1.0),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
