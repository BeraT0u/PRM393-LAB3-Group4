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

### 🌟 Các Tính Năng Nâng Cao Nổi Bật:
1. **Hệ thống 3 Persona Định Danh & Onboarding Tài Khoản Mới**:
   - Hỗ trợ 3 tài khoản mẫu với kịch bản riêng: Trần Hoàng Long (Xung đột quá tải 34h $\to$ 26h), Nguyễn Mai Linh (Kỳ tốt nghiệp 125/145 TC, GPA 3.82), Lê Minh Tuấn (Năm 2, nguy cơ học vụ 38h).
   - Tài khoản Google mới chưa định danh sẽ khởi tạo Hồ sơ Rỗng, app chủ động hiển thị thông báo yêu cầu thiết lập hồ sơ và bổ sung môn đã học.
2. **Tự Quản Lý & Chỉnh Sửa Hồ Sơ Cá Nhân (Profile Settings)**:
   - Cho phép sinh viên tự setup Họ tên, Mã sinh viên, Ảnh đại diện (hoặc đồng bộ Google), và GPA mục tiêu trực tiếp từ màn hình Cá nhân (`SCR-08`).
3. **Nghiệm Thu Kỳ Học ("Đã Hoàn Thành Kỳ Học")**:
   - Tại màn hình Tổng kết (`SCR-07`), nút "Đã hoàn thành kỳ học" tự động lưu toàn bộ môn trong kỳ vào danh mục `completed_courses`, cộng dồn số tín chỉ tích lũy và cập nhật tiến độ tốt nghiệp.
4. **Tự Khai Báo Môn Đã Học Theo Kỳ Với 2 Tầng Ràng Buộc (SCR-03)**:
   - Sinh viên bắt đầu dùng app có thể tự add các môn đã hoàn thành ở các kỳ trước.
   - **Ràng buộc tiến trình kỳ học**: Kỳ 2 phải có Kỳ 1 (chỉ được thêm Kỳ $N$ khi Kỳ $1 \dots N-1$ đã có dữ liệu).
   - **Ràng buộc môn tiên quyết**: Môn thêm vào Kỳ $N$ bắt buộc phải có các môn tiên quyết nằm trong danh sách các môn đã hoàn thành ở các kỳ trước đó ($< N$).

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


## 📋 6. Bảng liên kết tài liệu chuyển giao (Deliverables Matrix)

| Giai đoạn (Stage) | Tài liệu chuyển giao | Mô tả nội dung & Quy chuẩn đề cương | Trạng thái |
|:---|:---|:---|:---:|
| **Stage 1: Traceability** | [docs/design-traceability.md](file:///H:/Study/2026_fall/PRM392/Lab3/docs/design-traceability.md) | Ánh xạ toàn bộ 9 màn hình và 3 flows từ Figma sang Flutter | ✅ Hoàn thành |
| **Stage 2: Architecture** | [docs/architecture.md](file:///H:/Study/2026_fall/PRM392/Lab3/docs/architecture.md) | Kiến trúc MVVM, Riverpod DI, Mermaid Sequence diagrams | ✅ Hoàn thành |
| **Stage 5: Instrumentation** | [docs/analytics-plan.md](file:///H:/Study/2026_fall/PRM392/Lab3/docs/analytics-plan.md) | Kế hoạch 8 sự kiện Firebase Analytics & cam kết Zero-PII | ✅ Hoàn thành |
| **Stage 6: Test Plan & E2E** | [docs/test-plan.md](file:///H:/Study/2026_fall/PRM392/Lab3/docs/test-plan.md) | 12 ca kiểm thử E2E (Happy, Error, Native) & ARTEMIS pass rate | ✅ Hoàn thành |
| **Stage 7: AI Code Review** | [docs/code-review.md](file:///H:/Study/2026_fall/PRM392/Lab3/docs/code-review.md) | Báo cáo đánh giá mã nguồn AI (8 findings, 6 accepted, 1 rejected) | ✅ Hoàn thành |
| **Hệ thống Web Admin** | [Resource/EduPlan-system-spec.md](file:///H:/Study/2026_fall/PRM392/Lab3/Resource/EduPlan-system-spec.md) | Đặc tả hệ thống đồng bộ Mobile & Web Admin Portal | ✅ Hoàn thành |
| **Slide tiếng Việt** | [Resource/EduPlan-Presentation.pptx](file:///H:/Study/2026_fall/PRM392/Lab3/Resource/EduPlan-Presentation.pptx) | Slide thuyết trình 25 trang chuẩn 16:9 (Tiếng Việt) | ✅ Hoàn thành |
| **Slide tiếng Anh** | [Resource/EduPlan-Presentation-EN.pptx](file:///H:/Study/2026_fall/PRM392/Lab3/Resource/EduPlan-Presentation-EN.pptx) | Slide thuyết trình 25 trang chuẩn 16:9 (Tiếng Anh) | ✅ Hoàn thành |

---

## 🤖 7. Danh mục công cụ AI sử dụng (AI Tools Disclosure)

Tuân thủ quy định tại **Section 8.5 & 11 (Academic Integrity)** của Đề cương Lab 3:

| Tên công cụ | Đơn vị & Phiên bản | Mục đích & Phạm vi sử dụng |
|:---|:---|:---|
| **Google Gemini API** | Google DeepMind (`gemini-3.8-flash` / `gemini-2.5-flash`) | Cố vấn học tập thông minh (AI Study Advisor) & tối ưu hóa tải học kỳ. |
| **DeepSeek API** | DeepSeek (`deepseek-chat` DeepSeek V3) | Cơ chế AI Fallback tự động khi Gemini API hết quota hoặc sự cố mạng. |
| **CodeRabbit AI** | CodeRabbit v2.4 (PR Reviewer) | Rà soát tự động Pull Request, phát hiện rò rỉ secret key và Zero-PII. |
| **GitHub Copilot** | Microsoft / GitHub | Gợi ý cú pháp mã nguồn và sinh dữ liệu kiểm thử test fixtures. |
| **Antigravity Agent** | Google DeepMind | Phân tích mã nguồn, kiểm tra lint, chuẩn hóa tài liệu và sinh slide thuyết trình. |

---

## 🎥 8. Video Demo & Báo cáo cuối kỳ
* **Demo Video Link**: *(Cập nhật đường link YouTube/Google Drive khi nộp)*
* **Slide Presentation**: Nằm trong thư mục `slides/Lab03_SE180504_slides.pdf` và `Resource/EduPlan-Presentation.pptx`
* **Final Report**: Nằm trong thư mục `report/Lab03_SE180504.pdf`