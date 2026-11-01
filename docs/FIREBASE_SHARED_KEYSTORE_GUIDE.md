# 🔐 EduPlan — Hướng Dẫn Kết Nối Firebase & Cơ Chế Shared Keystore Dùng Chung

> **Dành cho tất cả thành viên nhóm PRM393:** Tài liệu này giải thích chi tiết cơ chế khóa ký dùng chung (Shared Keystore) giúp các thành viên kết nối thẳng tới Firebase và Google Sign-In mà **KHÔNG CẦN** phải lấy mã SHA-1 riêng của từng máy để thêm vào Firebase Console.

---

## ❓ Câu Hỏi Thường Gặp: "Máy em có cần lấy mã SHA-1 gửi Leader không?"

👉 **CÂU TRẢ LỜI: KHÔNG CẦN.**

Dự án EduPlan đã được cấu hình sẵn cơ chế **Shared Keystore** ngay trong kho mã nguồn Git. Mọi máy tính khi clone dự án về và chạy đều sẽ tự động tạo ra cùng một mã định danh chứng thực (SHA-1) duy nhất đã được đăng ký sẵn trên Firebase.

---

## 💡 1. Tại Sao Lại Không Cần SHA-1 Của Từng Máy?

### 1.1. Vấn đề thường gặp khi làm việc nhóm với Firebase
* Trong quy trình mặc định của Android / Flutter, mỗi khi cài đặt Android SDK trên máy tính cá nhân, hệ điều hành sẽ tự động tạo ngẫu nhiên một file `debug.keystore` riêng tại thư mục:
  * Windows: `C:\Users\<Tên_User>\.android\debug.keystore`
  * macOS / Linux: `~/.android/debug.keystore`
* Do mỗi máy có một file keystore khác nhau $\to$ mã vân tay **SHA-1** của mỗi máy sẽ hoàn toàn khác nhau.
* Nếu Leader chỉ add SHA-1 máy của Leader lên Firebase Console thì chỉ máy Leader đăng nhập được Google. Máy của các thành viên khác khi bấm "Đăng nhập Google" sẽ bị văng lỗi:
  ```text
  PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
  ```

---

### 1.2. Giải pháp đã tích hợp trong Repo EduPlan
Để loại bỏ hoàn toàn phiền toái trên, dự án đã thiết lập 3 thành phần đồng bộ:

1. **Lưu trữ Keystore dùng chung vào mã nguồn:**
   * File khóa ký [`android/app/debug.keystore`](../android/app/debug.keystore) đã được tạo sẵn và commit trực tiếp lên Git.
   * Thông số khóa ký:
     * **Keystore file:** `android/app/debug.keystore`
     * **Keystore password:** `android`
     * **Key alias:** `androiddebugkey`
     * **Key password:** `android`
     * **Mã SHA-1 cố định:** `FD:07:96:91:08:BF:8E:FC:4C:40:71:7E:08:F1:9C:97:46:C6:72:1A`

2. **Đăng ký sẵn SHA-1 này trên Firebase Console:**
   * Mã SHA-1 trên đã được đăng ký chính thức vào Firebase project `prm393-eduplan` (Package: `com.eduplan.app`).
   * File cấu hình [`android/app/google-services.json`](../android/app/google-services.json) trong repo đã chứa sẵn mã hash này:
     ```json
     "certificate_hash": "fd07969108bf8efc4c40717e08f19c9746c6721a"
     ```

3. **Cấu hình Gradle ép buộc dùng Shared Keystore:**
   * Tại file [`android/app/build.gradle.kts`](../android/app/build.gradle.kts), cấu hình signing đã được chỉ định rõ:
     ```kotlin
     signingConfigs {
         getByName("debug") {
             storeFile = file("debug.keystore")
             storePassword = "android"
             keyAlias = "androiddebugkey"
             keyPassword = "android"
         }
     }

     buildTypes {
         release {
             signingConfig = signingConfigs.getByName("debug")
         }
         debug {
             signingConfig = signingConfigs.getByName("debug")
         }
     }
     ```

🎯 **Kết quả:** Bất kể bạn dùng máy Windows, Mac hay Linux, khi chạy lệnh `flutter run`, Gradle sẽ dùng chính file `debug.keystore` trong repo này để ký app. Firebase sẽ nhận diện app của bạn hợp lệ 100%.

