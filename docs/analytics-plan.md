# EduPlan — Analytics Event Plan (Lab 3)

Kế hoạch đo lường sự kiện người dùng qua **Firebase Analytics** nhằm phục vụ việc theo dõi hành vi và cải thiện chất lượng sản phẩm (Tuân thủ biểu mẫu Appendix A của Đề cương Lab 3).

---

## 1. Bảng danh mục sự kiện (Analytics Events List)

| Event Name | Trigger (Thời điểm kích hoạt) | Parameters (type) | Question it answers (Câu hỏi định lượng sản phẩm) |
|:---|:---|:---|:---|
| **`login`** | Đăng nhập Google thành công | `method` (string) | Có bao nhiêu người dùng quay lại và đăng nhập vào ứng dụng mỗi tuần? |
| **`search`** | Người dùng gõ tìm kiếm môn học | `search_term` (string), `result_count` (int) | Các mã môn hoặc từ khóa nào được tìm kiếm nhiều nhất và từ khóa nào trả về 0 kết quả? |
| **`view_course_detail`** | Mở xem chi tiết môn học (`SCR-05`) | `course_id` (string), `course_name` (string), `credits` (int) | Môn học nào được sinh viên quan tâm xem chi tiết chiến lược nhiều nhất? |
| **`select_grade_target`** | Chọn mục tiêu điểm (A / B / Qua môn) | `course_id` (string), `target_grade` (string), `planned_hours` (int) | Xu hướng sinh viên đặt mục tiêu điểm A hay chỉ cần qua môn cho từng môn học? |
| **`detect_plan_conflict`** | Hệ thống phát hiện quá tải hoặc vi phạm tiên quyết | `total_hours` (int), `violated_course_id` (string), `conflict_type` (string) | Tỷ lệ kế hoạch học tập bị rơi vào trạng thái quá tải tự học là bao nhiêu? |
| **`resolve_plan_conflict`** | Người dùng khắc phục xung đột thành công (đổi môn) | `old_course_id` (string), `new_course_id` (string), `new_total_hours` (int) | Bao nhiêu phần trăm người dùng chủ động khắc phục lỗi để mở khóa nút lưu kế hoạch? |
| **`export_report`** | Người dùng nhấn xuất file PDF A4 kế hoạch | `format` (string), `courses_count` (int), `total_credits` (int) | Bản kế hoạch nào dẫn đến hành vi xuất tài liệu in ấn PDF nhiều nhất? |
| **`logout`** | Người dùng xác nhận đăng xuất tài khoản | `session_duration_sec` (int) | Thời lượng trung bình của một phiên làm việc trước khi sinh viên đăng xuất là bao lâu? |

---

## 2. Cam kết bảo mật dữ liệu riêng tư (Privacy & Compliance)
* Tuyệt đối không gửi thông tin định danh cá nhân (PII) như: Email cá nhân, Tên thật, MSSV hay số điện thoại vào các `parameters`.
* Người dùng chỉ được nhận diện bằng `user_id` ẩn danh (Firebase UID) sau khi đăng nhập thành công.
