# EduPlan — System Architecture Documentation (Lab 3)

Tài liệu thiết kế kiến trúc phần mềm cho ứng dụng EduPlan theo mô hình **MVVM (Model-View-ViewModel)** nghiêm ngặt, kết hợp quản lý trạng thái bằng **Riverpod**.

---

## 1. Cấu trúc thư mục (Folder Structure)

```text
lib/
├── firebase/       # Khởi tạo và bao bọc các dịch vụ Firebase SDK (Auth, Firestore, Storage, Messaging, RemoteConfig)
├── models/         # Các lớp dữ liệu thực thể thuần (Course, StudentProfile, StudyPlan, PrerequisiteCheck)
├── services/       # Giao diện và tầng dịch vụ gọi mạng, cơ sở dữ liệu, PDF generator
├── theme/          # Hệ thống Design Tokens: AppColors, AppTypography, AppDimens, AppTheme
├── utils/          # Các tiện ích chuyển đổi dữ liệu, định dạng số, ngày tháng, logger
├── viewmodels/     # Tầng logic nghiệp vụ, giữ State của màn hình, lắng nghe Service và phát thông báo
├── widgets/        # Các thành phần giao diện tái sử dụng (Buttons, Cards, SearchBar, Badges, Banners)
└── screens/        # Các màn hình người dùng tương ứng từ SCR-01 đến SCR-08
```

---

## 2. Sơ đồ các tầng kiến trúc (MVVM Layer Diagram)

Các phụ thuộc tuân thủ nguyên tắc một chiều (chỉ trỏ xuống dưới, tầng dưới tuyệt đối không import tầng trên). Widget giao diện không bao giờ gọi trực tiếp Firebase hay HTTP.

```mermaid
graph TD
    subgraph ViewLayer["View Layer (screens/, widgets/)"]
        V1["Screens: SCR-01 to SCR-08"]
        V2["Reusable Widgets: Buttons, Cards, Badges"]
    end

    subgraph ViewModelLayer["ViewModel Layer (viewmodels/)"]
        VM1["AuthViewModel"]
        VM2["CourseCatalogViewModel"]
        VM3["PlanAnalyzerViewModel"]
        VM4["ProfileViewModel"]
    end

    subgraph ModelLayer["Model Layer (models/)"]
        M1["Course"]
        M2["StudyPlan"]
        M3["StudentProfile"]
        M4["WorkloadAnalysisResult"]
    end

    subgraph ServiceLayer["Service & Repository Layer (services/, firebase/)"]
        S1["AuthService (Google Sign-In)"]
        S2["CourseService (Firestore Catalog)"]
        S3["PlanService (Firestore / Local Plan)"]
        S4["PdfReportService (PDF generation & upload)"]
        S5["RemoteConfigService (Thresholds & Flags)"]
        S6["AnalyticsCrashlyticsService (Telemetry)"]
    end

    subgraph Backend["Cloud Infrastructure"]
        FB1["Firebase Auth"]
        FB2["Cloud Firestore"]
        FB3["Cloud Storage"]
        FB4["Firebase Remote Config & Analytics"]
    end

    V1 -->|User actions / Watch state| VM1
    V1 -->|User actions / Watch state| VM2
    V1 -->|User actions / Watch state| VM3
    V1 -->|User actions / Watch state| VM4

    VM1 -->|Invoke async ops| S1
    VM2 -->|Query data| S2
    VM3 -->|Validate & Save| S3
    VM3 -->|Fetch thresholds| S5
    VM4 -->|Fetch remote info| S5

    VM1 -.->|Updates state with| M3
    VM2 -.->|Updates state with| M1
    VM3 -.->|Updates state with| M2
    VM3 -.->|Updates state with| M4

    S1 --> FB1
    S2 --> FB2
    S3 --> FB2
    S4 --> FB3
    S5 --> FB4
    S6 --> FB4
```

---

## 3. Sơ đồ tuần tự cho Luồng Lập kế hoạch & Khắc phục Xung đột (Sequence Diagram)

Mô tả luồng từ khi người dùng thêm môn học, hệ thống phát hiện quá tải $\to$ khắc phục đổi môn $\to$ lưu kế hoạch và xuất PDF.

```mermaid
sequenceDiagram
    autonumber
    actor User as Sinh viên
    participant UI as PlanAnalyzerScreen (SCR-06A/B)
    participant VM as PlanAnalyzerViewModel
    participant RCS as RemoteConfigService
    participant PS as PlanService (Firestore)
    participant PDF as PdfReportService
    participant ST as Storage / Device

    User->>UI: Mở màn hình Phân tích kế hoạch
    UI->>VM: analyzeWorkload(selectedCourses)
    VM->>RCS: getMaxSafeWorkloadHours()
    RCS-->>VM: Trả về ngưỡng 25 giờ
    VM->>VM: Tính tổng giờ = 34h (>25h) & check tiên quyết
    VM-->>UI: Cập nhật State: OverloadWarning (34h) + Conflict (IAE201)
    UI-->>User: Hiển thị Banner đỏ ⚠️ và khóa nút Lưu

    User->>UI: Bấm [⇄ Đổi môn khác] (chọn PRM323)
    UI->>VM: replaceCourse(from: IAE201, to: PRM323)
    VM->>VM: Tính lại tổng giờ = 26h, hết vi phạm
    VM-->>UI: Cập nhật State: Balanced (26h) & Resolved
    UI-->>User: Mở khóa nút "Lưu Kế Hoạch Học Tập" (Màu xanh)

    User->>UI: Bấm "Lưu Kế Hoạch Học Tập"
    UI->>VM: savePlan()
    VM->>PS: saveStudyPlan(uid, plan)
    PS-->>VM: Thành công
    VM-->>UI: Điều hướng sang SCR-07 (Summary)

    User->>UI: Bấm "Xuất PDF Kế Hoạch A4"
    UI->>PDF: generateAndUploadReport(plan)
    PDF->>ST: Tạo file PDF A4 chuẩn & lưu bộ nhớ máy
    PDF-->>UI: Trả về trạng thái hoàn thành & mở hộp thoại xem/in
```

---

## 4. Bảng phân công ViewModels và Services (ViewModels & Injected Services)

| Tên ViewModel | Trách nhiệm chính | Các Services được Inject |
|:---|:---|:---|
| `AuthViewModel` | Quản lý trạng thái đăng nhập Google, phiên làm việc, phân quyền người dùng | `AuthService`, `AnalyticsCrashlyticsService` |
| `HomeViewModel` | Cung cấp dữ liệu trọng tâm tuần 8, các mẹo học tập, tiến độ tín chỉ | `StudentService`, `RemoteConfigService` |
| `CourseCatalogViewModel` | Tìm kiếm môn, lọc theo chuyên ngành, quản lý trạng thái loading/empty | `CourseService`, `AnalyticsCrashlyticsService` |
| `CourseDetailViewModel` | Cung cấp chi tiết môn, cấu trúc điểm 40/30/30, lựa chọn mục tiêu điểm | `CourseService` |
| `PlanAnalyzerViewModel` | Tính toán số giờ tự học, kiểm tra điều kiện tiên quyết, khóa/mở nút Lưu | `PlanService`, `RemoteConfigService`, `AnalyticsCrashlyticsService` |
| `SemesterSummaryViewModel` | Tổng hợp KPI kế hoạch kỳ học, kích hoạt xuất bản PDF A4 | `PlanService`, `PdfReportService` |
| `ProfileViewModel` | Quản lý thiết lập thông báo, trạng thái Remote Config, hành động Đăng xuất | `AuthService`, `RemoteConfigService` |
