# EduPlan — Design Traceability Matrix (Lab 3)

Tài liệu liên kết và kiểm soát tính nhất quán giữa thiết kế Figma (Lab 2) và ứng dụng Flutter thực tế (Lab 3).
Định dạng màn hình chuẩn: **390 × 800 dp** | Phong cách: **Warm Paper Academic**.

---

## 1. Bảng ánh xạ Màn hình (Screens Traceability)

| Mã màn hình | Tên màn hình (Figma) | Flutter Route | Widget chính (`lib/screens/`) | Nguồn dữ liệu | Trạng thái | Ghi chú & Sai lệch |
|:---|:---|:---|:---|:---|:---|:---|
| **SCR-01** | Login Screen | `/login` | `LoginScreen` | Firebase Auth (Google Sign-In) | Sẵn sàng | Có State `SCR-01_Loading` hiển thị spinner khi xác thực |
| **SCR-02** | Home Planner Dashboard | `/home` | `HomeScreen` | Firestore `student_profile` & `courses` | Sẵn sàng | Tab 1 Bottom Bar; Hero Card tuần 8, Tips học tập |
| **SCR-03** | Completed Courses | `/completed-courses` | `CompletedCoursesScreen` | Firestore `completed_courses` | Sẵn sàng | Tab 2 Bottom Bar; Tiến độ 90/145 TC; Filter kỳ học; Nút "+ Thêm môn theo kỳ" kiểm tra kỳ 2 phải có kỳ 1 & môn tiên quyết |
| **SCR-04** | Course Catalog | `/catalog` | `CourseCatalogScreen` | Firestore `courses` (Catalog) | Sẵn sàng | Tab 3 Bottom Bar; Search, Filter, Skeleton & Empty state |
| **SCR-05** | Course Detail & Strategy | `/course-detail` | `CourseDetailScreen` | Firestore `courses/{id}` | Sẵn sàng | Ẩn Bottom Bar; Cấu trúc điểm 40/30/30; 3 mức mục tiêu điểm (A/B/Pass) |
| **SCR-06A**| Workload & Strategy Analyzer | `/plan-analyzer` | `PlanAnalyzerScreen` | Local State + Remote Config | Sẵn sàng | Ẩn Bottom Bar; Báo động đỏ 34h tự học > ngưỡng an toàn 25h |
| **SCR-06B**| Selected Courses (Conflict) | `/selected-courses` | `SelectedCoursesScreen` | State: `hasConflict = true` | Sẵn sàng | Ẩn Bottom Bar; Nút Lưu bị khóa xám; nút [⇄ Đổi môn khác] |
| **SCR-06B_Resolved** | Selected Courses (Resolved) | `/selected-courses` | `SelectedCoursesScreen` | State: `hasConflict = false` | Sẵn sàng | Đổi môn PRM323, tải 26h tự học; Nút Lưu Kế Hoạch sáng xanh |
| **SCR-07** | Semester Summary & Export PDF | `/summary` | `SemesterSummaryScreen` | Plan State + PDF Service | Sẵn sàng | Khôi phục Bottom Bar; KPI 5 môn, nút "✅ Đã Hoàn Thành Kỳ Học" tự động lưu môn vào Môn Đã Học, nút xuất PDF A4, sync lịch |
| **SCR-08** | Profile & Settings | `/profile` | `ProfileScreen` | Firebase Auth & Remote Config | Sẵn sàng | Tab 4 Bottom Bar; Thông tin SV, Nút Chỉnh sửa hồ sơ cá nhân (tên, ảnh, GPA mục tiêu), 3 toggle switch, Demo Firebase area |
| **Overlay_Logout** | Modal Xác nhận Đăng xuất | Dialog Overlay | `LogoutConfirmDialog` | Firebase Auth Service | Sẵn sàng | Hộp thoại bo góc 16dp, nền mờ barrierColor |

---

## 2. Bảng ánh xạ 3 Luồng người dùng (User Flows Traceability)

### Flow 1: Tra cứu môn học & Thiết lập mục tiêu chiến lược
* **Các bước**: `SCR-02` (Home) $\to$ Tab Tìm môn $\to$ `SCR-04` (Catalog) $\to$ Tìm kiếm / Chọn môn PRM393 $\to$ `SCR-05` (Course Detail).
* **Hành động & Phục hồi lỗi**: Nếu từ khóa tìm kiếm không tồn tại, `SCR-04` hiển thị Empty State với nút "Xóa bộ lọc".

