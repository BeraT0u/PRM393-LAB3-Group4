# EduPlan — AI-Assisted Code Review Report (Lab 3)

> **Môn học**: PRM393 — Lập trình Di động (Mobile Programming)  
> **Dự án**: EduPlan — Course Planner & Study Strategy Edition  
> **Sinh viên thực hiện**: Nguyễn Trọng Hiếu (MSSV: SE180504)  
> **Ngày báo cáo**: 09/11/2026  
> **Quy chuẩn đánh giá**: Tuân thủ Stage 7, Section 8, Section 10 và **Appendix C — Code review record template** của Đề cương PRM393 Lab 3.

---

## 1. Tổng quan & Phương pháp đánh giá (Review Methodology & Scope)

Theo yêu cầu của **Đề cương Lab 3 (Mục 8 & 11)**:
* Quá trình Review mã nguồn được thực hiện qua hình thức **Pull Request Review** trên nhánh tính năng `feature/ai-advisor-and-workload-optimization` và toàn bộ các tầng kiến trúc `lib/` (MVVM) trước khi merge vào nhánh chính.
* Các công cụ AI Review được tích hợp: **Gemini 3.8 Flash Code Review**, **CodeRabbit AI**, **GitHub Copilot Code Review**, và **SonarCloud static analyzer**.
* Phạm vi quét mã nguồn:
  * **Tầng Giao diện (Screens & Widgets)**: Kiểm tra vi phạm gọi SDK/HTTP trực tiếp, rò rỉ BuildContext, rebuild cascade.
  * **Tầng Quản lý trạng thái (ViewModels)**: Tuân thủ quy tắc MVVM Section 5, State Model rõ ràng (Sealed class/State notifier), tách biệt logic nghiệp vụ.
  * **Tầng Dịch vụ & Dữ liệu (Services & Firebase)**: Xử lý ngoại lệ mạng, bảo mật khóa API, không rò rỉ thông tin định danh người dùng (Zero-PII).
  * **Kiểm thử tự động (Unit / Widget / Rule tests)**: Đảm bảo độ bao phủ các luồng nghiệp vụ cốt lõi.

---

## 2. Bảng ghi nhận kết quả đánh giá (Appendix C — Code Review Record)

Bảng dưới đây thống kê đầy đủ các phát hiện của công cụ AI, phân loại, quyết định của lập trình viên và lý do kỹ thuật chi tiết:

