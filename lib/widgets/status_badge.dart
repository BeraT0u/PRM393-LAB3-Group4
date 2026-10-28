import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

enum StatusBadgeType {
  success,
  warning,
  danger,
  primaryTonal,
  neutral,
}

/// UC-04: Bộ Badge trạng thái (StatusBadge / Tag Pill) chuẩn tương phản WCAG AAA
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final bool showBorder;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (type) {
      case StatusBadgeType.success:
        bgColor = AppColors.successSurface;
        textColor = AppColors.successText;
        borderColor = AppColors.successBorder.withValues(alpha: 0.35);
      case StatusBadgeType.warning:
        bgColor = AppColors.warningSurface;
        textColor = AppColors.warningText; // Tương phản WCAG AAA >= 7:1
        borderColor = AppColors.warningBorder;
      case StatusBadgeType.danger:
        bgColor = AppColors.dangerSurface;
        textColor = AppColors.dangerText;
        borderColor = AppColors.dangerBorder.withValues(alpha: 0.4);
      case StatusBadgeType.primaryTonal:
        bgColor = AppColors.primaryBlueTonal;
        textColor = AppColors.primaryBluePressed;
        borderColor = AppColors.primaryBlue.withValues(alpha: 0.25);
      case StatusBadgeType.neutral:
        bgColor = const Color(0xFFF2EAD8);
        textColor = AppColors.textPrimary;
        borderColor = AppColors.borderStructural;
    }

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: showBorder ? Border.all(color: borderColor, width: 1.0) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
