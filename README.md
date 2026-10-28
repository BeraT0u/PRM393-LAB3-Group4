# 📌 QUY TRÌNH LÀM VIỆC NHÓM & QUY TẮC COMMIT TRÊN GIT (BẮT BUỘC)

> Sau khi hoàn thiện chức năng UC trong link [Google Sheets Quản lý Task & Use Cases](https://docs.google.com/spreadsheets/d/1ynbjXKlnqcOq6BBKju1T5mV6T_nXMNInXkqCTdHWlQc/edit?usp=sharing) thì hãy push code lên git lên 1 nhánh mới kèm message theo rule:

## Rule đặt tên commit

```text
[NgayThangNam][Ten] Chức năng
```

* **Ví dụ**: `[03/10/2026][SonNT] made UC-21 & UC-22`
* Và sau đó merge vào nhánh `main`, phải tự chịu trách nhiệm merge và tránh conflict khi merge.
* Sau khi đã commit và merge thành công quay lại link task và cập nhật trạng thái **đã commit** cùng với điền **tên** và **ngày hoàn thành** vào đúng UC đó.

---

# 🎓 EduPlan — Course Planner & Study Strategy Edition
### PRM393 — Lab 3: Cloud-Enabled Mobile App (Firebase, Google ARTEMIS, AI Code Review)

> **Họ và tên**: Nguyễn Trọng Hiếu (Persona thiết kế: Trần Hoàng Long — MSSV: SE180504)  
> **Môn học**: PRM393 — Lập trình Di động (Mobile Programming)  
> **Chủ đề**: Lập kế hoạch học tập thông minh, chiến lược phân bổ môn học & tối ưu hóa khối lượng tự học theo tín chỉ  
> **Phong cách thiết kế**: Warm Paper Academic (Canvas `#FBF6EB`, font Inter, chuẩn giao diện 390 × 800 dp)  

---

## 📌 1. Giới thiệu tổng quan dự án (Project Overview)

> 📖 **HƯỚNG DẪN DÀNH CHO THÀNH VIÊN NHÓM**: Xem chi tiết tại [docs/DATABASE_AND_TEAM_GUIDE.md](file:///H:/Study/2026_fall/PRM392/Lab3/docs/DATABASE_AND_TEAM_GUIDE.md) để biết cách clone code, cấu hình Firebase dùng chung và khởi chạy app thành công trên mọi máy tính.

**EduPlan** là ứng dụng di động hỗ trợ sinh viên lập kế hoạch học tập theo kỳ học, theo dõi tiến độ tích lũy tín chỉ tốt nghiệp, dự báo độ khó và khối lượng tự học của từng môn. Ứng dụng tích hợp hệ thống phát hiện quá tải thông minh (Workload Analyzer) nhằm cảnh báo sinh viên khi tổng giờ tự học vượt quá ngưỡng an toàn hoặc vi phạm điều kiện môn tiên quyết, đồng thời hỗ trợ xuất bản kế hoạch học tập ra định dạng tài liệu PDF A4.

---

## 🏛️ 2. Kiến trúc & Công nghệ (Architecture & Tech Stack)

* **Mô hình kiến trúc**: **MVVM (Model - View - ViewModel)** nghiêm ngặt.
  * Tầng View chỉ nhận dữ liệu từ ViewModel và gửi hành vi người dùng, không bao giờ gọi trực tiếp HTTP hay Firebase SDK.
  * Tầng ViewModel quản lý trạng thái màn hình (Sealed State: Loading, Empty, Error, Data) và kích hoạt ghi nhận sự kiện Analytics.
  * Tầng Service xử lý toàn bộ kết nối bên ngoài và được inject thông qua Dependency Injection.
* **Quản lý trạng thái (State Management)**: `flutter_riverpod: ^3.4.3`.
* **Design System**: Chuẩn Material Design 3 tùy biến theo phong cách **Warm Paper Academic**:
  * Nền Canvas giấy kem ấm chống mỏi mắt: `#FBF6EB`
  * Thẻ môn học và bề mặt: `#FFFDF7` viền hairline 1px `#EAE1D0`
  * Màu thương hiệu hành động chính: Royal Blue `#2563EB`
  * Typography: `Inter` hỗ trợ 100% tiếng Việt với font tabular cho số giờ và điểm.
* **Đám mây & Dịch vụ Firebase**:
  * **Firebase Authentication**: Đăng nhập bằng tài khoản Google (OAuth 2.0).
  * **Cloud Firestore**: Lưu trữ danh mục môn học (`courses`), lịch sử học tập (`completed_courses`), và kế hoạch học kỳ (`study_plans`).
  * **Firebase Remote Config**: Đồng bộ ngưỡng tự học an toàn (`max_safe_workload_hours`: 25) và cờ bật/tắt mẹo học tập (`enable_study_tips`: true).
  * **Firebase Analytics**: Thu thập 8 sự kiện đo lường hành vi người dùng phục vụ phân tích sản phẩm.
  * **Firebase Crashlytics**: Bắt lỗi có xử lý (handled error) và theo dõi độ ổn định ứng dụng.
  * **Cloud Storage & Security Rules**: Quy chuẩn bảo mật thư mục cô lập theo từng người dùng `/reports/{uid}/...`.

---

## 📂 3. Sơ đồ cây thư mục & Vị trí các tài liệu nộp bài (Deliverables Map)

```text
PRM393_Lab3/
├── README.md                           # Bản mô tả tổng quan dự án và hướng dẫn chạy app
├── pubspec.yaml                        # Danh sách dependencies đã pin phiên bản
├── android/                            # Cấu hình Android & google-services.json
│   └── app/google-services.json
├── firebase/
│   ├── storage.rules                   # Quy tắc bảo mật phân quyền theo per-user path
│   └── remote-config-defaults.json     # Giá trị mặc định in-app của Remote Config
├── docs/
│   ├── DATABASE_AND_TEAM_GUIDE.md      # Hướng dẫn chi tiết cài đặt và database cho thành viên nhóm
│   ├── design-traceability.md          # Stage 1: Bảng ma trận ánh xạ 9 màn hình và 3 flows
│   ├── architecture.md                 # Stage 2: Bản vẽ kiến trúc MVVM, Mermaid diagrams
│   ├── analytics-plan.md               # Stage 5: Bảng kế hoạch 8 sự kiện đo lường Analytics
│   ├── test-plan.md                    # Stage 6: Kịch bản kiểm thử E2E tự động
│   └── code-review.md                  # Stage 7: Báo cáo đánh giá mã nguồn bằng AI
├── lib/
│   ├── firebase/                       # Tầng khởi tạo & bao bọc Firebase SDK
│   ├── models/                         # Dữ liệu thực thể (Course, Plan, StudentProfile)
│   ├── services/                       # Dịch vụ gọi dữ liệu, tạo PDF, xác thực
│   ├── theme/                          # Design tokens (Colors, Typography, Dimens, Theme)
│   ├── utils/                          # Hàm tiện ích định dạng số, tiền tệ, logger
│   ├── viewmodels/                     # Logic nghiệp vụ & quản lý State
│   ├── widgets/                        # Components UI tái sử dụng (Button, Card, Badge)
│   ├── screens/                        # Toàn bộ 9 màn hình (SCR-01 đến SCR-08)
│   └── main.dart                       # Entry point của ứng dụng Flutter
├── assets/
│   └── images/logo.png                 # Logo EduPlan Master
├── report/                             # File báo cáo PDF cuối kỳ
│   └── Lab03_SE180504.pdf
└── slides/                             # Slide thuyết trình PDF
    └── Lab03_SE180504_slides.pdf
```

---

## 🚀 4. Hướng dẫn cài đặt & Khởi chạy (How to Run)

### Yêu cầu môi trường (Prerequisites)
* Flutter SDK: `3.47.x` trở lên (Channel stable)
* Dart SDK: `3.13.x` trở lên
* Thiết bị kiểm thử: Thiết bị Android thật, Android Emulator, hoặc chạy trực tiếp trên Windows Desktop / Google Chrome.

### Các bước khởi chạy
1. **Lấy mã nguồn về máy**:
   ```bash
   git clone <repo-url>
   cd Lab3
   ```
2. **Cài đặt thư viện dependencies**:
   ```bash
   flutter pub get
   ```
3. **Chạy ứng dụng**:
   * Khởi chạy trên thiết bị đang kết nối (Android/Chrome/Windows):
     ```bash
     flutter run
     ```
   * Hoặc chỉ định rõ thiết bị:
     ```bash
     flutter run -d chrome
     flutter run -d windows
     ```

---

## 📦 5. Danh sách phiên bản thư viện đã Pin (Pinned Dependencies)

| Thư viện | Phiên bản | Mục đích sử dụng |
|:---|:---|:---|
| `flutter_riverpod` | `^3.4.3` | Quản lý trạng thái MVVM & Dependency Injection |
| `firebase_core` | `^5.1.0` | Khởi tạo nền tảng kết nối Firebase |
| `firebase_auth` | `^7.0.1` | Xác thực đăng nhập Google Sign-In |
| `cloud_firestore` | `^7.1.0` | Cơ sở dữ liệu Cloud NoSQL cho môn học & kế hoạch |
| `firebase_storage` | `^14.0.1` | Quản lý tải lên file PDF báo cáo |
| `firebase_analytics`| `^13.0.1` | Đo lường 8 sự kiện tương tác người dùng |
| `firebase_crashlytics`| `^6.0.1` | Báo cáo ngoại lệ và độ ổn định |
| `firebase_remote_config`| `^7.0.1` | Cấu hình động ngưỡng giờ tự học và Study tips |
| `google_fonts` | `^9.0.0` | Bộ phông chữ Inter chuẩn thiết kế |
| `pdf` & `printing` | `^3.13.1` / `^5.15.1` | Tạo bản vẽ PDF kế hoạch khổ A4 và kích hoạt In |
| `shimmer` | `^4.0.0` | Hiệu ứng tải dữ liệu khung xương (Skeleton loader) |
| `intl` | `^0.20.3` | Định dạng tiền tệ VND, thời gian và số liệu |

---

## 📹 6. Video Demo & Báo cáo
* **Demo Video Link**: *(Sẽ cập nhật đường link YouTube/Drive tại đây)*
* **Slide Presentation**: Nằm trong thư mục `slides/Lab03_SE180504_slides.pdf`
* **Final Report**: Nằm trong thư mục `report/Lab03_SE180504.pdf`