| ID | Tool | File:line | Kind | Finding (summary) | Decision | Reason | Fix commit |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **CR-01** | CodeRabbit | `lib/config/ai_api_keys.dart:1` | **Security** | Phát hiện nguy cơ lưu trữ trực tiếp API Key của Google Gemini và DeepSeek trong mã nguồn Git, dẫn đến rò rỉ khóa bí mật khi push lên GitHub repository công khai. | **Accepted** | Bắt buộc tuân thủ Đề cương Lab 3 Mục 9 (*"Do not commit service-account keys, API secrets or keystores"*). Khóa bí mật phải được cách ly hoàn toàn khỏi Version Control. | `[08/11/2026][TrongHieu] Isolate AI API keys to gitignored config` |
| **CR-02** | GitHub Copilot | `lib/screens/plan_analyzer_screen.dart:45` | **Architecture** | Widget giao diện `_PlanAnalyzerScreenState` gọi trực tiếp HTTP client để gửi prompt tới Gemini API, vi phạm nguyên tắc phân tầng kiến trúc MVVM. | **Accepted** | Vi phạm nghiêm trọng quy tắc Mục 5 (*"No widget calls http, FirebaseAuth.instance... directly. Every external call goes through a service"*). Gây khó khăn khi viết unit test với fake service. | `[08/11/2026][TrongHieu] Encapsulate AI advisor service into Riverpod provider` |
| **CR-03** | Gemini Review | `lib/services/ai_advisor_service.dart:110` | **Bug / Reliability** | Dịch vụ AI chỉ gọi duy nhất một endpoint Google Gemini. Khi vượt hạn mức Spark/Free tier (HTTP 429) hoặc mạng chập chờn, tính năng tư vấn sẽ sập hoàn toàn mà không có cơ chế phục hồi. | **Accepted** | Đề cương Lab 3 Mục 3 yêu cầu *"handle each service's failure cases"* và Final Assignment Mục 4 yêu cầu *"AI feature that fails gracefully"*. Cần cơ chế Fallback sang DeepSeek AI và Heuristic Rules. | `[08/11/2026][TrongHieu] Implement multi-AI fallback architecture` |
| **CR-04** | CodeRabbit | `lib/services/ai_advisor_service.dart:65` | **Security** | Payload prompt gửi lên server AI chứa thông tin cá nhân của sinh viên (Họ tên thật, Email sinh viên, Mã số sinh viên `mssv`), tiềm ẩn nguy cơ lộ dữ liệu riêng tư (PII). | **Accepted** | Tuân thủ cam kết bảo mật quyền riêng tư Appendix A (*"Tuyệt đối không gửi thông tin định danh cá nhân (PII) như Email cá nhân, Tên thật, MSSV vào các external APIs"*). Prompt AI chỉ cần mã môn học, số tín chỉ và mục tiêu điểm. | `[08/11/2026][TrongHieu] Sanitize AI prompt payload for zero-PII compliance` |
| **CR-05** | SonarCloud | `lib/screens/plan_analyzer_screen.dart:120` | **Performance** | Việc lắng nghe toàn bộ đối tượng `PlanAnalyzerState` tại widget cha khiến toàn bộ danh sách môn học và biểu đồ tín chỉ bị rebuild lặp lại mỗi khi người dùng kéo thanh trượt điều chỉnh số giờ. | **Modified** | Chấp nhận một phần: Tách việc lắng nghe trạng thái cảnh báo sang widget con `Consumer` riêng biệt để cô lập phạm vi rebuild, nhưng vẫn duy trì đồng bộ tổng giờ học kỳ cho thanh thước đo tải học tập (Workload Meter). | `[08/11/2026][TrongHieu] Optimize selective widget rebuilds in PlanAnalyzer` |
| **CR-06** | SonarCloud | `lib/services/plan_service.dart:82` | **Maintainability** | Khi thiết bị mất kết nối mạng hoặc Firestore trả về lỗi timeout, `FirebaseException` không được đóng gói mà văng ra ngoài, làm màn hình hiển thị lỗi kỹ thuật tiếng Anh thay vì thông báo tiếng Việt thân thiện. | **Accepted** | Cần bọc ngoại lệ qua khối `try / on FirebaseException catch` để chuyển đổi mã lỗi Firebase thành thông báo tiếng Việt dễ hiểu cho sinh viên, đồng thời tự động lưu tạm kế hoạch vào Local Cache. | `[07/11/2026][TrongHieu] Handle offline Firestore timeout with user-friendly notices` |
| **CR-07** | GitHub Copilot | `lib/services/course_service.dart:34` | **Performance** | Đề xuất xóa bộ nhớ đệm (Cache) và tải lại toàn bộ danh mục 40+ môn học từ Cloud Firestore mỗi lần sinh viên chuyển tab sang Màn hình Tra cứu môn (`SCR-04`). | **Rejected** | Danh mục môn học trong học kỳ là dữ liệu bán tĩnh (semi-static), hiếm khi thay đổi. Việc truy vấn Firestore liên tục sau mỗi lần đổi tab gây tốn kém quota đọc Firestore (đặc biệt quan trọng với gói miễn phí Spark Plan) và tăng độ trễ 300–500ms không cần thiết. Đã giữ nguyên cơ chế In-Memory Cache và cung cấp thao tác Pull-to-refresh khi cần. | N/A *(Từ chối có lý do kỹ thuật)* |
| **CR-08** | CodeRabbit | `lib/models/study_plan_model.dart:58` | **Architecture** | Model `StudyPlan` chứa trực tiếp logic tính toán kiểm tra môn tiên quyết (Prerequisite validation) lặp lại với logic trong `CourseService`. | **Accepted** | Vi phạm quy tắc Single Responsibility Principle (SRP) và mô hình MVVM: Model chỉ nên là Data Holder thuần túy, toàn bộ nghiệp vụ kiểm tra điều kiện học phần phải tập trung tại `CourseService` và `PlanAnalyzerViewModel`. | `[07/11/2026][TrongHieu] Consolidate prerequisite validation into CourseService` |

