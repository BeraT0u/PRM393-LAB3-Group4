import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;  // Padding chuẩn 2 cạnh màn hình 390dp
  static const double xl  = 24.0;
  static const double xxl = 32.0;

  static const double bottomClearanceWithBar   = 96.0;  // Tránh bị Bottom Bar 64dp đè
  static const double bottomClearanceDockedBtn = 110.0; // Tránh bị Sticky Button đè
  static const double minTouchTarget          = 48.0;  // Chuẩn tiếp cận WCAG
}

class AppRadius {
  static const double control = 8.0;   // Nút bấm, TextField, tag nhỏ
  static const double card    = 16.0;  // Thẻ môn học, Modal Bottom Sheet, Dialog
  static const double pill    = 999.0; // Status chip, badge, avatar
}

class AppElevation {
  // Hệ thống hoàn toàn không dùng drop shadow mờ ảo; phân tách bằng viền 1px solid
  static const Border sideBorder = Border.fromBorderSide(
    BorderSide(color: AppColors.borderStructural, width: 1.0),
  );

  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF78716C).withValues(alpha: 0.08),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: const Color(0xFF78716C).withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];
}
