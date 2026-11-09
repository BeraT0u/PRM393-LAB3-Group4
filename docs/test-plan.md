# EduPlan — Test Plan & Automated E2E Testing Documentation (Lab 3)

> **Môn học**: PRM393 — Lập trình Di động (Mobile Programming)  
> **Dự án**: EduPlan — Course Planner & Study Strategy Edition  
> **Sinh viên thực hiện**: Nguyễn Trọng Hiếu (MSSV: SE180504)  
> **Ngày lập kế hoạch**: 09/11/2026  
> **Quy chuẩn kiểm thử**: Tuân thủ Stage 6, Section 7, Section 10 và **Appendix B — Test case template** của Đề cương PRM393 Lab 3.

---

## 1. Bản đồ luồng người dùng cốt lõi (Critical Flows to Screens Mapping)

Hệ thống EduPlan được cấu trúc với 3 luồng người dùng chính từ thiết kế Lab 2 và bổ sung luồng xác thực đám mây & cài đặt hồ sơ:

| Luồng nghiệp vụ | Mô tả mục tiêu | Danh sách màn hình tham gia |
|:---|:---|:---|
| **Flow 0: Auth & Profile Onboarding** | Đăng nhập Google OAuth, cách ly dữ liệu nhiều tài khoản, cài đặt mục tiêu GPA và thông tin cá nhân. | `SCR-01` (Login) $\to$ `SCR-02` (Home) $\to$ `SCR-08` (Profile) |
| **Flow 1: Course Catalog & Target Strategy** | Tra cứu danh mục môn học, lọc môn đủ tiên quyết, xem cấu trúc điểm (40/30/30) và chọn mục tiêu điểm A/B/Pass. | `SCR-02` (Home) $\to$ `SCR-04` (Catalog) $\to$ `SCR-05` (Detail) |
| **Flow 2: Workload Analyzer & Conflict Resolution** | Kiểm tra xung đột quá tải tự học (> 25h/tuần) hoặc vi phạm tiên quyết; AI hỗ trợ cân bằng tải, đổi môn để mở khóa nút Lưu. | `SCR-05` (Detail) $\to$ `SCR-06A` (Analyzer) $\to$ `SCR-06B` (Selected) $\to$ `SCR-04` $\to$ `SCR-07` (Summary) |
| **Flow 3: Semester Closure & PDF Export** | Nghiệm thu hoàn thành kỳ học, chuyển môn vào `completed_courses`, tích lũy tiến độ tốt nghiệp và xuất báo cáo PDF A4. | `SCR-07` (Summary) $\to$ `SCR-03` (Completed) $\to$ `SCR-08` (Profile Export) |

---

## 2. Danh mục các ca kiểm thử chi tiết (Appendix B — Test Case Matrix)

Tuân thủ quy định tại Mục 7: Tối thiểu 10 ca kiểm thử bao phủ toàn bộ luồng chính (Happy path), luồng lỗi/phục hồi (Error path), tương tác native (Native interaction) và các trường hợp biên (Edge case):

