# EduPlan System Specification (Tài liệu Tổng quan Hệ thống & Thiết kế Slide)

> **Dự án**: PRM393 - EduPlan: Hệ thống Lập Kế Hoạch Học Tập & Cố Vấn Học Vụ Thông Minh  
> **Nền tảng**: Flutter (Mobile App & Web Admin Portal) + Firebase Spark Backend + Gemini AI  
> **Ngôn ngữ thiết kế**: Warm Paper Academic Design System  
> **Tác giả / Nhóm thực hiện**: Group 4 (Nguyễn Trọng Hiếu & Nhóm)

---

## SLIDE 1: Giới thiệu Bài toán & Tầm nhìn Dự án

### 1.1. Vấn đề thực tế của Sinh viên (Problem Statement)
- Sinh viên đại học (đặc biệt khối ngành Kỹ thuật Phần mềm - SE) thường gặp khó khăn khi đăng ký tín chỉ:
  - **Vi phạm môn tiên quyết**: Đăng ký môn chuyên ngành khi chưa hoàn thành môn cơ sở (VD: Học `SWT301` khi chưa qua `PRO192`).
  - **Quá tải học tập (Burnout / Overload)**: Đăng ký quá nhiều môn nặng trong cùng một kỳ, tổng giờ tự học vượt quá ngưỡng an toàn (> 25h/tuần) dẫn đến rớt môn hoặc tụt GPA.
  - **Mất phương hướng lộ trình**: Không ước tính được học phí, không theo dõi được tỷ lệ hoàn thành 145 tín chỉ tốt nghiệp, và thiếu lời khuyên chiến lược phân bổ môn học.

### 1.2. Giải pháp: Hệ sinh thái EduPlan (The Solution)
- **EduPlan** là hệ sinh thái cố vấn học tập 2 chiều:
  - **Mobile App (Dành cho Sinh viên)**: Tra cứu môn học, mô phỏng tải tự học thời gian thực, cảnh báo môn tiên quyết, lập và gửi kế hoạch học tập lên Cloud, nhận phản hồi phê duyệt từ Cố vấn, và nhận gợi ý học tập tối ưu từ **Gemini AI**.
  - **Web Admin Portal (Dành cho Cố vấn & Quản trị viên)**: Quản lý danh mục môn học (CRUD), xem thống kê tải sinh viên qua biểu đồ KPI, xét duyệt/từ chối kế hoạch học tập kèm lý do, và phát hành thông báo học vụ tức thì xuống Mobile.

---

## SLIDE 2: Kiến trúc Hệ thống Tổng thể (Architecture Diagram)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        HỆ SINH THÁI EDUPLAN                            │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
         ┌─────────────────────────┴─────────────────────────┐
         ▼                                                   ▼
┌──────────────────────────────────┐        ┌──────────────────────────────────┐
│        FLUTTER MOBILE APP        │        │        FLUTTER WEB ADMIN         │
│   (Role: Sinh viên / user)       │        │ (Role: Cố vấn / staff, admin)    │
│  - Tra cứu môn, kiểm tra tiên    │        │  - Dashboard KPI & Biểu đồ tải   │
│    quyết & giờ tự học            │        │  - Quản lý danh mục môn (CRUD)   │
│  - Phân tích quá tải & Gợi ý AI  │        │  - Duyệt/Từ chối kế hoạch học tập│
│  - Hộp thư thông báo học vụ      │        │  - Phát hành thông báo học vụ    │
│  - Xuất bản vẽ kế hoạch PDF A4   │        │  - Quản lý phân quyền tài khoản  │
└────────────────┬─────────────────┘        └─────────────────┬────────────────┘
                 │                                            │
                 └─────────────────────┬──────────────────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                    NỀN TẢNG FIREBASE BACKEND (SPARK $0)                      │
