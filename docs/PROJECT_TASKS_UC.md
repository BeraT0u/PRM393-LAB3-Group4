# 📊 EduPlan — Bảng Phân Chia Công Việc & Danh Sách Use Cases (UC)

> **File Excel gốc**: [`EduPlan_Project_Tasks_UC.xlsx`](../EduPlan_Project_Tasks_UC.xlsx)  
> Bảng này liệt kê chi tiết từng phần việc cần code từ khi khởi tạo dự án cho đến khi hoàn thiện 100% đồ án EduPlan PRM393.
> Có thể mở trực tiếp bằng Microsoft Excel hoặc tải lên Google Trang tính (Google Sheets).

---

## 📐 Cấu trúc các cột trong File Excel (Columns Specification)

| Cột | Tên Cột | Ý nghĩa & Hướng dẫn sử dụng |
|:---:|:---|:---|
| **A** | **ID** | Mã định danh công việc / Use Case (`SETUP-01`, `UC-01` $\to$ `UC-39`). |
| **B** | **Function / Screen** | Tên chức năng cụ thể, màn hình phụ trách (`SCR-01` $\to$ `SCR-08`) và mô tả nghiệp vụ cần hoàn thành. |
| **C** | **Level** | Độ phức tạp ước lượng: `Simple (N=1..2)`, `Medium (N=3..4)`, `Hard (N=5..6)`. |
| **D** | **Responsible by** | *(Đang để trống)* Nhóm trưởng điền tên thành viên phụ trách (FE + BE/Firebase gộp chung). |
| **E** | **Date** | *(Đang để trống)* Ngày cam kết / ngày hoàn thiện thực tế của Use Case. |
| **F** | **Trạng thái** | Trạng thái hiện tại: `Chưa bắt đầu` (Đỏ) / `Đang làm` (Vàng) / `Đã commit` (Xanh lá). |
| **G** | **Note** | Tiêu chuẩn nghiệm thu kỹ thuật, file source code liên quan hoặc lưu ý đặc thù. |

---

## 📋 Danh sách toàn bộ các Use Case (UC) Dự án EduPlan