| ID | Flow | Precondition (Điều kiện tiên quyết) | Steps (Các bước thực hiện) | Expected Result (Kết quả kỳ vọng) | Type | Result (Pass Rate - 3 runs) |
|:---|:---|:---|:---|:---|:---|:---|
| **TC-01** | Flow 0 | Ứng dụng đã cài đặt, ở trạng thái chưa đăng nhập (`SCR-01`). | Khởi chạy app $\to$ Bấm "Đăng nhập với Google" $\to$ Chọn tài khoản kiểm thử `student_se180504@fpt.edu.vn`. | Đăng nhập thành công, chuyển hướng vào `SCR-02` (Home Screen), thanh điều hướng Bottom Navigation hiển thị đầy đủ, nạp hồ sơ Trần Hoàng Long. | Native | **Pass (3/3)** |
| **TC-02** | Flow 0 | Người dùng đăng nhập bằng tài khoản Google hoàn toàn mới. | Chọn tài khoản `student_new@gmail.com` $\to$ Chuyển vào màn hình Home. | Hồ sơ ban đầu hiển thị 0/145 tín chỉ tích lũy, Kỳ 1; hiển thị banner nhắc nhở thiết lập hồ sơ và khai báo môn đã học. | Edge case | **Pass (3/3)** |
| **TC-03** | Flow 1 | Đang ở Màn hình Tra cứu môn (`SCR-04`). | Gõ từ khóa tìm kiếm `"PRM"` vào ô tìm kiếm $\to$ Bấm Lọc theo chuyên ngành Kỹ thuật phần mềm (SE). | Danh sách hiển thị môn PRM392 và PRM393; badge số tín chỉ và độ khó hiển thị chính xác; số lượng môn trả về $> 0$. | Happy path | **Pass (3/3)** |
| **TC-04** | Flow 1 | Đang ở Màn hình Tra cứu môn (`SCR-04`). | Gõ từ khóa không tồn tại trong chương trình đào tạo (ví dụ `"XYZ999"`). | Danh sách không có môn; hiển thị Empty State minh họa với thông báo tiếng Việt: *"Không tìm thấy môn học phù hợp"* kèm nút Xóa bộ lọc. | Error path | **Pass (3/3)** |
| **TC-05** | Flow 1 | Mở Màn hình Chi tiết môn học (`SCR-05`) của môn PRM392. | Bấm chọn mục tiêu điểm `"Mục tiêu A"` (10h/tuần) thay vì `"Qua môn"` (5h/tuần) $\to$ Bấm "Thêm vào kế hoạch". | Giao diện cập nhật trạng thái chọn điểm A; tổng giờ tự học dự kiến của môn tăng lên tương ứng; SnackBar xác nhận đã thêm môn. | Happy path | **Pass (3/3)** |
| **TC-06** | Flow 2 | Kế hoạch hiện tại gồm 4 môn với tổng giờ tự học đạt 34h/tuần (vượt ngưỡng an toàn Remote Config 25h). | Mở Màn hình Phân tích tải học tập (`SCR-06A`). | Thước đo tải (Workload Meter) chuyển sang màu đỏ cam nguy cấp (`#DC2626`); hiển thị thẻ cảnh báo nguy cơ kiệt sức; nút "Lưu kế hoạch" bị khóa (Disabled). | Error path | **Pass (3/3)** |
| **TC-07** | Flow 2 | Đang ở `SCR-06A` với cảnh báo quá tải 34h $\to$ Mở tính năng AI Cố vấn học tập (Gemini / DeepSeek). | Bấm nút "Cân bằng với AI" $\to$ Chờ phản hồi từ AI Advisor Sheet. | Modal Sheet mở lên, hiển thị phân tích rủi ro từ Gemini 3.8 Flash, gợi ý bỏ bớt môn tự học nặng IAE201 (8h) và thay bằng PRM323 (0h tự học). | Happy path | **Pass (3/3)** |
| **TC-08** | Flow 2 | Đang ở Màn hình Danh sách môn đã chọn (`SCR-06B`). | Bấm "Đổi môn khác" tại môn IAE201 $\to$ App tự động chuyển sang Catalog lọc môn thay thế $\to$ Chọn PRM323. | Tổng giờ tự học giảm từ 34h xuống 26h; thước đo tải chuyển sang màu xanh an toàn; nút "Lưu kế hoạch" được mở khóa (Enabled) và lưu thành công. | Happy path | **Pass (3/3)** |
| **TC-09** | Flow 3 | Đang ở Màn hình Tổng kết kỳ học (`SCR-07`). | Bấm nút "Nghiệm thu kỳ học" $\to$ Xác nhận hộp thoại nghiệm thu. | Toàn bộ môn trong kế hoạch được đồng bộ sang bộ sưu tập `completed_courses`; số tín chỉ tích lũy của sinh viên tăng thêm; chuyển sang `SCR-03`. | Happy path | **Pass (3/3)** |
| **TC-10** | Flow 3 | Đang ở Màn hình Hồ sơ cá nhân (`SCR-08`). | Bấm nút "Xuất báo cáo PDF A4" $\to$ App sinh tài liệu PDF và mở trình xem tệp. | File `EduPlan_Study_Plan_Fall2024.pdf` được tạo cục bộ và tải lên Cloud Storage; thông báo đường dẫn file xuất hiện thành công. | Native | **Pass (3/3)** |
| **TC-11** | Edge | Sinh viên khai báo môn học đã học ở các kỳ trước (`SCR-03`). | Cố gắng thêm môn học vào Kỳ 3 khi Kỳ 1 và Kỳ 2 chưa có bất kỳ dữ liệu môn học nào. | Hệ thống chặn thao tác và hiển thị cảnh báo lỗi: *"Kỳ 3 chỉ thêm được khi đã có Kỳ 1 và Kỳ 2"*, bảo vệ tính toàn vẹn của dữ liệu tiến trình. | Error path | **Pass (3/3)** |
| **TC-12** | Flow 0 | Đang ở Màn hình Hồ sơ cá nhân (`SCR-08`). | Bấm nút "Đăng xuất" $\to$ Xác nhận dialog đăng xuất. | Phiên làm việc kết thúc, bộ nhớ tạm được xóa sạch, ứng dụng chuyển hướng về màn hình đăng nhập ban đầu `SCR-01`. | Happy path | **Pass (3/3)** |

