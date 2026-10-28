# Handoff — EduPlan Mobile (Flutter) — Course Planner & Study Strategy Edition

Tài liệu đặc tả kỹ thuật giao diện dành cho lập trình viên Flutter, chuyển giao trực tiếp từ thiết kế Figma hoàn thiện (chuẩn màn hình 390 × 800 dp, phong cách Warm Paper Academic).

| Thông số | Giá trị chuẩn |
| --- | --- |
| **Màn hình chuẩn** | **390 × 800 dp** (Android Mobile — Đã thống nhất & duyệt đồng bộ) |
| **Design System** | Material Design 3 (Custom Warm Paper Academic System) |
| **Theme Mode** | Warm Paper / Parchment (Nền kem ngà dịu mắt, chống mỏi mắt ban đêm) |
| **Typography** | Inter (Hỗ trợ 100% tiếng Việt, Tabular Figures cho số giờ & điểm số) |
| **Quy chuẩn màn hình** | 9 màn hình chính + 3 biến thể State + 1 Modal Dialog Overlay + 1 Resolved Screen |

---

## Mục lục

- [Phần 1 — Bảng ánh xạ Design Tokens sang Flutter](#phần-1--bảng-ánh-xạ-design-tokens-sang-flutter)
  - [1.1. Bảng màu (ColorScheme)](#11-bảng-màu-colorscheme)
  - [1.2. Kiểu chữ (TextTheme - Font Inter)](#12-kiểu-chữ-texttheme---font-inter)
  - [1.3. Spacing, Border Radius & Elevation](#13-spacing-border-radius--elevation)
  - [1.4. Bảng ánh xạ Component sang Flutter Widget](#14-bảng-ánh-xạ-component-sang-flutter-widget)
- [Phần 2 — Kiến trúc điều hướng & 3 User Flows](#phần-2--kiến-trúc-điều-hướng--3-user-flows)
- [Phần 3 — Đặc tả chi tiết 9 màn hình (Đủ 6 mục bắt buộc)](#phần-3--đặc-tả-chi-tiết-9-màn-hình-đủ-6-mục-bắt-buộc)
  - [3.1. SCR-01 — Login Screen & SCR-01_Loading](#31-scr-01--login-screen--scr-01_loading)
  - [3.2. SCR-02 — Home Planner Dashboard](#32-scr-02--home-planner-dashboard)
  - [3.3. SCR-03 — Completed Courses (Môn Đã Hoàn Thành)](#33-scr-03--completed-courses-môn-đã-hoàn-thành)
  - [3.4. SCR-04 — Course Catalog & Khám phá Chiến lược](#34-scr-04--course-catalog--khám-phá-chiến-lược)
  - [3.5. SCR-05 — Course Strategy, Assessment & Study Tips](#35-scr-05--course-strategy-assessment--study-tips)
  - [3.6. SCR-06A — Workload & Strategy Analyzer (Phân Tích Kế Hoạch)](#36-scr-06a--workload--strategy-analyzer-phân-tích-kế-hoạch)
  - [3.7. SCR-06B — Selected Courses & SCR-06B_Resolved](#37-scr-06b--selected-courses--scr-06b_resolved)
  - [3.8. SCR-07 — Semester Summary & Export PDF Blueprint](#38-scr-07--semester-summary--export-pdf-blueprint)
  - [3.9. SCR-08 — Profile & Settings & Overlay_Logout](#39-scr-08--profile--settings--overlay_logout)
- [Phần 4 — Responsive (Width ≥ 600 dp) & QA Checklist](#phần-4--responsive-width--600-dp--qa-checklist)

---

## Phần 1 — Bảng ánh xạ Design Tokens sang Flutter

### 1.1. Bảng màu (ColorScheme)

```dart
// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Nền canvas giấy kem ấm & thẻ ngà ấm
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
Ánh xạ vào ThemeData.colorScheme:
colorScheme token	Ánh xạ hằng số Flutter	Vai trò trong hệ thống
colorScheme.surface	AppColors.canvasBg	Nền Scaffold toàn app
colorScheme.surfaceContainer	AppColors.surfaceCard	Nền thẻ môn học, dialog, bottom bar
colorScheme.surfaceContainerLowest	AppColors.surfaceLowest	Nền ô nhập liệu search bar
colorScheme.outlineVariant	AppColors.borderStructural	Viền hairline 1px solid của mọi thẻ
colorScheme.primary	AppColors.primaryBlue	Màu nút chính, tab active, link chuyển tiếp
colorScheme.onPrimary	AppColors.onPrimaryWhite	Chữ trắng trên nền nút xanh
colorScheme.onSurface	AppColors.textPrimary	Tiêu đề, tên môn (tương phản >12:1)
colorScheme.onSurfaceVariant	AppColors.textSecondary	Giờ tự học, trọng số điểm, chú thích
colorScheme.error	AppColors.dangerBorder	Viền đỏ lỗi, viền thẻ vi phạm tiên quyết
colorScheme.errorContainer	AppColors.dangerSurface	Nền thẻ môn bị lỗi quá tải/tiên quyết
1.2. Kiểu chữ (TextTheme - Font Inter)
code
Dart
// lib/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

final TextTheme appTextTheme = TextTheme(
  headlineLarge: TextStyle(
    fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, height: 1.3,
    letterSpacing: -0.015, color: AppColors.textPrimary,
  ),
  headlineMedium: TextStyle(
    fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, height: 1.3,
    letterSpacing: -0.01, color: AppColors.textPrimary,
  ),
  titleMedium: TextStyle(
    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, height: 1.4,
    color: AppColors.textPrimary,
  ),
  bodyLarge: TextStyle(
    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.normal, height: 1.5,
    color: AppColors.textPrimary,
  ),
  bodyMedium: TextStyle(
    fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.normal, height: 1.4,
    color: AppColors.textPrimary, // Chuẩn WCAG >= 14sp
  ),
  bodySmall: TextStyle(
    fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.normal, height: 1.3,
    color: AppColors.textSecondary,
  ),
  labelLarge: TextStyle(
    fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
    color: AppColors.onPrimaryWhite,
  ),
  labelMedium: TextStyle(
    fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, height: 1.3,
    color: AppColors.textSecondary,
  ),
);

// Tabular numbers cho giờ tự học, điểm GPA và số tín chỉ
const TextStyle tabularNumberStyle = TextStyle(
  fontFamily: 'Inter',
  fontFeatures: [FontFeature.tabularFigures()],
);
1.3. Spacing, Border Radius & Elevation
code
Dart
// lib/theme/app_dimens.dart
class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;  // Padding chuẩn 2 cạnh màn hình 390dp
  static const double xl  = 24.0;
  
  static const double bottomClearanceWithBar   = 96.0;  // Tránh bị Bottom Bar 64dp đè
  static const double bottomClearanceDockedBtn = 110.0; // Tránh bị Sticky Button đè
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
}
1.4. Bảng ánh xạ Component sang Flutter Widget
Tên Component (Design)	Widget Flutter chuẩn	Variants / States hỗ trợ
Primary Button	FilledButton	Default, Pressed, Disabled (nền xám #EAE1D0), Loading (Spinner)
Tonal Button	FilledButton.tonal	Nền #DBE1FF, chữ #1D4ED8 (dùng cho nút "Chiến lược >")
Destructive Button	OutlinedButton / FilledButton	Viền/nền đỏ #DC2626 (dùng cho Đăng xuất hoặc Xóa môn)
Search Field	TextFormField / SearchBar	Default, Focused (viền xanh), Filled
Course Strategy Card	Container bọc InkWell	Default, Pressed, Conflict (viền đỏ 1.5px #DC2626)
Navigation Bar	NavigationBar (M3)	4 Tabs: [Trang chủ, Đã học, Tìm môn, Cá nhân]
Top App Bar	AppBar	Back Button 48dp, Title SemiBold 18px, Notification Action
Modal Dialog	AlertDialog / showGeneralDialog	Confirm (Đăng xuất) và Alert (Cảnh báo quá tải)
Loading State	Shimmer / Skeleton containers	Màn hình Skeleton xám nhạt #EAE1D0 khi fetch dữ liệu
Empty State	Custom EmptyStateWidget	Kính lúp rỗng + Tiêu đề + Phụ đề + OutlinedButton "Xóa bộ lọc"
Error / Alert Banner	Container / MaterialBanner	Nền đỏ #FEE2E2, viền #DC2626, icon ⚠️, chữ #B91C1C
Phần 2 — Kiến trúc điều hướng & 3 User Flows
Bảng phân cấp màn hình & Trạng thái Bottom Navigation Bar (64dp)
Mã màn hình	Tên màn hình	Phân cấp	Hiển thị Bottom Bar	Điểm đến điều hướng
SCR-01	Login Screen	Root	❌ Ẩn	Chuyển sang SCR-01_Loading ➔ SCR-02
SCR-02	Home Planner Dashboard	Cấp 1	✅ Tab Trang chủ	Mở SCR-03, SCR-04, SCR-05, SCR-08
SCR-03	Completed Courses (Đã học)	Cấp 1	✅ Tab Đã học	Xem lịch sử môn, mở khóa tiên quyết
SCR-04	Course Catalog	Cấp 1	✅ Tab Tìm môn	Xem danh mục môn & độ khó ➔ Mở SCR-05
SCR-05	Course Strategy & Tips	Cấp 2	❌ Ẩn	Chọn mục tiêu điểm ➔ Mở SCR-06A
SCR-06A	Plan Strategy Analyzer	Cấp 2	❌ Ẩn	Phân tích quá tải & tiên quyết ➔ Mở SCR-06B
SCR-06B	Selected Courses (Bị lỗi)	Cấp 2	❌ Ẩn	Nút Lưu bị khóa ➔ Bấm "Đổi môn" ➔ Mở SCR-05
SCR-06B_Resolved	Selected Courses (Hết lỗi)	Cấp 2	❌ Ẩn	Nút Lưu MỞ KHÓA xanh ➔ Mở SCR-07
SCR-07	Semester Summary & PDF	Cấp 2	✅ Khôi phục	Mở Modal tải file PDF A4
SCR-08	Profile & Settings	Cấp 1	✅ Tab Cá nhân	Mở SCR-07 qua thẻ kỳ học; mở Overlay_Logout
Overlay_Logout	Modal Xác nhận Đăng xuất	Overlay	N/A	Bấm Hủy (đóng overlay), Bấm Đăng xuất ➔ SCR-01
code
Text
[ SCR-01 Login ]
                                      │ (Bấm "Đăng nhập Google")
                                      ▼
                           [ SCR-01_Login_Loading ]
                                      │ (After delay 800ms)
                                      ▼
                        [ SCR-02 Home Planner Dashboard ]
         ┌────────────────────────────┼────────────────────────────┐
         ▼                            ▼                            ▼
  [ SCR-03 Môn Đã Học ]        [ SCR-04 Tìm Môn ]           [ SCR-08 Cá Nhân ]
  (Tiến độ 90/145 TC)          (Độ khó & Tự học)                   │
                                      │ (Bấm "Chiến lược >")       ├─▶ [Thẻ Fall 2024] ──┐
                                      ▼                            ▼                     │
                               [ SCR-05 Chi Tiết ]          [ Overlay_Logout ]           │
                               (Tỷ trọng điểm & Tips)              │ (Xác nhận)          │
                                      │ (Thêm vào kế hoạch)        ▼                     │
                                      ▼                     [ Về SCR-01 ]                │
                               [ SCR-06A Phân Tích ]                                     │
                               (Báo động quá tải 34h ⚠️)                                 │
                                      │ (Bấm "Điều chỉnh")                               │
                                      ▼                                                  │
                               [ SCR-06B Môn Đã Chọn ]                                   │
                               (Nút Lưu KHÓA xám 🔒)                                     │
                                      │ (Bấm "[⇄ Đổi môn khác]")                         │
                                      ▼                                                  │
                               [ SCR-05 Chọn môn PRM323 ]                                │
                                      │ (Chốt môn thay thế)                              │
                                      ▼                                                  │
                            [ SCR-06B_Resolved ]                                         │
                            (Nút Lưu MỞ KHÓA xanh 🟢)                                    │
                                      │ (Bấm "Lưu Kế Hoạch Học Tập")                     │
                                      ▼                                                  ▼
                               [ SCR-07 Tổng Kết Chiến Lược & Xuất PDF A4 ] ◀────────────┘
Phần 3 — Đặc tả chi tiết 9 màn hình (Đủ 6 mục bắt buộc)
3.1. SCR-01 — Login Screen & SCR-01_Loading
Layout: Scaffold(backgroundColor: AppColors.canvasBg) → SafeArea → Padding(16) → Column(mainAxisAlignment: MainAxisAlignment.spaceBetween). Không cuộn.
Components:
Logo EduPlan Master (sổ tay gáy xanh, 64×64 dp).
Khối tiêu đề: "EduPlan" (28sp bold) + Slogan "Lập kế hoạch & Chiến lược học tập thông minh".
Nút GoogleSignInButton: Chiều cao 52 dp, nền #FFFFFF, viền #EAE1D0, bo góc 8dp, logo Google SVG.
States:
Default: Sẵn sàng tương tác.
SCR-01_Loading: Khi bấm, nút hiển thị spinner CircularProgressIndicator(strokeWidth: 2.5) kèm text "Đang xác thực Google...".
User Interactions: Chạm nút Đăng nhập ➔ Kích hoạt Auth SDK.
Navigation: Xác thực thành công ➔ Gọi Navigator.pushReplacementNamed(context, '/home') sang SCR-02.
Important UI Constraints: Vùng chạm nút tối thiểu 52dp; layout cố định vừa vặn màn hình 390dp không có thanh cuộn.
3.2. SCR-02 — Home Planner Dashboard
Layout: Scaffold → AppBar cố định → RefreshIndicator → SingleChildScrollView(padding: EdgeInsets.fromLTRB(16, 12, 16, 96)) → Column(spacing: 16).
Components:
Top App Bar: Logo EduPlan bên trái, Notification Bell bên phải.
Header Lời chào: Avatar Long (40dp) + "Chào Hoàng Long 👋" + Subtitle "Tích lũy: 90/145 TC • GPA mục tiêu: 3.60".
Hero Card "🔥 Trọng tâm Tuần 8": Nền #FFFDF7, viền #EAE1D0, tiêu đề "Lập trình Di động (PRM393)", mô tả "Hoàn thiện Lab 2 UI/UX trước Thứ Sáu", thanh tiến độ tự học 6/8h, tag "Mục tiêu: Điểm A".
Section "💡 Tips học tập kỳ này": 2 thẻ gợi ý ngắn gọn cho môn SWE302 (C4 Model) và DBI202 (Stored Procedure).
Bottom Navigation Bar (64dp, Tab 1 Trang chủ Active).
States:
Populated: Đầy đủ trọng tâm tuần và tips học tập.
Offline Mode: Hiện banner cam nhạt: "Dữ liệu ngoại tuyến • Đã lưu lúc 09:15".
User Interactions: Vuốt xuống để refresh (Pull-to-refresh); chạm Hero Card ➔ Mở SCR-05; chạm tab Bottom Bar ➔ Chuyển màn hình.
Navigation: Tab 2 ➔ SCR-03; Tab 3 ➔ SCR-04; Tab 4 ➔ SCR-08.
Important UI Constraints: Các thẻ Tips khống chế text trong tối đa 2 dòng; khoảng cách các khối 16px tạo độ thoáng.
3.3. SCR-03 — Completed Courses (Môn Đã Hoàn Thành)
Layout: Scaffold → AppBar("Môn Đã Học") → Header cố định (Tiến độ tốt nghiệp + Filter Chips) → Expanded → ListView.separated(padding: EdgeInsets.only(bottom: 96)).
Components:
Top App Bar: Icon Logo + Tiêu đề "Môn Đã Học" (Inter SemiBold 18px) + Icon chuông.
Card Tiến độ Tốt nghiệp: "90 / 145 Tín chỉ (62%) • GPA: 3.42", thanh progress bar xanh #2563EB trên nền xám #EAE1D0.
Filter Chips: [Tất cả], [Kỳ 4], [Kỳ 3].
Thẻ môn đã hoàn thành: Tên môn, số TC, điểm tổng kết (8.8 (A) ✅), và dòng chú thích: "Điều kiện: Đã mở khóa tiên quyết cho PRM393.".
Bottom Navigation Bar (Tab 2 Đã học Active).
States:
Default: Danh sách các môn đã Pass.
Empty: Khi chọn một kỳ chưa có dữ liệu ➔ Hiện Empty State.
User Interactions: Chạm các chip để lọc danh sách theo kỳ học; chạm thẻ môn để xem bảng điểm chi tiết.
Navigation: Chạm Bottom Bar để chuyển tab; nút Back trên thiết bị đưa về SCR-02.
Important UI Constraints: Dòng chữ "Điều kiện: ..." gióng thẳng hàng với tiêu đề môn, không thụt lề; badge điểm dùng màu xanh lá dịu mắt (#DCFCE7 / #15803D).
3.4. SCR-04 — Course Catalog & Khám phá Chiến lược
Layout: Scaffold → AppBar("Tìm Môn") → Khối SearchBar & Filter Chips cố định → Expanded → ListView.separated(padding: EdgeInsets.only(bottom: 96)).
Components:
SearchBar: Cao 48 dp, bo góc 8 dp, placeholder "Tìm mã môn hoặc tên môn...".
Filter Chips: [Tất cả], [Chuyên ngành SE], [Cơ sở].
Thẻ môn học: Hiển thị tên môn, số TC, metadata "Độ khó: 4/5 ⭐ • Tự học: 8h/tuần", nút Tonal Button bên phải "Chiến lược >" (Cao 40dp, touch target 48dp).
Bottom Navigation Bar (Tab 3 Tìm môn Active).
States:
Populated: Danh sách các môn học mở trong học kỳ.
SCR-04_Loading: Danh sách Skeleton Shimmer xám #EAE1D0 khi đang tải.
SCR-04_Empty: Khi tìm không ra kết quả (VD: gõ "XYZ99") ➔ Hiện icon kính lúp buồn + text "Không tìm thấy môn học nào" + OutlinedButton "Xóa bộ lọc".
User Interactions: Gõ tìm kiếm; chạm chip lọc; chạm nút "Chiến lược >" hoặc chạm cả thân thẻ môn.
Navigation: Chạm vào môn PRM393 ➔ Navigator.pushNamed('/course-detail') sang SCR-05.
Important UI Constraints: Chiều cao ô tìm kiếm đúng 48dp; danh sách cuộn mượt mà có padding đáy 96dp tránh bị che bởi Bottom Bar.
3.5. SCR-05 — Course Strategy, Assessment & Study Tips
Layout: Scaffold → AppBar (Back [←], Logo, Ghim) → SingleChildScrollView(padding: EdgeInsets.only(bottom: 110)) → DockedActionFooter(cố định đáy).
Quy tắc điều hướng: ẨN HOÀN TOÀN Bottom Navigation Bar.
Components:
Header môn: "Lập trình Di động (PRM393)", 3 badge ngang: "3 Tín chỉ", "Độ khó: 4/5 ⭐", "Tiên quyết: PRO192 ✅".
Section 1 — "📊 Cấu trúc điểm & Đánh giá": 3 hộp thông số ngang: Đồ án: 40%, Thực hành (Lab): 30%, Thi cuối kỳ (FE): 30%.
Section 2 — "💡 Tips học tập từ Khóa trên": Thẻ vàng nhạt #FEF3C7 viền #FDE68A, 2 gạch đầu dòng bí kíp làm đồ án và học Riverpod.
Section 3 — "🎯 Chọn Mục tiêu & Khối lượng": Danh sách 3 Radio Card:
Radio 1 (Đang chọn): "Mục tiêu: Điểm A (8.5+) — Đầu tư 8h/tuần • Hoàn thành sớm Đồ án".
Radio 2: "Mục tiêu: Điểm B (7.0+) — Đầu tư 5h/tuần".
Radio 3: "Mục tiêu: Qua môn (5.5+) — Đầu tư 3.5h/tuần".
Docked Footer: Nút Yêu thích (48dp) + Nút chính "Thêm vào Kế hoạch" (Cao 52dp, nền #2563EB, bo góc 8dp).
States: Radio chuyển đổi linh hoạt giữa 3 mức mục tiêu điểm; nút chân trang đổi sang trạng thái Pressed khi chạm.
User Interactions: Bấm chọn radio mục tiêu điểm; bấm nút "Thêm vào Kế hoạch".
Navigation: Bấm nút chính ➔ Navigator.pushNamed('/plan-analyzer') sang SCR-06A. Nút Back [←] ➔ Quay lại SCR-04.
Important UI Constraints: Padding đáy 110dp đảm bảo nội dung cuộn lên hết, không bị nút chân trang đè.
3.6. SCR-06A — Workload & Strategy Analyzer (Phân Tích Kế Hoạch)
Layout: Scaffold → AppBar("Phân Tích Kế Hoạch", Back [←]) → SingleChildScrollView(padding: EdgeInsets.only(bottom: 110)) → DockedBottomButton(cố định đáy).
Quy tắc điều hướng: ẨN HOÀN TOÀN Bottom Navigation Bar.
Components & Báo động lỗi:
Banner Báo động đỏ (Top): Nền #FEE2E2, viền #DC2626, icon ⚠️, text: "⚠️ Cảnh báo: Vi phạm tiên quyết & Quá tải!".
Thẻ Đo lường Khối lượng (Workload Meter): "Tổng giờ tự học: 34 giờ / tuần", phụ đề "Vượt ngưỡng an toàn (Khuyến nghị: 25h/tuần)", thanh progress bar có đoạn đỏ quá tải.
Danh sách phân bổ môn (4 thẻ):
3 thẻ môn bình thường: PRM393 (8h/tuần), SWE302 (7h/tuần), AIE411 (7h/tuần).
1 thẻ XUNG ĐỘT ĐỎ (IAE201): Nền #FEE2E2, viền đỏ 1.5px #DC2626, tiêu đề "⚠️ IAE201 (An toàn TT)", phụ đề "Tự học: +12h/tuần • LỖI: Chưa học tiên quyết NWC203".
Sticky Footer Button: Nút lớn "Điều chỉnh kế hoạch (4 môn) ➔" (Cao 52dp, nền #2563EB).
States: Thể hiện trực quan trạng thái hệ thống phát hiện lỗi (Error Detection State).
User Interactions: Chạm vào thẻ lỗi hoặc chạm nút chân trang ➔ Mở SCR-06B.
Navigation: Nút chân trang dẫn sang SCR-06B; Nút Back [←] quay lại SCR-05.
Important UI Constraints: Ô báo động đỏ sử dụng cả màu sắc, viền, icon ⚠️ và chữ đậm để truyền đạt lỗi theo chuẩn WCAG 1.4.1.
3.7. SCR-06B — Selected Courses & SCR-06B_Resolved
Layout: Scaffold → AppBar("Môn Đã Chọn", Back [←]) → ListView(padding: EdgeInsets.only(bottom: 110)) → DockedBottomButton.
Quy tắc điều hướng: ẨN HOÀN TOÀN Bottom Navigation Bar.
Components & 2 Trạng thái phục hồi lỗi (Error Recovery):
Trạng thái 1: SCR-06B_Selected_Courses (Khi còn lỗi):
Thẻ Tổng quan: "4 Môn • 12 Tín chỉ • Tổng khối lượng: 34h/tuần" + Hộp cảnh báo "⚠️ 1 môn vi phạm tiên quyết".
Thẻ môn IAE201 viền đỏ: Có nút [⇄ Đổi môn khác] (OutlinedButton đỏ cao 40dp, touch target 48dp) bên cạnh icon thùng rác 🗑️.
Nút chân trang: BỊ KHÓA (Disabled), nền xám #EAE1D0, text #78716C, nhãn: "🔒 Giải quyết 1 xung đột để lưu". Người dùng bấm vào không có tác dụng.
Trạng thái 2: SCR-06B_Resolved (Sau khi đã đổi môn PRM323):
Thẻ Tổng quan: Cập nhật "Tổng khối lượng: 26h tự học/tuần (Cân bằng ✅)".
Môn thứ 4 đổi thành Thiết kế UI/UX (PRM323) với viền xám bình thường, xóa bỏ chữ lỗi.
Nút chân trang: MỞ KHÓA MÀU XANH (Active), nền #2563EB, nhãn: "Lưu Kế Hoạch Học Tập".
User Interactions:
Bấm [⇄ Đổi môn khác] ➔ Mở lại SCR-05 chọn môn thay thế hợp lệ.
Tại màn hình Resolved ➔ Bấm nút màu xanh "Lưu Kế Hoạch Học Tập".
Navigation: Bấm nút Lưu Kế Hoạch ➔ Navigator.pushNamedAndRemoveUntil('/summary', ModalRoute.withName('/home')) sang SCR-07.
Important UI Constraints: Nút "Đổi môn khác" không bị đè layer; nút Lưu chân trang phản hồi trạng thái rõ ràng giữa Disabled và Active.
3.8. SCR-07 — Semester Summary & Export PDF Blueprint
Layout: Scaffold → AppBar("Tổng Kết Kế Hoạch Kỳ") → SingleChildScrollView(padding: EdgeInsets.fromLTRB(16, 12, 16, 96)) → NavigationBar (Khôi phục Bottom Bar, tab Tìm môn Active).
Components:
Top App Bar: Nút Back [←] bên trái, Tiêu đề "Tổng Kết Kế Hoạch Kỳ" (Inter SemiBold 18px).
Thẻ Hero KPI: "5 Môn học • 15 Tín chỉ", 4 nhãn chia thành 2 hàng ngang:
Hàng 1: [✅ Lộ trình hợp lệ (0 Xung đột)] | [⏱️ Tự học: 26h/tuần (Cân bằng)]
Hàng 2: [🎯 GPA Mục tiêu: 3.65] | [Học phí: 14.250.000 đ]
Danh sách "Chiến lược từng môn (5)": 5 thẻ môn nhỏ gọn (PRM393, SWE302, AIE411, PRM323, OSG209) hiển thị mục tiêu điểm (A / B+) và giờ tự học kèm dấu tích xanh ✅.
Hộp hành động xuất file:
Nút chính: "📄 Xuất PDF Kế Hoạch & Chiến Lược (A4)" (FilledButton cao 48dp, nền #2563EB, bo góc 8dp).
2 nút phụ: "Đồng bộ Lịch Ôn Tập" và "Chia sẻ Kế Hoạch".
Bottom Navigation Bar (Tab 3 Tìm môn Active).
States: Hiển thị trọn vẹn bản kế hoạch hợp lệ không có lỗi; nút xuất file sẵn sàng bấm.
User Interactions: Bấm nút "📄 Xuất PDF Kế Hoạch" ➔ Mở modal xem trước bản in khổ A4 (tỷ lệ 1 : 1.414).
Navigation: Màn hình này cũng được mở trực tiếp khi bấm vào thẻ học kỳ ở SCR-08. Nút Back [←] quay lại màn hình trước.
Important UI Constraints: Toàn bộ thẻ và nút xuất PDF nằm hoàn toàn phía trên thanh Bottom Bar 64dp, không bị che khuất.
3.9. SCR-08 — Profile & Settings & Overlay_Logout
Layout: Scaffold → AppBar("Cá Nhân") → SingleChildScrollView(padding: EdgeInsets.fromLTRB(16, 12, 16, 96)) → NavigationBar (Tab Cá nhân Active).
Components:
Thẻ Sinh viên: Avatar tròn 40dp, tên Trần Hoàng Long, MSSV SE180504, 2 pill chỉ số: 📘 Đã tích lũy: 90 / 145 TC và ⭐ GPA: 3.42 (Giỏi).
Thẻ Học kỳ Fall 2024: Có nút Chi tiết > màu xanh #2563EB (touch target 48dp).
Nhóm cài đặt Course Planner (3 switch):
Switch 1: "Nhắc hạn nộp Lab & Milestone đồ án" (Bật).
Switch 2: "Tự động cảnh báo quá tải & tiên quyết" (Bật).
Switch 3: "Đồng bộ Lịch Ôn Tập sang Google Calendar" (Tắt).
Nút nguy hiểm: "[-> Đăng xuất tài khoản" (OutlinedButton đỏ #DC2626, cao 48dp).
Dialog Modal Overlay_Logout: Hộp thoại 320dp bo góc 16dp, tiêu đề "Đăng xuất tài khoản?", 2 nút Hủy và Đăng xuất (50/50).
States: Switch toggle bật/tắt mượt mà; popup logout hiển thị trên nền mờ barrierColor: Colors.black40.
User Interactions: Bấm vào thẻ Học kỳ Fall 2024 ➔ Mở SCR-07; Bấm Đăng xuất ➔ Mở Overlay_Logout.
Navigation:
Trên Overlay_Logout: Bấm Hủy ➔ Đóng popup; Bấm Đăng xuất ➔ Xóa session và gọi Navigator.pushNamedAndRemoveUntil('/login', (route) => false) về SCR-01.
Important UI Constraints: Mọi switch list tile có chiều cao tối thiểu 56dp; nút Đăng xuất có viền đỏ cảnh báo rõ ràng.
Phần 4 — Responsive (Width ≥ 600 dp) & QA Checklist
4.1. Quy tắc Responsive Tablet / Web (Width ≥ 600 dp)
Navigation Transition: NavigationBar ở đáy màn hình tự động chuyển đổi thành NavigationRail cố định ở cạnh trái màn hình.
Content Centering & Max-Width: Toàn bộ nội dung đọc chính (Hero card, Course strategy list, Profile) bọc trong:
code
Dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 540.0),
    child: contentWidget,
  ),
)
Lưới phân bổ môn (SCR-06A & SCR-07): Trên màn hình rộng ≥ 600 dp, danh sách môn học tự động chia thành lưới 2 cột (Grid 2 columns) song song.
4.2. Checklist nghiệm thu UI cho Flutter Developer (QA Checklist)

Màn hình chuẩn 390 × 800 dp: Bố cục vừa vặn trên chuẩn 390dp và co giãn hoàn hảo trên 412dp.

Bảng màu Warm Paper: 100% Scaffold dùng nền #FBF6EB; thẻ dùng #FFFDF7; viền nét liền 1px #EAE1D0. Tuyệt đối không dùng nền trắng tinh gây chói mắt.

Độ tương phản tiếp cận (WCAG 2.1 AA/AAA): Chữ nội dung tối thiểu 14sp; chữ tiêu đề đạt tương phản >12:1; badge trạng thái dùng chữ nâu đậm #78350F trên nền vàng nhạt #FEF3C7 (tương phản 7.2:1).

Kích thước vùng chạm (Touch Target): Mọi nút bấm, icon button, radio card, switch tile có diện tích bấm tối thiểu 48 × 48 dp.

Quy tắc hiển thị Bottom Navigation Bar (64dp):
HIỂN THỊ: SCR-02, SCR-03, SCR-04, SCR-07, SCR-08.
ẨN HOÀN TOÀN: SCR-01, SCR-05, SCR-06A, SCR-06B, SCR-06B_Resolved.

Bottom Clearance (Khoảng đệm an toàn):
Màn hình có Bottom Bar: padding-bottom: 96.0.
Màn hình có Footer Button (SCR-05, 06A, 06B): padding-bottom: 110.0 đến 120.0.

Phòng ngừa & Phục hồi lỗi (SCR-06B & SCR-06B_Resolved):
Nút "Lưu Kế Hoạch" bị khóa mờ khi còn môn vi phạm tiên quyết hoặc quá tải.
Có nút [⇄ Đổi môn khác] cạnh môn lỗi để hoán đổi môn tại chỗ.
Sau khi đổi môn thành công, nút Lưu sáng xanh #2563EB cho phép bấm tiếp.

Đầy đủ các States: Có màn hình Loading (Spinner & Skeleton), Empty State (kính lúp tìm kiếm rỗng), Error Banner (quá tải/mất mạng), và Modal Dialog Overlay xác nhận đăng xuất.