│                                                                              │
│  1. Firebase Authentication: Đăng nhập Google, cấp User.uid độc lập          │
│  2. Cloud Firestore: Cơ sở dữ liệu thời gian thực (Real-time NoSQL)          │
│  3. Firestore Security Rules: Deny-by-default, phân quyền RBAC 3 vai trò     │
│  4. Firebase AI Logic: Tích hợp Gemini AI Developer API (No PII, Fallback)   │
│  5. Firebase Remote Config: Điều khiển từ xa (Bật/tắt AI, Model, Prompt, Tải)│
│  6. Firebase App Check: Bảo vệ dữ liệu chống gọi lậu API                     │
│  7. Firebase Analytics & Crashlytics: Đo lường hành vi & giám sát lỗi        │
│  8. Firebase Hosting: Triển khai ứng dụng Web Admin toàn cầu                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## SLIDE 3: Bảng Công nghệ đã Triển khai (Technology Stack & Implementations)

Mỗi công nghệ được thiết kế tối giản, đóng gói rõ ràng theo từng dịch vụ:

### 1. Firebase Authentication & Google Sign-In
- **Nằm trong**: `lib/services/auth_service.dart`, `lib/screens/login_screen.dart`
- **Tác dụng thực tế**:
  - Đăng nhập an toàn 1-chạm bằng tài khoản Google (`@fpt.edu.vn` hoặc cá nhân).
  - Cấp mã định danh duy nhất (`User.uid`), phân tách hoàn toàn không gian dữ liệu giữa các tài khoản, không bị rò rỉ dữ liệu khi đổi email.

### 2. Cloud Firestore (Real-time NoSQL Database)
- **Nằm trong**: `lib/services/course_service.dart`, `lib/services/plan_service.dart`, `lib/services/student_service.dart`, `lib/services/database_seeder.dart`
- **Tác dụng thực tế**:
  - Lưu trữ và đồng bộ hóa thời gian thực 5 collections chính: `users`, `students`, `courses`, `study_plans`, `announcements`.
  - Tự động nạp dữ liệu mẫu ban đầu nếu database trống (`DatabaseSeeder.seedDatabaseIfEmpty`).
  - Hỗ trợ cache offline: nếu mất mạng, app đọc dữ liệu từ local draft và đồng bộ lại khi có mạng.

### 3. Firestore Security Rules (Kiểm soát Phân quyền RBAC)
- **Nằm trong**: `firebase/firestore.rules`, `firebase/tests/rules.test.js`
- **Tác dụng thực tế**:
  - Chặn đứng 100% truy cập trái phép ở cấp server (Deny by default, không dùng `if true`).
  - Phân quyền chặt chẽ 3 roles: Sinh viên (`user`), Cố vấn (`staff`), Quản trị viên (`admin`).
  - Chặn sinh viên tự duyệt kế hoạch của mình; bắt buộc Cố vấn phải ghi lý do (`reviewReason >= 3 ký tự`).
  - Cho phép Admin xóa vĩnh viễn môn học tạo nhầm, trong khi Cố vấn chỉ được phép ẩn/lưu trữ (`archived`).

### 4. Firebase Remote Config (Điều khiển Hệ thống Từ xa)
- **Nằm trong**: `lib/firebase/firebase_service.dart`, `lib/viewmodels/plan_analyzer_viewmodel.dart`, `lib/screens/home_screen.dart`
- **Tác dụng thực tế**:
  - Cho phép Admin thay đổi ngưỡng cảnh báo quá tải (`max_safe_workload_hours = 25h`) từ Firebase Console mà không cần cập nhật lại app.
  - Bật/tắt công tắc tính năng AI (`ai_feature_enabled`), đổi model Gemini (`gemini-3.8-flash`) và cập nhật System Prompt cố vấn linh hoạt.