---

## 🚀 2. Hướng Dẫn Kết Nối & Chạy Ứng Dụng Trên Máy Thành Viên

Các thành viên chỉ cần thực hiện 4 bước tiêu chuẩn sau:

### Bước 1: Kéo mã nguồn mới nhất từ GitHub
Mở Terminal / PowerShell trên máy của bạn và chạy:
```bash
git clone https://github.com/BeraT0u/PRM393-LAB3-Group4.git
cd PRM393-LAB3-Group4
```
*(Nếu bạn đã clone từ trước, hãy chạy `git pull` để nhận đầy đủ các file cấu hình mới nhất).*

---

### Bước 2: Kiểm tra các file cấu hình bắt buộc
Đảm bảo thư mục `android/app/` trên máy bạn có đủ 3 file sau:
* ✅ `android/app/google-services.json` (File kết nối Firebase)
* ✅ `android/app/debug.keystore` (File khóa ký dùng chung)
* ✅ `android/app/build.gradle.kts` (Script cấu hình Gradle)

---

### Bước 3: Cài đặt thư viện dependencies
Chạy lệnh sau tại thư mục gốc của dự án:
```bash
flutter pub get
```

---

### Bước 4: Khởi động thiết bị & Chạy app
1. Mở **Android Emulator** (khuyến nghị máy ảo Pixel chạy Android 12 trở lên có sẵn Google Play Store). Hoặc cắm điện thoại thật Android (bật USB Debugging).
2. Đảm bảo thiết bị của bạn có kết nối Internet / WiFi.
3. Chạy lệnh:
   ```bash
   flutter run
   ```
4. Khi app mở lên màn hình SCR-01 (Đăng nhập):
   * Nhấn nút **"Đăng nhập bằng Google"**.
   * Chọn tài khoản Google của bạn $\to$ App sẽ xác thực thành công và tự động chuyển vào màn hình Trang chủ (`HomeScreen`).
   * Dữ liệu môn học, hồ sơ sinh viên sẽ được đọc/ghi trực tiếp từ Cloud Firestore (`prm393-eduplan`).

---

## 🛠️ 3. Xử Lý Sự Cố (Troubleshooting & FAQ)

### TH 1: Bấm đăng nhập Google bị xoay vòng rồi báo lỗi `ApiException 10`
* **Nguyên nhân:** Máy ảo của bạn chưa đăng nhập tài khoản Google Play Store, hoặc Gradle chưa nhận đúng keystore.
* **Cách khắc phục:**
  1. Mở máy ảo Android $\to$ Vào ứng dụng **Google Play Store** $\to$ Đăng nhập một tài khoản Google bất kỳ vào máy ảo trước.
  2. Dọn dẹp cache Gradle và chạy lại:
     ```bash
     cd android
     ./gradlew clean
     cd ..
     flutter clean
     flutter pub get
     flutter run
     ```

---

### TH 2: Muốn kiểm tra xem máy mình đang dùng mã SHA-1 nào
Mở Terminal tại thư mục dự án và gõ:
```bash
cd android
./gradlew signingReport
```
* Cuộn tìm mục `Variant: debug` $\to$ Kiểm tra dòng `SHA1:`.
* Nếu hiển thị: `FD:07:96:91:08:BF:8E:FC:4C:40:71:7E:08:F1:9C:97:46:C6:72:1A` tức là máy bạn đã ăn đúng keystore của nhóm.
* Trong trường hợp đặc biệt hiển thị mã khác (do máy bạn ghi đè biến môi trường), hãy copy mã SHA-1 đó gửi cho Leader để thêm vào Firebase Console dự phòng.

---

### TH 3: Không có kết nối mạng thì app có chạy được không?
* **Có.** Ứng dụng EduPlan đã được tích hợp cơ chế Offline Fallback an toàn. Nếu không có internet hoặc Firebase chưa kết nối được, hệ thống sẽ tự động dùng dữ liệu nạp sẵn từ `DatabaseSeeder` để không bao giờ bị crash app. Tuy nhiên, để test tính năng lưu trữ Firestore và đồng bộ đa người dùng thì cần có mạng internet.
