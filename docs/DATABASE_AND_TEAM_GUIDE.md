# 👥 EduPlan — Hướng Dẫn Cài Đặt Dự Án & Kiến Trúc Database Cho Thành Viên Nhóm

> **Dành cho tất cả thành viên nhóm PRM393**: Hướng dẫn chi tiết từ A-Z để clone mã nguồn, cài đặt môi trường, hiểu rõ kiến trúc Cloud Firestore/Storage và chạy ứng dụng thành công 100% trên máy cá nhân mà không gặp bất kỳ lỗi xung đột nào.

---

## 🚀 0. Repository Dự Án & Quy Trình Git Bắt Buộc

* **GitHub Repository**: `https://github.com/BeraT0u/PRM393-LAB3-Group4.git`
* **Clone dự án**:
  ```bash
  git clone https://github.com/BeraT0u/PRM393-LAB3-Group4.git
  cd PRM393-LAB3-Group4
  flutter pub get
  ```
* **Bảng phân công Task & Use Cases**: [Link Google Sheets](https://docs.google.com/spreadsheets/d/1ynbjXKlnqcOq6BBKju1T5mV6T_nXMNInXkqCTdHWlQc/edit?usp=sharing)
* **Quy tắc làm việc**:
  1. Nhận Use Case trên Google Sheets $\to$ Tạo branch mới để code.
  2. Commit message theo đúng quy tắc: `[NgayThangNam][Ten] Chức năng` (Ví dụ: `[03/10/2026][SonNT] made UC-21 & UC-22`).
  3. Merge vào nhánh `main` và chịu trách nhiệm giải quyết conflict (nếu có).
  4. Sau khi merge thành công, cập nhật trạng thái `Đã commit`, điền tên và ngày hoàn thành lên Google Sheets.

---

## 📌 1. Yêu cầu môi trường phát triển (Prerequisites)

Mỗi thành viên cần cài đặt sẵn trên máy:
* **Flutter SDK**: Phiên bản `3.24.x` trở lên (Khuyến nghị stable `3.47.x`).
* **Dart SDK**: `3.13.x` trở lên (đi kèm với Flutter).
* **Java Development Kit (JDK)**: **JDK 17** (Bắt buộc cho Gradle 8+ và Android build).
* **IDE**: Android Studio / VS Code (đã cài extension *Flutter* và *Dart*).
* **Thiết bị chạy thử**: Thiết bị thật Android (bật USB Debugging), Android Emulator, hoặc chạy nhanh trên **Google Chrome** (`-d chrome`) / **Windows Desktop** (`-d windows`).

---

## 🔑 2. Cấu hình Firebase & Đăng nhập Google dùng chung cho nhóm

Dự án đã được cấu hình sẵn để **tất cả thành viên dùng chung 1 backend Firebase duy nhất**, không cần mỗi người phải tự tạo project Firebase riêng:

1. **File cấu hình đã có sẵn**:
   * File [`android/app/google-services.json`](../android/app/google-services.json) đã được cấu hình cho project `prm393-eduplan` với `applicationId`: `com.eduplan.app`.
2. **Khóa ký Debug dùng chung (Shared Keystore) — RẤT QUAN TRỌNG**:
   * Thông thường trong Flutter, mỗi máy tính sẽ tự sinh một file `debug.keystore` riêng với mã SHA-1 khác nhau $\to$ dẫn đến việc máy Leader chạy được Google Sign-In nhưng máy thành viên khác bị lỗi `ApiException 10`.
   * **Giải pháp đã tích hợp**: Repo đã lưu sẵn file [`android/app/debug.keystore`](../android/app/debug.keystore) và cấu hình Gradle tự động dùng file này.
   * 👉 **Kết quả**: Bất kỳ thành viên nào clone repo về và nhấn "Tiếp tục với Google" đều sẽ hoạt động trơn tru 100%, không cần phải lấy SHA-1 hay gửi email cấu hình gì thêm!

---

## 🗄️ 3. Chi tiết Kiến trúc Cơ sở Dữ liệu (Cloud Firestore)

Ứng dụng kết nối với Cloud Firestore (`prm393-eduplan`) đặt tại vị trí `asia-southeast1` (Singapore).

### 3.1. Các Collection chính trong Database

| Collection Name | Document ID | Mục đích & Dữ liệu lưu trữ |
|:---|:---|:---|
| **`courses`** | Mã môn (VD: `PRM393`) | Danh mục toàn bộ các môn học: số tín chỉ, độ khó, giờ tự học mặc định, tỷ trọng điểm 40/30/30, mẹo học tập, và mã môn tiên quyết. |
| **`students`** | `uid` của sinh viên | Hồ sơ cá nhân: Họ tên, MSSV, tiến độ tích lũy tín chỉ (`90/145`), GPA hiện tại (`3.42`), danh sách môn đã Pass (`PRO192`, `MAD101`...), và cài đặt thông báo. |
| **`study_plans`**| `{uid}_{semester}` | Kế hoạch học tập từng kỳ của sinh viên: danh sách môn đã chọn, tổng giờ tự học, trạng thái quá tải (`isOverloaded`), link file PDF tải về. |

### 3.2. Cơ chế Tự động Nạp Dữ liệu Mẫu (Database Seeder)
* Source code: [`lib/services/database_seeder.dart`](../lib/services/database_seeder.dart)
* **Cách hoạt động**:
  * Khi ứng dụng khởi chạy, hệ thống sẽ tự động kiểm tra xem Firestore có môn học nào chưa.
  * Nếu Firestore đang trống, app sẽ tự động nạp **7 môn học chuẩn theo Figma**:
    1. `PRM393` (Lập trình Di động — 3 TC, tiên quyết `PRO192` ✅)
    2. `SWE302` (Kiến trúc Phần mềm — 3 TC, tiên quyết `CSD201` ✅)
    3. `AIE411` (AI Ứng dụng — 3 TC, tiên quyết `MAS291` ✅)
    4. `IAE201` (An toàn Thông tin — 3 TC, tiên quyết `NWC203` ❌ **Môn gây xung đột quá tải 34h**)
    5. `PRM323` (Thiết kế UI/UX — 3 TC, không tiên quyết 🟢 **Môn thay thế để gỡ xung đột, đưa tải về 26h**)
    6. `OSG209` (Hệ điều hành — 3 TC)
    7. `DBI202` (Hệ CSDL — 3 TC)
  * Thành viên nhóm không cần phải nhập tay dữ liệu lên Firebase Console!

### 3.3. Cơ chế Ngoại tuyến (Offline Fallback & Graceful Degradation)
* Nếu thành viên chạy app khi không có mạng hoặc mạng trường học chặn Firebase, **ứng dụng KHÔNG BAO GIỜ bị văng crash**.
* Hệ thống sẽ tự động dùng dữ liệu Fallback nội bộ (`DatabaseSeeder.sampleCourses`), mọi thao tác tìm kiếm, lọc, tính giờ tự học và đổi môn vẫn hoạt động hoàn hảo.

---

## ☁️ 4. Dịch vụ Lưu trữ File (Cloud Storage)

* **Bucket**: `gs://prm393-eduplan.firebasestorage.app` (Đã nâng cấp gói Blaze).
* **Quy chuẩn lưu trữ**: Mỗi khi sinh viên bấm xuất PDF A4, file sẽ được tải lên theo đường dẫn cô lập:
  ```text
  reports/{userId}/EduPlan_Blueprint_{timestamp}.pdf
  ```
* **Bảo mật**: File [`firebase/storage.rules`](../firebase/storage.rules) đã được thiết lập để sinh viên chỉ có quyền đọc/ghi file trong chính thư mục mang UID của mình.

---

## ⚡ 5. Hướng dẫn các bước chạy dự án trên máy thành viên

Sau khi clone repo về máy, thành viên nhóm mở Terminal tại thư mục gốc của dự án và chạy các lệnh sau:

### Bước 1: Tải các thư viện phụ thuộc
```bash
flutter pub get
```

### Bước 2: Chạy kiểm tra tĩnh (đảm bảo không có lỗi code)
```bash
dart analyze lib test
```
*(Đảm bảo xuất hiện thông báo `No issues found!`)*

### Bước 3: Chạy Unit/Widget test
```bash
flutter test
```
*(Đảm bảo xuất hiện `All tests passed!`)*

### Bước 4: Khởi chạy ứng dụng
* **Chạy trên thiết bị Android đang cắm dây hoặc giả lập**:
  ```bash
  flutter run
  ```
* **Chạy nhanh trên Google Chrome** *(Rất tiện khi chưa mở máy ảo Android)*:
  ```bash
  flutter run -d chrome
  ```
* **Chạy trên Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

---

## 📝 6. Quy tắc Đặt tên Git Commit Message (BẮT BUỘC TOÀN NHÓM)

Để lịch sử Git của nhóm đồng bộ và đạt điểm tối đa tiêu chí đánh giá quy trình làm việc:
Mọi commit bắt buộc phải theo đúng định dạng:

```text
[NgayThangNam][TenThanhVien] Chức năng đã làm
```

* **`[NgayThangNam]`**: Ngày/Tháng/Năm theo định dạng `DD/MM/YYYY`.
* **`[TenThanhVien]`**: Tên của bạn (VD: `[TrongHieu]`, `[MinhTuan]`, `[HoangLong]`).
* **Ví dụ mẫu**:
  * `[28/10/2026][TrongHieu] Implement Firestore services and database seeder`
  * `[29/10/2026][MinhTuan] Build UI widgets for course card and status badge`
  * `[30/10/2026][HoangLong] Implement SCR-05 Course Detail and radio grade target`

---

## 🛠️ 7. Xử lý các lỗi thường gặp (Troubleshooting)

| Hiện tượng lỗi | Nguyên nhân | Cách khắc phục |
|:---|:---|:---|
| `Unable to locate Android SDK` | Máy chưa cài Android SDK hoặc chưa trỏ đường dẫn | Mở Android Studio $\to$ SDK Manager tải Android SDK, hoặc chạy tạm bằng `flutter run -d chrome`. |
| `Gradle build failed / lock file` | Xung đột cache Gradle cũ | Chạy lệnh `flutter clean` $\to$ `flutter pub get` rồi chạy lại. |
| `Google Sign-In canceled` | Người dùng đóng popup chọn tài khoản | Bình thường, app sẽ hiển thị thông báo hủy nhẹ nhàng chứ không crash. |
| `CocoaPods / iOS errors` | Chạy trên máy Mac chưa cài pods | Chạy lệnh `cd ios && pod install && cd ..`. |