### 5. Firebase AI Logic (Trí tuệ Nhân tạo Gemini AI)
- **Nằm trong**: `lib/services/ai_service.dart`, `lib/models/ai_plan_advice_model.dart`
- **Tác dụng thực tế**:
  - **Level 2 - Structured Output (JSON)**: Phân tích danh sách môn sinh viên chọn và trả về đánh giá rủi ro, phân bổ giờ học, và gợi ý đổi môn học tối ưu dưới dạng Model chuẩn.
  - **Bảo mật PII (Zero Personal Data)**: Bộ lọc `AiPrivacyGuard` loại bỏ toàn bộ tên, MSSV, email trước khi gửi lên AI.
  - **Khả năng tự phục hồi (Fallback Mechanism)**: Khi mất mạng hoặc hết quota, app tự động chuyển sang thuật toán quy tắc cục bộ (Rule-based) mà không làm gián đoạn người dùng.

### 6. Quản lý Trạng thái Riverpod (State Management)
- **Nằm trong**: `lib/viewmodels/course_catalog_viewmodel.dart`, `lib/viewmodels/plan_analyzer_viewmodel.dart`, `lib/viewmodels/completed_courses_viewmodel.dart`
- **Tác dụng thực tế**:
  - Quản lý luồng dữ liệu một chiều (Unidirectional Data Flow) chuẩn MVVM.
  - Tự động tính toán lại tổng tín chỉ, học phí ước tính (1.140.000đ/TC) và tổng giờ tự học ngay khi sinh viên thêm hoặc bớt một môn học.

### 7. Xuất Báo cáo Bản vẽ Kế hoạch PDF (Printing & PDF Engine)
- **Nằm trong**: `lib/services/pdf_export_service.dart`, `lib/screens/semester_summary_screen.dart`
- **Tác dụng thực tế**:
  - Tự động vẽ bản kế hoạch chuẩn khổ giấy A4 (210×297mm) gồm: Thông tin sinh viên, bảng KPI học kỳ, cơ cấu điểm 40/30/30 và mã xác thực Firestore.
  - Cho phép in trực tiếp hoặc lưu/chia sẻ file PDF trên thiết bị di động.

---

## SLIDE 4: Chi tiết 8 Màn hình trên Mobile App (`mobile/`)

| Mã màn hình | Tên màn hình | Chức năng chính |
| :--- | :--- | :--- |
| **SCR-01** | **Đăng nhập (`LoginScreen`)** | Đăng nhập Google 1-chạm, xử lý trạng thái Loading/Error, tự tạo hồ sơ sinh viên mới. |
| **SCR-02** | **Trang chủ (`HomeScreen`)** | Xem tiến độ tốt nghiệp (TC tích lũy / 145 TC), thẻ trạng thái duyệt kế hoạch (`Chờ duyệt`, `Đã duyệt`), mẹo học tập Remote Config, chuông thông báo real-time. |
| **SCR-03** | **Môn đã học (`CompletedCoursesScreen`)** | Quản lý bảng điểm các môn đã hoàn thành, tính toán GPA hệ 4 và hệ 10 tự động, mở khóa các môn tiên quyết tiếp theo. |
| **SCR-04** | **Tìm môn học (`CourseCatalogScreen`)** | Tra cứu danh mục môn học, bộ lọc danh mục (`Tất cả`, `Chuyên ngành SE`, `Cơ sở`), tìm kiếm theo mã/tên môn, xem độ khó ⭐ và giờ tự học. |
| **SCR-05** | **Chi tiết môn (`CourseDetailScreen`)** | Xem điều kiện tiên quyết, cấu trúc điểm thành phần (Assignment/Lab/PE/FE), chọn mục tiêu điểm (A/B/Qua môn), thêm môn vào kế hoạch. |
| **SCR-06A** | **Phân tích kế hoạch (`PlanAnalyzerScreen`)** | Đồng hồ đo áp lực học tập (Workload Meter), cảnh báo quá tải >25h/tuần, phát hiện vi phạm môn tiên quyết, tích hợp gợi ý cố vấn từ Gemini AI. |
| **SCR-06B** | **Môn đã chọn (`SelectedCoursesScreen`)** | Danh sách các môn dự định học trong kỳ, hoán đổi môn quá tải sang môn nhẹ hơn, công tắc bật/tắt cảnh báo quá tải, nút gửi Cố vấn duyệt. |
| **SCR-07** | **Tổng kết kế hoạch (`SemesterSummaryScreen`)** | Bảng tổng kết số môn, tổng tín chỉ, dự toán học phí, xuất bản vẽ kế hoạch A4 ra PDF và chia sẻ. |
| **SCR-08** | **Hồ sơ cá nhân (`ProfileScreen`)** | Chỉnh sửa MSSV, chuyên ngành, khóa học, GPA mục tiêu; đồng bộ ngay lập tức lên Firestore `students/{uid}`. |