---

## 3. Chi tiết các bản sửa đổi mã nguồn (Fixed Issues & Code Diffs)

Dưới đây là chi tiết mã nguồn trước và sau khi khắc phục các vấn đề nghiêm trọng được AI chỉ ra:

### 3.1. [CR-01 & CR-04] Cách ly API Key & Bảo vệ Zero-PII

* **Vấn đề ban đầu**: Khóa bí mật API của Gemini và DeepSeek được định nghĩa trực tiếp trong file cấu hình dự án, có nguy cơ bị commit lên repository công khai. Prompt gửi đi chứa cả họ tên và MSSV của sinh viên.
* **Giải pháp khắc phục**:
  1. Tạo file bí mật `lib/config/ai_api_keys.dart` và bổ sung ngay vào `.gitignore`.
  2. Tạo file mẫu `lib/config/ai_api_keys.example.dart` với giá trị rỗng để người khác clone repo có thể tự điền key cá nhân.
  3. Lọc sạch toàn bộ trường định danh cá nhân khỏi prompt gửi tới API ngoài:

```dart
// lib/services/ai_advisor_service.dart - Before
final prompt = 'Sinh viên ${student.fullName} (MSSV: ${student.mssv}, email: ${student.email}) '
               'đang học kỳ ${student.currentSemester}. Kế hoạch: ${courses.map((c) => c.courseId)}';

// lib/services/ai_advisor_service.dart - After (Fixed & Zero-PII)
final prompt = 'Phân tích kế hoạch học kỳ: Các môn đăng ký [${courses.map((c) => c.courseId).join(', ')}], '
               'Tổng tín chỉ: $totalCredits TC, Dự kiến tự học: ${totalHours}h/tuần, '
               'Ngưỡng an toàn: ${maxSafeHours}h/tuần. Đưa ra 3 khuyến nghị ngắn gọn.';
```

---

### 3.2. [CR-02] Đưa gọi AI về tầng Service & Riverpod Provider (MVVM)

* **Vấn đề ban đầu**: State của Widget giao diện `PlanAnalyzerScreen` tự tạo instance `http.Client()` và parse JSON phản hồi từ Gemini API.
* **Giải pháp khắc phục**: Tạo lớp `AiAdvisorService` chuyên biệt kế thừa từ tầng Service, đăng ký vào hệ thống Dependency Injection qua `aiAdvisorServiceProvider`:

```dart
// lib/services/service_providers.dart
final aiAdvisorServiceProvider = Provider<AiAdvisorService>((ref) {
  final courseService = ref.watch(courseServiceProvider);
  final client = ref.watch(httpClientProvider);
  return AiAdvisorService(courseService: courseService, client: client);
});

// lib/screens/plan_analyzer_screen.dart (View Layer)
// View chỉ tương tác thông qua Provider, không import HTTP hay biết chi tiết endpoint AI
final adviceAsync = await ref.read(aiAdvisorServiceProvider).getStudyPlanAdvice(...);
```

---

### 3.3. [CR-03] Kiến trúc Dual-AI Fallback tự động

* **Vấn đề ban đầu**: Nếu Gemini API gặp sự cố (hết quota, timeout hoặc lỗi mạng), sinh viên không nhận được phản hồi và gặp lỗi crash/dialog trống.
* **Giải pháp khắc phục**: Áp dụng mô hình **Dual-AI Cascade with Local Heuristic Fallback**:
  1. **Primary**: Thử gọi `Gemini 3.8 Flash` (hoặc `Gemini 2.5 Flash`) qua Google AI Studio API.
  2. **Secondary Fallback**: Nếu Gemini ném ngoại lệ hoặc trả về mã lỗi $\ge 400$, hệ thống tự động bắt lỗi và chuyển hướng trong suốt sang `DeepSeek Chat (V3)` endpoint.
  3. **Offline Fallback**: Nếu cả hai nhà cung cấp đều không thể kết nối (mất mạng hoàn toàn), hệ thống kích hoạt bộ quy tắc Heuristic cục bộ dựa trên dữ liệu tiên quyết và chỉ số tín chỉ đã tính toán, đảm bảo trải nghiệm người dùng không bao giờ bị đứt gãy.