### Flow 2: Lập kế hoạch học kỳ, Phát hiện quá tải & Khắc phục xung đột (Error Recovery Path)
* **Các bước**: `SCR-05` $\to$ Bấm "Thêm vào Kế hoạch" $\to$ `SCR-06A` (Analyzer hiển thị cảnh báo đỏ 34h/tuần và vi phạm tiên quyết môn IAE201) $\to$ Bấm "Điều chỉnh kế hoạch" $\to$ `SCR-06B` (Nút Lưu bị khóa) $\to$ Bấm [⇄ Đổi môn khác] $\to$ `SCR-05` chọn PRM323 $\to$ `SCR-06B_Resolved` (Tải về 26h/tuần, nút Lưu Kế Hoạch mở khóa xanh).
* **Kết quả**: Chuyển tiếp tới `SCR-07` để xem bản tổng kết hợp lệ.

### Flow 3: Xuất tài liệu Blueprint PDF A4 & Quản lý tài khoản
* **Các bước**: `SCR-07` $\to$ Bấm "📄 Xuất PDF Kế Hoạch & Chiến Lược (A4)" $\to$ Tạo file PDF A4, tải lên Cloud Storage `/reports/{uid}/...` và lưu metadata vào Firestore $\to$ Mở hộp thoại In / Chia sẻ $\to$ Sang `SCR-08` $\to$ Cấu hình thông báo $\to$ Bấm Đăng xuất $\to$ Hiện `Overlay_Logout` $\to$ Xác nhận đăng xuất về `SCR-01`.

### Flow 4: Nghiệm thu hoàn thành kỳ học & Tự khai báo lộ trình học tập quá khứ
* **Nghiệm thu kỳ học (`SCR-07`)**: Tại bản tổng kết kế hoạch, sinh viên bấm nút **"✅ Đã Hoàn Thành Kỳ Học"** $\to$ Hệ thống tự động chuyển toàn bộ các môn đang lập kế hoạch thành các môn đã hoàn thành, cộng dồn số tín chỉ vào `accumulatedCredits` và cập nhật tiến độ tốt nghiệp $\to$ Tự động chuyển người dùng sang `SCR-03` để thấy môn mới được ghi nhận.
* **Tự khai báo môn đã học theo kỳ (`SCR-03`)**: Sinh viên bấm nút **"+ Thêm môn đã học theo kỳ"** $\to$ Chọn kỳ học và môn đã học.
  * *Kiểm tra tiến trình kỳ*: Bắt buộc Kỳ 1 đến Kỳ $N-1$ phải có môn mới được thêm vào Kỳ $N$ ("kì 2 phải có kì 1").
  * *Kiểm tra môn tiên quyết*: Môn thêm vào Kỳ $N$ phải có các môn tiên quyết nằm trong danh mục đã Pass ở các kỳ trước đó ($< N$).

### Flow 5: Trải nghiệm Đa Persona & Khởi tạo tài khoản mới (Onboarding Flow)
* **3 Persona mẫu**: `Trần Hoàng Long` (Năm 3 - Kế hoạch xung đột 34h demo đổi môn sang 26h), `Nguyễn Mai Linh` (Năm cuối - GPA 3.82, kỳ tốt nghiệp cân bằng), `Lê Minh Tuấn` (Năm 2 - Rủi ro học vụ quá tải 38h).
* **Tài khoản mới hoàn toàn**: Khi một tài khoản Google mới đăng nhập (chưa định danh trước), hệ thống nhận diện là Hồ sơ Rỗng $\to$ Hiển thị thông báo yêu cầu thiết lập hồ sơ và thêm môn $\to$ Chuyển sang `SCR-08` bấm **"Chỉnh sửa hồ sơ"** để nhập Họ tên, MSSV, ảnh đại diện, GPA mục tiêu.

---

## 3. Bảng ánh xạ Components Reusable

| Tên Component (Figma) | Flutter Widget | File nguồn | Variants / States |
|:---|:---|:---|:---|
| Primary Button | `AppPrimaryButton` | `lib/widgets/app_button.dart` | Default, Loading (Spinner), Disabled |
| Tonal Button | `AppTonalButton` | `lib/widgets/app_button.dart` | Default, Pressed |
| Destructive Button | `AppDestructiveButton` | `lib/widgets/app_button.dart` | Outlined viền đỏ, Filled đỏ |
| Course Strategy Card | `CourseStrategyCard` | `lib/widgets/course_strategy_card.dart` | Normal, Selected, Conflict (Viền đỏ 1.5px) |
| Search Bar | `AppSearchBar` | `lib/widgets/app_search_bar.dart` | Default, Focused, Has text |
| Status Badge / Pill | `StatusBadge` | `lib/widgets/status_badge.dart` | Success (xanh lá), Warning (vàng nâu), Error (đỏ) |
| Empty State | `AppEmptyState` | `lib/widgets/app_empty_state.dart` | Icon kính lúp + Text + Nút Retry/Clear |
| Error Banner | `AppAlertBanner` | `lib/widgets/app_alert_banner.dart` | Nền đỏ nhạt, viền đỏ, icon ⚠️ cảnh báo |
| Navigation Shell | `MainScaffold` | `lib/widgets/main_scaffold.dart` | Quản lý Bottom Navigation Bar 4 tabs |