---

## SLIDE 5: Chi tiết 4 Màn hình + 1 Form trên Web Admin (`web/`)

| Mã màn hình | Tên màn hình | Đối tượng sử dụng | Chức năng chính |
| :--- | :--- | :--- | :--- |
| **WEB-01** | **Sign-in & Role Gate** | Cố vấn & Admin | Đăng nhập Google. Nếu tài khoản có `role == 'user'` (sinh viên) -> từ chối truy cập và thông báo rõ ràng. |
| **WEB-02** | **Dashboard Học vụ** | Cố vấn & Admin | 4 chỉ số thống kê tổng hợp từ Firestore (`count()`): Tổng sinh viên, Kế hoạch chờ duyệt, Kế hoạch đã duyệt, Môn đang mở + 1 Biểu đồ phân bổ tải học tập. |
| **WEB-03** | **Quản trị Môn học (CRUD)** | Cố vấn & Admin | Tìm kiếm, thêm môn mới, sửa môn học, lưu trữ (`archive`) môn cũ. Riêng **Admin** có thêm nút xóa vĩnh viễn (`delete`) môn tạo nhầm. |
| **WEB-04** | **Hàng đợi Duyệt Kế hoạch** | Cố vấn & Admin | Xem danh sách kế hoạch học tập sinh viên gửi lên theo thời gian thực; phê duyệt (`Approve`) hoặc từ chối (`Reject`) kèm lý do cố vấn (`reviewReason >= 3 ký tự`). |
| **WEB-05** | **Form Thông báo & Phân quyền** | Cố vấn & Admin | Đăng thông báo học vụ gửi tức thì xuống hộp thư Mobile; Admin quản trị phân quyền tài khoản giữa `'user'`, `'staff'`, `'admin'`. |

---

## SLIDE 6: Điểm Sáng Kỹ thuật (Technical Highlights & Innovations)

1. **Kiến trúc dữ liệu đồng nhất (Single Source of Truth)**:
   - Cả Mobile App và Web Admin cùng kết nối vào 1 database Cloud Firestore duy nhất. Khi Cố vấn bấm "Approve" trên Web, badge trạng thái trên điện thoại sinh viên đổi từ màu vàng `"⏳ Chờ duyệt"` sang màu xanh `"✅ Đã được duyệt"` ngay trong tích tắc (Real-time Streams).
2. **Chi phí vận hành $0 (Zero Cost Spark Plan)**:
   - Tối ưu hóa 100% trong hạn mức miễn phí của Firebase: Không sử dụng Cloud Functions (tiết kiệm chi phí), xuất PDF trực tiếp trên thiết bị thay vì Cloud Storage, dùng Gemini Developer API miễn phí.
3. **Bảo mật đa tầng**:
   - Xác thực danh tính qua Firebase Auth -> Kiểm tra quyền qua Firestore Security Rules (14/14 tests pass) -> Chống giả mạo qua App Check.
4. **Trải nghiệm người dùng thân thiện (Warm Paper UX)**:
   - Tông màu giấy kem ấm áp dịu mắt (`#FBF6EB`), phân cấp thị giác rõ ràng, font chữ chuẩn học thuật Inter, hỗ trợ trợ năng tiếp cận (Accessibility / Semantics) đạt chuẩn kiểm thử ARTEMIS.