### 🔷 NHÓM 0: NỀN TẢNG KỸ THUẬT & KHỞI TẠO HỆ THỐNG
| ID | Function / Screen | Level | Responsible by | Date | Trạng thái | Note |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **SETUP-01** | Khởi tạo dự án Flutter, cấu hình package name `com.eduplan.app` & Git repo | Simple (N=1) | | 28/10/2026 | `Đã commit` | Cấu hình build.gradle.kts, Git commit theo quy tắc `[DD/MM/YYYY][TrongHieu]` |
| **SETUP-02** | Cấu hình Firebase project `prm393-eduplan` & SHA-1 keystore dùng chung | Medium (N=3) | | 28/10/2026 | `Đã commit` | Tích hợp google-services.json & debug.keystore chia sẻ cho mọi thành viên |
| **SETUP-03** | Xây dựng Design System Tokens (Warm Paper Academic Theme) | Simple (N=2) | | 28/10/2026 | `Đã commit` | AppColors (#FBF6EB canvas), AppTypography (Inter), AppDimens, AppTheme |
| **SETUP-04** | Thiết kế Data Models & DTOs tuần tự hóa với Firestore | Simple (N=2) | | 28/10/2026 | `Đã commit` | CourseModel, StudentProfileModel, StudyPlanModel có toMap() & fromMap() |
| **SETUP-05** | Xây dựng Firebase Services & Bộ nạp dữ liệu mẫu (DatabaseSeeder) | Medium (N=4) | | 28/10/2026 | `Đã commit` | CourseService, StudentService, PlanService, StorageService, Seeder 7 môn học mẫu |
| **SETUP-06** | Soạn thảo tài liệu kỹ thuật & Hướng dẫn cài đặt cho nhóm | Simple (N=2) | | 28/10/2026 | `Đã commit` | design-traceability.md, architecture.md, analytics-plan.md, DATABASE_AND_TEAM_GUIDE.md |

---

### 🔷 NHÓM 1: REUSABLE UI COMPONENTS (Thành phần giao diện dùng chung)
| ID | Function / Screen | Level | Responsible by | Date | Trạng thái | Note |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **UC-01** | Bộ nút bấm chuẩn Design System (Primary, Tonal, Destructive Button) | Simple (N=2) | | 28/10/2026 | `Đã commit` | Cao 48-52dp, touch target >= 48dp, các state: Default, Pressed, Disabled, Spinner |
| **UC-02** | Thẻ môn học chiến lược (CourseStrategyCard) & State vi phạm viền đỏ | Medium (N=3) | | 28/10/2026 | `Đã commit` | Hiển thị độ khó ⭐, giờ tự học, viền 1px solid, biến thể Conflict viền đỏ 1.5px |
| **UC-03** | Thanh tìm kiếm (AppSearchBar) & Bộ lọc Filter Chips chuyên ngành | Simple (N=2) | | 28/10/2026 | `Đã commit` | Ô Search cao 48dp bo góc 8dp, các chip: Tất cả, Chuyên ngành SE, Cơ sở |
| **UC-04** | Bộ Badge trạng thái (StatusBadge / Tag Pill) chuẩn tương phản WCAG | Simple (N=1) | | 28/10/2026 | `Đã commit` | Success (xanh lá #DCFCE7), Warning (vàng nâu #FEF3C7), Danger (đỏ #FEE2E2) |
| **UC-05** | Banner báo động đỏ quá tải & vi phạm tiên quyết (AppAlertBanner) | Simple (N=1) | | 28/10/2026 | `Đã commit` | Nền đỏ nhạt #FEE2E2, viền đỏ #DC2626, icon ⚠️, chữ đỏ đậm #B91C1C |
| **UC-06** | Trạng thái Shimmer Loading (Skeleton) & Empty State tìm kiếm rỗng | Simple (N=2) | | 28/10/2026 | `Đã commit` | Shimmer xám #EAE1D0; Empty state icon kính lúp + nút "Xóa bộ lọc" |
| **UC-07** | Khung điều hướng chung MainScaffold & Responsive NavigationRail | Medium (N=3) | | 28/10/2026 | `Đã commit` | NavigationBar 64dp 4 tab (Mobile) tự chuyển sang NavigationRail khi width >= 600dp |

---

### 🔷 NHÓM 2: MÀN HÌNH ĐĂNG NHẬP & TRANG CHỦ (SCR-01 & SCR-02)
| ID | Function / Screen | Level | Responsible by | Date | Trạng thái | Note |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **UC-08** | SCR-01 Màn hình Đăng nhập & State SCR-01_Loading | Simple (N=2) | | 28/10/2026 | `Đã commit` | Logo sổ tay 64dp, slogan, nút đăng nhập Google, spinner "Đang xác thực Google..." |
| **UC-09** | Xử lý Google Sign-In & Đa Persona (3 TK mẫu Long/Linh/Tuấn; TK mới báo rỗng) | Medium (N=3) | | | `Chưa bắt đầu` | Long (90TC, 34h conflict), Linh (125TC, kỳ tốt nghiệp), Tuấn (35TC, 38h); TK mới báo hồ sơ trống |
| **UC-10** | SCR-02 Home Dashboard: Lời chào, tích lũy 90/145 TC, GPA mục tiêu 3.60 | Simple (N=2) | | | `Chưa bắt đầu` | Top App Bar, Avatar sinh viên, pull-to-refresh cập nhật dữ liệu từ Firestore |
| **UC-11** | SCR-02 Hero Card "🔥 Trọng tâm Tuần 8": Tiến độ tự học môn PRM393 (6/8h) | Simple (N=2) | | | `Chưa bắt đầu` | Thanh progress bar xanh, tag Mục tiêu Điểm A, chạm vào mở chi tiết môn SCR-05 |
| **UC-12** | SCR-02 Section "💡 Tips học tập kỳ này" kết hợp Remote Config toggle | Simple (N=2) | | | `Chưa bắt đầu` | 2 thẻ gợi ý ngắn SWE302 (C4 Model) và DBI202; ẩn/hiện theo enable_study_tips |

---

### 🔷 NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03, 04, 05)
| ID | Function / Screen | Level | Responsible by | Date | Trạng thái | Note |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **UC-13** | SCR-03 Màn hình Môn Đã Học (Completed Courses) & Thẻ tiến độ 90/145 TC | Medium (N=3) | HuyNH | 28/10/2026 | `Đã commit` | Card Tiến độ 90/145 TC (62%), Filter Chips theo kỳ, dòng chú thích mở khóa PRM393 |
| **UC-13B**| SCR-03 Modal Thêm môn đã học theo kỳ: Thẩm định kỳ 2 phải có kỳ 1 & Tiên quyết | Hard (N=5) | HuyNH | 28/10/2026 | `Đã commit` | Nút riêng cho SV tự add môn từng kỳ, validate kỳ 2 phải có kỳ 1 và môn tiên quyết phải hoàn thành trước |
| **UC-14** | SCR-04 Course Catalog: Danh mục môn mở, tìm kiếm & độ khó tự học | Medium (N=3) | HuyNH | 28/10/2026 | `Đã commit` | Thẻ môn học, số TC, độ khó ⭐, tự học h/tuần, nút Tonal Button "Chiến lược >" |
| **UC-15** | SCR-04 Xử lý Shimmer Skeleton khi tải & Empty State khi tìm kiếm rỗng | Simple (N=2) | HuyNH | 28/10/2026 | `Đã commit` | Khi tìm từ khóa không có môn (VD: XYZ99) hiện kính lúp buồn + nút Xóa bộ lọc |
| **UC-16** | SCR-05 Course Strategy: Header môn PRM393 & 3 badge thông số | Simple (N=2) | HuyNH | 28/10/2026 | `Đã commit` | 3 badge: 3 Tín chỉ, Độ khó 4/5 ⭐, Tiên quyết PRO192 ✅. Ẩn hoàn toàn Bottom Bar |
| **UC-17** | SCR-05 Cấu trúc điểm 40/30/30 & Thẻ Study Tips khóa trên | Simple (N=2) | HuyNH | 28/10/2026 | `Đã commit` | 3 hộp thông số: Đồ án 40%, Lab 30%, FE 30%; Thẻ vàng nhạt tips làm Riverpod/MVVM |
| **UC-18** | SCR-05 Radio Card chọn Mục tiêu điểm (Điểm A: 8h, B: 5h, Qua môn: 3.5h) | Medium (N=3) | HuyNH | 28/10/2026 | `Đã commit` | 3 Radio card tương tác mượt mà, tự động cập nhật số giờ tự học dự kiến |
| **UC-19** | SCR-05 Docked Action Footer: Nút yêu thích + Nút "Thêm vào Kế hoạch" | Simple (N=2) | HuyNH | 28/10/2026 | `Đã commit` | Cố định chân trang, padding-bottom 110dp chống đè nội dung, điều hướng sang SCR-06A |

---

### 🔷 NHÓM 4: PHÂN TÍCH QUÁ TẢI & KHẮC PHỤC XUNG ĐỘT (SCR-06A & 06B)
| ID | Function / Screen | Level | Responsible by | Date | Trạng thái | Note |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **UC-20** | SCR-06A Workload Analyzer: Banner cảnh báo đỏ quá tải & vi phạm | Simple (N=2) | | | `Chưa bắt đầu` | Nền đỏ #FEE2E2, viền #DC2626, icon ⚠️ "Cảnh báo: Vi phạm tiên quyết & Quá tải!" |
| **UC-21** | SCR-06A Thẻ Workload Meter: 34h/tuần vượt ngưỡng an toàn (25h Remote Config) | Medium (N=3) | | | `Chưa bắt đầu` | Thanh progress bar có đoạn màu đỏ báo quá tải, lấy max_safe_workload_hours động |
| **UC-22** | SCR-06A Danh sách 4 thẻ môn: 3 môn hợp lệ và 1 môn vi phạm đỏ IAE201 | Medium (N=3) | | | `Chưa bắt đầu` | PRM393 (8h), SWE302 (7h), AIE411 (7h); IAE201 (+12h, LỖI chưa học tiên quyết NWC203) |
| **UC-23** | SCR-06B Selected Courses (State lỗi): Nút Lưu BỊ KHÓA & Nút [⇄ Đổi môn] | Hard (N=5) | | | `Chưa bắt đầu` | Nút chân trang màu xám "🔒 Giải quyết 1 xung đột để lưu"; nút Đổi môn mở SCR-05 |
| **UC-24** | SCR-06B_Resolved Khắc phục xung đột: Đổi sang PRM323, tải 26h Cân bằng | Hard (N=5) | | | `Chưa bắt đầu` | Môn thứ 4 đổi thành PRM323 (4h), tổng 26h; NÚT LƯU MỞ KHÓA MÀU XANH ACTIVE |
| **UC-25** | Lưu Kế hoạch học tập vào Firestore & Chuyển hướng sang SCR-07 | Medium (N=3) | | | `Chưa bắt đầu` | Ghi dữ liệu kế hoạch hợp lệ vào study_plans trên Cloud Firestore, pushNamed sang SCR-07 |

---

### 🔷 NHÓM 5: TỔNG KẾT KẾ HOẠCH & XUẤT BLUEPRINT PDF (SCR-07)
| ID | Function / Screen | Level | Responsible by | Date | Trạng thái | Note |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **UC-26** | SCR-07 Semester Summary: Thẻ Hero KPI (5 Môn, 15 TC, GPA 3.65, 26h tự học) | Simple (N=2) | | | `Chưa bắt đầu` | Khôi phục Bottom Bar; 4 nhãn KPI chia 2 hàng: Lộ trình hợp lệ, Học phí 14.250.000đ |
| **UC-26B**| SCR-07 Nút "Đã hoàn thành kỳ học": Tự động lưu các môn vào Môn Đã Học & Tích lũy TC | Medium (N=4) | | | `Chưa bắt đầu` | Tự động chuyển các môn trong kỳ thành Môn đã hoàn thành, cộng dồn accumulatedCredits và update status |
| **UC-27** | SCR-07 Danh sách 5 môn học kèm mục tiêu điểm (A / B+) và tích xanh ✅ | Simple (N=2) | | | `Chưa bắt đầu` | Hiển thị PRM393, SWE302, AIE411, PRM323, OSG209 thẻ nhỏ gọn, căn gióng đẹp mắt |
| **UC-28** | SCR-07 Tạo file tài liệu PDF Blueprint A4 Kế hoạch học tập | Medium (N=4) | | | `Chưa bắt đầu` | Dựng bằng pdf & printing package: Header, bảng KPI, bảng điểm & giờ tự học từng môn |
| **UC-29** | SCR-07 Upload file PDF lên Firebase Storage reports/{uid}/... & hiển thị progress | Hard (N=5) | | | `Chưa bắt đầu` | Thanh tiến trình % tải lên, lấy download URL thật trên Cloud Storage (bucket Blaze) |
| **UC-30** | SCR-07 Kích hoạt hộp thoại xem trước in ấn PDF & Đồng bộ lịch Google Calendar | Simple (N=2) | | | `Chưa bắt đầu` | Nút "📄 Xuất PDF Kế Hoạch & Chiến Lược (A4)", nút Đồng bộ lịch và nút Chia sẻ |

---

### 🔷 NHÓM 6: HỒ SƠ CÁ NHÂN & FIREBASE DEMO (SCR-08)
| ID | Function / Screen | Level | Responsible by | Date | Trạng thái | Note |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **UC-31** | SCR-08 Profile: Thẻ sinh viên & Modal Chỉnh sửa hồ sơ (Tên, Ảnh, MSSV, GPA mục tiêu) | Medium (N=3) | | | `Chưa bắt đầu` | Avatar tròn, nút Chỉnh sửa hồ sơ, modal cập nhật Họ tên, MSSV, ảnh đại diện, GPA mục tiêu lên Firestore |
| **UC-32** | SCR-08 Thẻ học kỳ Fall 2024: Nút "Chi tiết >" mở lại màn hình SCR-07 | Simple (N=1) | | | `Chưa bắt đầu` | Touch target 48dp, chuyển hướng mượt mà sang bản tổng kết kế hoạch đã lưu |
| **UC-33** | SCR-08 Nhóm cài đặt 3 Switch: Nhắc hạn Lab, Cảnh báo quá tải, Sync Calendar | Simple (N=2) | | | `Chưa bắt đầu` | Chiều cao mỗi tile >= 56dp, đồng bộ trạng thái toggle tức thời lên Cloud Firestore |
| **UC-34** | SCR-08 Firebase Demo Showcase: Crashlytics test, Remote Config & FCM inbox | Medium (N=4) | | | `Chưa bắt đầu` | Nút test Crashlytics (non-fatal error & crash), hiển thị giá trị Remote Config động |
| **UC-35** | Overlay_Logout Modal: Hộp thoại xác nhận đăng xuất tài khoản | Simple (N=2) | | | `Chưa bắt đầu` | Dialog 320dp bo góc 16dp, 2 nút Hủy và Đăng xuất (50/50), xóa session về SCR-01 |

---

### 🔷 NHÓM 7: ĐO LƯỜNG SỰ KIỆN & KIỂM THỬ E2E (Analytics & Testing)
| ID | Function / Screen | Level | Responsible by | Date | Trạng thái | Note |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **UC-36** | Gắn mã ghi nhận 8 sự kiện Firebase Analytics (DebugView verification) | Medium (N=3) | | | `Chưa bắt đầu` | Đầy đủ parameters không PII: login, search, view_detail, conflict, resolve, export... |
| **UC-37** | Gắn Semantics Labels trợ năng cho toàn bộ nút bấm, card, ô nhập liệu | Simple (N=2) | | | `Chưa bắt đầu` | Phục vụ khả năng tiếp cận WCAG và giúp AI Agent ARTEMIS đọc cây widget |
| **UC-38** | Xây dựng kịch bản kiểm thử E2E tự động với Google ARTEMIS / Pytest | Hard (N=6) | | | `Chưa bắt đầu` | >= 10 test cases trong e2e_test/, bao gồm luồng chính, native dialog và error-path |
| **UC-39** | Thực hiện AI-Assisted Code Review & lưu bằng chứng docs/code-review.md | Medium (N=3) | | | `Chưa bắt đầu` | Ghi nhận >= 5 findings, ra quyết định chấp nhận/từ chối và >= 3 commit sửa lỗi |