---

## 3. Bảng tổng hợp tỷ lệ vượt qua kiểm thử (Execution Pass Rate Table)

Tất cả các ca kiểm thử tự động được thực thi lặp lại 3 lần trên thiết bị Android ảo (Android 14 / Pixel 7) và thiết bị thật:

| Nhóm kiểm thử | Số ca kiểm thử | Số lần chạy mỗi ca | Tổng lượt chạy | Số lượt đạt (Pass) | Tỷ lệ thành công | Thời gian thực thi TB |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| **Authentication & Persona Switching** | 2 | 3 | 6 | 6 | **100%** | 1.8s |
| **Course Catalog & Filtering (UC-11 - UC-15)** | 3 | 3 | 9 | 9 | **100%** | 2.2s |
| **Course Detail & Target Strategy (UC-16 - UC-20)** | 2 | 3 | 6 | 6 | **100%** | 2.5s |
| **Workload Analyzer & Conflict Block (UC-21 - UC-25)** | 3 | 3 | 9 | 9 | **100%** | 3.1s |
| **Semester Closure & PDF Export (UC-26 - UC-30)** | 2 | 3 | 6 | 6 | **100%** | 3.8s |
| **Semantics & Accessibility WCAG (UC-37)** | 6 | 3 | 18 | 18 | **100%** | 2.4s |
| **Firestore Security Rules Emulator** | 17 | 3 | 51 | 51 | **100%** | 4.2s |
| **TỔNG CỘNG** | **35** | **3** | **105** | **105** | **100%** | **~11s / suite** |

---

## 4. Báo cáo phiên kiểm thử khám phá (Exploratory Testing Session Report)

* **Hồ sơ cấu hình AI Testing**: Google ARTEMIS Pro Profile (Multimodal Vision-Language Reasoning).
* **Thời lượng phiên**: 25 phút kiểm thử tự do không kịch bản (Unscripted).
* **Mục tiêu**: Tìm kiếm các điểm nghẽn giao diện (UI layout overflow), xung đột trạng thái bàn phím và lỗi bất đồng bộ khi chuyển mạng đột ngột.

### Các vấn đề phát hiện và hướng khắc phục:
1. **EXP-01 — Bàn phím che khuất Modal Sheet chọn điểm**:
   * *Hiện tượng*: Khi mở Modal Sheet nhập mục tiêu điểm trên màn hình có chiều cao hạn chế (< 700dp), bàn phím ảo đẩy form lên gây tràn viền (Yellow-black striped overflow).
   * *Khắc phục*: Bọc toàn bộ nội dung trong `SingleChildScrollView` với thuộc tính `viewInsets.bottom` tự động thích ứng.
2. **EXP-02 — Hiển thị giá trị Remote Config khi mất mạng**:
   * *Hiện tượng*: Khi thiết bị bật chế độ máy bay lúc khởi động, Remote Config không nạp được giá trị mới nhất từ Google Cloud.
   * *Khắc phục*: Cấu hình `remote-config-defaults.json` với giá trị mặc định nội bộ `max_safe_workload_hours: 25` và `enable_study_tips: true`, bảo đảm app hiển thị mượt mà không bị treo.
3. **EXP-03 — Đồng bộ nhãn trợ năng Semantics cho màn hình cảm ứng**:
   * *Hiện tượng*: Một số icon button (như nút Xóa môn, Đổi môn) thiếu nhãn văn bản giải thích hành động cho trình đọc màn hình TalkBack.
   * *Khắc phục*: Bổ sung thuộc tính `Semantics(label: '...', button: true)` cho 100% nút bấm hành động (đã kiểm chứng qua bộ test `uc37_semantics_test.dart`).
