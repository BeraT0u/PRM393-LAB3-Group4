import 'package:flutter/material.dart';

/// Design tokens for EduPlan Warm Paper Academic Theme
/// Reference: Resource/flutter-handoff.md & Resource/Figma/DESIGN.md
class AppColors {
  // Nền canvas giấy kem ấm & bề mặt thẻ ngà
  static const Color canvasBg          = Color(0xFFFBF6EB); // Nền Scaffold toàn app
  static const Color surfaceCard        = Color(0xFFFFFDF7); // Bề mặt Card, Sheet, App Bar
  static const Color surfaceLowest      = Color(0xFFFFFFFF); // Nền trắng input text
  static const Color borderStructural   = Color(0xFFEAE1D0); // Viền 1px nét liền quanh Card

  // Màu thương hiệu & Hành động chính (Royal Blue)
  static const Color primaryBlue        = Color(0xFF2563EB); // Nút CTA chính, Tab active
  static const Color primaryBluePressed = Color(0xFF1D4ED8); // Trạng thái nhấn nút
  static const Color primaryBlueTonal   = Color(0xFFDBE1FF); // Nền nút "Chiến lược >", tag nổi bật
  static const Color onPrimaryWhite     = Color(0xFFFFFFFF);

  // Màu văn bản (Độ tương phản cao trên nền kem)
  static const Color textPrimary        = Color(0xFF1C1917); // Deep Espresso Ink (Tiêu đề, tên môn)
  static const Color textSecondary      = Color(0xFF78716C); // Warm Slate Muted (Giờ tự học, chú thích)
  static const Color textDisabled       = Color(0xFF94A3B8); // Chữ khi nút bị khóa

  // Trạng thái: Cảnh báo quá tải & Vi phạm tiên quyết
  static const Color dangerSurface      = Color(0xFFFEE2E2); // Nền banner báo động đỏ, thẻ lỗi
  static const Color dangerBorder       = Color(0xFFDC2626); // Viền đỏ báo động, icon ⚠️
  static const Color dangerText         = Color(0xFFB91C1C); // Chữ đỏ thông báo vi phạm

  // Trạng thái: Tips học tập, Nhắc nhở & Tag chờ
  static const Color warningSurface     = Color(0xFFFEF3C7); // Nền thẻ Study Tips, tag lưu ý
  static const Color warningBorder      = Color(0xFFFDE68A); // Viền thẻ Study Tips
  static const Color warningText        = Color(0xFF78350F); // Chữ nâu đậm (WCAG AAA >= 7:1)

  // Trạng thái: Hợp lệ & Hoàn thành môn
  static const Color successSurface     = Color(0xFFDCFCE7); // Nền badge Điểm A/B, tiến độ hợp lệ
  static const Color successBorder      = Color(0xFF16A34A);
  static const Color successText        = Color(0xFF15803D); // Chữ trạng thái hoàn thành môn
}
