import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

enum AlertBannerVariant {
  danger,  // Nền đỏ #FEE2E2, viền #DC2626, chữ #B91C1C
  warning, // Nền vàng #FEF3C7, viền #FDE68A, chữ #78350F
  success, // Nền xanh lá #DCFCE7, viền #16A34A, chữ #15803D
}

/// UC-05: Banner báo động đỏ quá tải & vi phạm tiên quyết (AppAlertBanner)
/// Đạt chuẩn WCAG 1.4.1 (Truyền đạt trạng thái bằng cả màu sắc, viền, icon và chữ đậm).
class AppAlertBanner extends StatelessWidget {
  final String message;
  final AlertBannerVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppAlertBanner({
    super.key,
    required this.message,
    this.variant = AlertBannerVariant.danger,
    this.icon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData defaultIcon;

    switch (variant) {
      case AlertBannerVariant.danger:
        bgColor = AppColors.dangerSurface;
        borderColor = AppColors.dangerBorder;
        textColor = AppColors.dangerText;
        defaultIcon = Icons.warning_amber_rounded;
      case AlertBannerVariant.warning:
        bgColor = AppColors.warningSurface;
        borderColor = AppColors.warningBorder;
        textColor = AppColors.warningText;
        defaultIcon = Icons.info_outline_rounded;
      case AlertBannerVariant.success:
        bgColor = AppColors.successSurface;
        borderColor = AppColors.successBorder;
        textColor = AppColors.successText;
        defaultIcon = Icons.check_circle_outline_rounded;
    }

    return Semantics(
      liveRegion: true,
      label: message,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(icon ?? defaultIcon, color: textColor, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