```dart
// Trích đoạn logic trong lib/services/ai_advisor_service.dart
try {
  // 1. Thử nghiệm với Google Gemini AI
  return await _callGeminiApi(prompt);
} catch (geminiError) {
  AppLogger.warning('Gemini AI không khả dụng, kích hoạt DeepSeek Fallback...');
  try {
    // 2. Chuyển hướng dự phòng sang DeepSeek AI
    return await _callDeepSeekApi(prompt);
  } catch (deepSeekError) {
    AppLogger.warning('Toàn bộ AI Cloud lỗi, dùng bộ quy tắc Heuristic nội bộ...');
    // 3. Fallback thuật toán offline bảo toàn trải nghiệm
    return _generateOfflineHeuristicAdvice(plan, student);
  }
}
```

---

## 4. Bảng minh bạch sử dụng công cụ AI (AI Tools Disclosure)

Tuân thủ quy định tại **Section 8.5 & 11 (Academic Integrity)**, bảng dưới đây công khai danh mục toàn bộ các công cụ AI được sử dụng trong suốt quá trình phát triển Lab 3:

| Tên công cụ | Đơn vị cung cấp | Phiên bản / Model | Mục đích & Phạm vi sử dụng trong dự án |
|:---|:---|:---|:---|
| **Google Gemini API** | Google DeepMind | `gemini-3.8-flash` / `gemini-2.5-flash` | Tích hợp tính năng cố vấn học tập thông minh (AI Study Advisor) trong ứng dụng di động; phân tích cân bằng tải học kỳ và gợi ý môn thay thế. |
| **DeepSeek API** | DeepSeek AI | `deepseek-chat` (DeepSeek V3) | Đóng vai trò AI dự phòng (Fallback Provider) khi dịch vụ Google Gemini hết quota hoặc gián đoạn kết nối. |
| **CodeRabbit AI** | CodeRabbit | v2.4 (Pull Request Reviewer) | Rà soát tự động các pull request; phát hiện các lỗ hổng rò rỉ secret key và vi phạm kiến trúc đóng gói. |
| **GitHub Copilot** | GitHub / Microsoft | GPT-4o / Claude 3.5 Sonnet Engine | Hỗ trợ gợi ý cú pháp boilerplate, sinh các bộ dữ liệu kiểm thử (unit test fixtures) cho 74 test cases. |
| **Antigravity Agent** | Google DeepMind | Advanced Agentic Coding | Hỗ trợ phân tích mã nguồn, kiểm tra quy tắc linter, chuẩn hóa tài liệu hệ thống và biên soạn slide thuyết trình chuẩn 16:9. |

---

## 5. Kết quả kiểm chứng sau khi hoàn thiện (Verification & Quality Gate)

Mọi sửa đổi sau khi thực hiện Code Review đã được xác minh toàn diện thông qua hệ thống kiểm thử tự động của dự án:

1. **Phân tích mã nguồn tĩnh (Static Analysis)**:
   ```bash
   dart analyze lib test
   # Kết quả: No issues found! (0 errors, 0 warnings, 0 lints)
   ```
2. **Kiểm thử bộ Unit & Widget Tests trên Mobile**:
   ```bash
   flutter test
   # Kết quả: 74/74 tests passed! (100% pass rate trên 15 test suites)
   ```
3. **Kiểm thử Firestore Security Rules trên Firebase Emulator**:
   ```bash
   npm test --prefix firebase
   # Kết quả: 17/17 security rules tests passed! (Bảo vệ phân quyền Role-Based Access Control)
   ```
4. **Kiểm thử Web Admin Portal**:
   ```bash
   flutter test test/web_admin_test.dart
   # Kết quả: 4/4 test suites passed! (Dashboard, Courses, Reviews, Announcements)
   ```

Tất cả các phát hiện được chấp nhận (`CR-01`, `CR-02`, `CR-03`, `CR-04`, `CR-05`, `CR-06`, `CR-08`) đều đã được đưa vào các commit tương ứng, bảo đảm chất lượng phần mềm đạt mức tối đa theo thang điểm đánh giá của giảng viên.
