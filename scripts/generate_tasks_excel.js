const XLSX = require('xlsx');
const path = require('path');

// Danh sách dữ liệu các Use Case và công việc của dự án EduPlan
const tasks = [
  // NHÓM 0: NỀN TẢNG KỸ THUẬT & KHỞI TẠO HỆ THỐNG
  {
    category: 'NHÓM 0: NỀN TẢNG KỸ THUẬT & KHỞI TẠO HỆ THỐNG',
    id: 'SETUP-01',
    functionScreen: 'Khởi tạo dự án Flutter, cấu hình package name com.eduplan.app & Git repo',
    level: 'Simple (N=1)',
    responsible: '',
    date: '28/10/2026',
    status: 'Đã commit',
    note: 'Cấu hình build.gradle.kts, Git initial commit theo quy tắc [DD/MM/YYYY][TrongHieu]'
  },
  {
    category: 'NHÓM 0: NỀN TẢNG KỸ THUẬT & KHỞI TẠO HỆ THỐNG',
    id: 'SETUP-02',
    functionScreen: 'Cấu hình Firebase project prm393-eduplan & SHA-1 keystore dùng chung',
    level: 'Medium (N=3)',
    responsible: '',
    date: '28/10/2026',
    status: 'Đã commit',
    note: 'Tích hợp google-services.json & debug.keystore chia sẻ cho mọi thành viên'
  },
  {
    category: 'NHÓM 0: NỀN TẢNG KỸ THUẬT & KHỞI TẠO HỆ THỐNG',
    id: 'SETUP-03',
    functionScreen: 'Xây dựng Design System Tokens (Warm Paper Academic Theme)',
    level: 'Simple (N=2)',
    responsible: '',
    date: '28/10/2026',
    status: 'Đã commit',
    note: 'AppColors (#FBF6EB canvas), AppTypography (Inter), AppDimens, AppTheme'
  },
  {
    category: 'NHÓM 0: NỀN TẢNG KỸ THUẬT & KHỞI TẠO HỆ THỐNG',
    id: 'SETUP-04',
    functionScreen: 'Thiết kế Data Models & DTOs tuần tự hóa với Firestore',
    level: 'Simple (N=2)',
    responsible: '',
    date: '28/10/2026',
    status: 'Đã commit',
    note: 'CourseModel, StudentProfileModel, StudyPlanModel có toMap() & fromMap()'
  },
  {
    category: 'NHÓM 0: NỀN TẢNG KỸ THUẬT & KHỞI TẠO HỆ THỐNG',
    id: 'SETUP-05',
    functionScreen: 'Xây dựng Firebase Services & Bộ nạp dữ liệu mẫu (DatabaseSeeder)',
    level: 'Medium (N=4)',
    responsible: '',
    date: '28/10/2026',
    status: 'Đã commit',
    note: 'CourseService, StudentService, PlanService, StorageService, Seeder 7 môn học mẫu'
  },
  {
    category: 'NHÓM 0: NỀN TẢNG KỸ THUẬT & KHỞI TẠO HỆ THỐNG',
    id: 'SETUP-06',
    functionScreen: 'Soạn thảo tài liệu kỹ thuật & Hướng dẫn cài đặt cho nhóm',
    level: 'Simple (N=2)',
    responsible: '',
    date: '28/10/2026',
    status: 'Đã commit',
    note: 'design-traceability.md, architecture.md, analytics-plan.md, DATABASE_AND_TEAM_GUIDE.md'
  },

  // NHÓM 1: REUSABLE UI COMPONENTS (Thành phần giao diện dùng chung)
  {
    category: 'NHÓM 1: REUSABLE UI COMPONENTS (Giao diện dùng chung)',
    id: 'UC-01',
    functionScreen: 'Bộ nút bấm chuẩn Design System (Primary, Tonal, Destructive Button)',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Cao 48-52dp, touch target >= 48dp, các state: Default, Pressed, Disabled, Spinner'
  },
  {
    category: 'NHÓM 1: REUSABLE UI COMPONENTS (Giao diện dùng chung)',
    id: 'UC-02',
    functionScreen: 'Thẻ môn học chiến lược (CourseStrategyCard) & State vi phạm viền đỏ',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Hiển thị độ khó ⭐, giờ tự học, viền 1px solid, biến thể Conflict viền đỏ 1.5px'
  },
  {
    category: 'NHÓM 1: REUSABLE UI COMPONENTS (Giao diện dùng chung)',
    id: 'UC-03',
    functionScreen: 'Thanh tìm kiếm (AppSearchBar) & Bộ lọc Filter Chips chuyên ngành',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Ô Search cao 48dp bo góc 8dp, các chip: Tất cả, Chuyên ngành SE, Cơ sở'
  },
  {
    category: 'NHÓM 1: REUSABLE UI COMPONENTS (Giao diện dùng chung)',
    id: 'UC-04',
    functionScreen: 'Bộ Badge trạng thái (StatusBadge / Tag Pill) chuẩn tương phản WCAG',
    level: 'Simple (N=1)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Success (xanh lá #DCFCE7), Warning (vàng nâu #FEF3C7), Danger (đỏ #FEE2E2)'
  },
  {
    category: 'NHÓM 1: REUSABLE UI COMPONENTS (Giao diện dùng chung)',
    id: 'UC-05',
    functionScreen: 'Banner báo động đỏ quá tải & vi phạm tiên quyết (AppAlertBanner)',
    level: 'Simple (N=1)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Nền đỏ nhạt #FEE2E2, viền đỏ #DC2626, icon ⚠️, chữ đỏ đậm #B91C1C'
  },
  {
    category: 'NHÓM 1: REUSABLE UI COMPONENTS (Giao diện dùng chung)',
    id: 'UC-06',
    functionScreen: 'Trạng thái Shimmer Loading (Skeleton) & Empty State tìm kiếm rỗng',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Shimmer xám #EAE1D0; Empty state icon kính lúp + nút "Xóa bộ lọc"'
  },
  {
    category: 'NHÓM 1: REUSABLE UI COMPONENTS (Giao diện dùng chung)',
    id: 'UC-07',
    functionScreen: 'Khung điều hướng chung MainScaffold & Responsive NavigationRail',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'NavigationBar 64dp 4 tab (Mobile) tự chuyển sang NavigationRail khi width >= 600dp'
  },

  // NHÓM 2: MÀN HÌNH ĐĂNG NHẬP & TRANG CHỦ (Auth & Home Dashboard)
  {
    category: 'NHÓM 2: MÀN HÌNH ĐĂNG NHẬP & TRANG CHỦ (SCR-01 & SCR-02)',
    id: 'UC-08',
    functionScreen: 'SCR-01 Màn hình Đăng nhập & State SCR-01_Loading',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Logo sổ tay 64dp, slogan, nút đăng nhập Google, spinner "Đang xác thực Google..."'
  },
  {
    category: 'NHÓM 2: MÀN HÌNH ĐĂNG NHẬP & TRANG CHỦ (SCR-01 & SCR-02)',
    id: 'UC-09',
    functionScreen: 'Xử lý xác thực Google Sign-In & Auth-state Routing (Signed in -> Home)',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Bắt sự kiện hủy đăng nhập từ người dùng, dọn dẹp session khi sign-out'
  },
  {
    category: 'NHÓM 2: MÀN HÌNH ĐĂNG NHẬP & TRANG CHỦ (SCR-01 & SCR-02)',
    id: 'UC-10',
    functionScreen: 'SCR-02 Home Dashboard: Lời chào, tích lũy 90/145 TC, GPA mục tiêu 3.60',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Top App Bar, Avatar sinh viên, pull-to-refresh cập nhật dữ liệu từ Firestore'
  },
  {
    category: 'NHÓM 2: MÀN HÌNH ĐĂNG NHẬP & TRANG CHỦ (SCR-01 & SCR-02)',
    id: 'UC-11',
    functionScreen: 'SCR-02 Hero Card "🔥 Trọng tâm Tuần 8": Tiến độ tự học môn PRM393 (6/8h)',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Thanh progress bar xanh, tag Mục tiêu Điểm A, chạm vào mở chi tiết môn SCR-05'
  },
  {
    category: 'NHÓM 2: MÀN HÌNH ĐĂNG NHẬP & TRANG CHỦ (SCR-01 & SCR-02)',
    id: 'UC-12',
    functionScreen: 'SCR-02 Section "💡 Tips học tập kỳ này" kết hợp Remote Config toggle',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: '2 thẻ gợi ý ngắn SWE302 (C4 Model) và DBI202; ẩn/hiện theo enable_study_tips'
  },

  // NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03 & SCR-04)
  {
    category: 'NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03, 04, 05)',
    id: 'UC-13',
    functionScreen: 'SCR-03 Màn hình Môn Đã Học (Completed Courses) & Mở khóa tiên quyết',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Card Tiến độ 90/145 TC (62%), Filter Chips theo kỳ, dòng chú thích mở khóa PRM393'
  },
  {
    category: 'NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03, 04, 05)',
    id: 'UC-14',
    functionScreen: 'SCR-04 Course Catalog: Danh mục môn mở, tìm kiếm & độ khó tự học',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Thẻ môn học, số TC, độ khó ⭐, tự học h/tuần, nút Tonal Button "Chiến lược >"'
  },
  {
    category: 'NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03, 04, 05)',
    id: 'UC-15',
    functionScreen: 'SCR-04 Xử lý Shimmer Skeleton khi tải & Empty State khi tìm kiếm rỗng',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Khi tìm từ khóa không có môn (VD: XYZ99) hiện kính lúp buồn + nút Xóa bộ lọc'
  },
  {
    category: 'NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03, 04, 05)',
    id: 'UC-16',
    functionScreen: 'SCR-05 Course Strategy: Header môn PRM393 & 3 badge thông số',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: '3 badge: 3 Tín chỉ, Độ khó 4/5 ⭐, Tiên quyết PRO192 ✅. Ẩn hoàn toàn Bottom Bar'
  },
  {
    category: 'NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03, 04, 05)',
    id: 'UC-17',
    functionScreen: 'SCR-05 Cấu trúc điểm 40/30/30 & Thẻ Study Tips khóa trên',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: '3 hộp thông số: Đồ án 40%, Lab 30%, FE 30%; Thẻ vàng nhạt tips làm Riverpod/MVVM'
  },
  {
    category: 'NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03, 04, 05)',
    id: 'UC-18',
    functionScreen: 'SCR-05 Radio Card chọn Mục tiêu điểm (Điểm A: 8h, B: 5h, Qua môn: 3.5h)',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: '3 Radio card tương tác mượt mà, tự động cập nhật số giờ tự học dự kiến'
  },
  {
    category: 'NHÓM 3: TIẾN ĐỘ TÍCH LŨY & DANH MỤC MÔN HỌC (SCR-03, 04, 05)',
    id: 'UC-19',
    functionScreen: 'SCR-05 Docked Action Footer: Nút yêu thích + Nút "Thêm vào Kế hoạch"',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Cố định chân trang, padding-bottom 110dp chống đè nội dung, điều hướng sang SCR-06A'
  },

  // NHÓM 4: PHÂN TÍCH QUÁ TẢI & KHẮC PHỤC XUNG ĐỘT (SCR-06A & SCR-06B)
  {
    category: 'NHÓM 4: PHÂN TÍCH QUÁ TẢI & KHẮC PHỤC XUNG ĐỘT (SCR-06A & 06B)',
    id: 'UC-20',
    functionScreen: 'SCR-06A Workload Analyzer: Banner cảnh báo đỏ quá tải & vi phạm',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Nền đỏ #FEE2E2, viền #DC2626, icon ⚠️ "Cảnh báo: Vi phạm tiên quyết & Quá tải!"'
  },
  {
    category: 'NHÓM 4: PHÂN TÍCH QUÁ TẢI & KHẮC PHỤC XUNG ĐỘT (SCR-06A & 06B)',
    id: 'UC-21',
    functionScreen: 'SCR-06A Thẻ Workload Meter: 34h/tuần vượt ngưỡng an toàn (25h Remote Config)',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Thanh progress bar có đoạn màu đỏ báo quá tải, lấy max_safe_workload_hours động'
  },
  {
    category: 'NHÓM 4: PHÂN TÍCH QUÁ TẢI & KHẮC PHỤC XUNG ĐỘT (SCR-06A & 06B)',
    id: 'UC-22',
    functionScreen: 'SCR-06A Danh sách 4 thẻ môn: 3 môn hợp lệ và 1 môn vi phạm đỏ IAE201',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'PRM393 (8h), SWE302 (7h), AIE411 (7h); IAE201 (+12h, LỖI chưa học tiên quyết NWC203)'
  },
  {
    category: 'NHÓM 4: PHÂN TÍCH QUÁ TẢI & KHẮC PHỤC XUNG ĐỘT (SCR-06A & 06B)',
    id: 'UC-23',
    functionScreen: 'SCR-06B Selected Courses (State lỗi): Nút Lưu BỊ KHÓA & Nút [⇄ Đổi môn]',
    level: 'Hard (N=5)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Nút chân trang màu xám "🔒 Giải quyết 1 xung đột để lưu"; nút Đổi môn mở SCR-05'
  },
  {
    category: 'NHÓM 4: PHÂN TÍCH QUÁ TẢI & KHẮC PHỤC XUNG ĐỘT (SCR-06A & 06B)',
    id: 'UC-24',
    functionScreen: 'SCR-06B_Resolved Khắc phục xung đột: Đổi sang PRM323, tải 26h Cân bằng',
    level: 'Hard (N=5)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Môn thứ 4 đổi thành PRM323 (4h), tổng 26h; NÚT LƯU MỞ KHÓA MÀU XANH ACTIVE'
  },
  {
    category: 'NHÓM 4: PHÂN TÍCH QUÁ TẢI & KHẮC PHỤC XUNG ĐỘT (SCR-06A & 06B)',
    id: 'UC-25',
    functionScreen: 'Lưu Kế hoạch học tập vào Firestore & Chuyển hướng sang SCR-07',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Ghi dữ liệu kế hoạch hợp lệ vào study_plans trên Cloud Firestore, pushNamed sang SCR-07'
  },

  // NHÓM 5: TỔNG KẾT KẾ HOẠCH & XUẤT BLUEPRINT PDF (SCR-07)
  {
    category: 'NHÓM 5: TỔNG KẾT KẾ HOẠCH & XUẤT BLUEPRINT PDF (SCR-07)',
    id: 'UC-26',
    functionScreen: 'SCR-07 Semester Summary: Thẻ Hero KPI (5 Môn, 15 TC, GPA 3.65, 26h tự học)',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Khôi phục Bottom Bar; 4 nhãn KPI chia 2 hàng: Lộ trình hợp lệ, Học phí 14.250.000đ'
  },
  {
    category: 'NHÓM 5: TỔNG KẾT KẾ HOẠCH & XUẤT BLUEPRINT PDF (SCR-07)',
    id: 'UC-27',
    functionScreen: 'SCR-07 Danh sách 5 môn học kèm mục tiêu điểm (A / B+) và tích xanh ✅',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Hiển thị PRM393, SWE302, AIE411, PRM323, OSG209 thẻ nhỏ gọn, căn gióng đẹp mắt'
  },
  {
    category: 'NHÓM 5: TỔNG KẾT KẾ HOẠCH & XUẤT BLUEPRINT PDF (SCR-07)',
    id: 'UC-28',
    functionScreen: 'SCR-07 Tạo file tài liệu PDF Blueprint A4 Kế hoạch học tập',
    level: 'Medium (N=4)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Dựng bằng pdf & printing package: Header, bảng KPI, bảng điểm & giờ tự học từng môn'
  },
  {
    category: 'NHÓM 5: TỔNG KẾT KẾ HOẠCH & XUẤT BLUEPRINT PDF (SCR-07)',
    id: 'UC-29',
    functionScreen: 'SCR-07 Upload file PDF lên Firebase Storage reports/{uid}/... & hiển thị progress',
    level: 'Hard (N=5)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Thanh tiến trình % tải lên, lấy download URL thật trên Cloud Storage (bucket Blaze)'
  },
  {
    category: 'NHÓM 5: TỔNG KẾT KẾ HOẠCH & XUẤT BLUEPRINT PDF (SCR-07)',
    id: 'UC-30',
    functionScreen: 'SCR-07 Kích hoạt hộp thoại xem trước in ấn PDF & Đồng bộ lịch Google Calendar',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Nút "📄 Xuất PDF Kế Hoạch & Chiến Lược (A4)", nút Đồng bộ lịch và nút Chia sẻ'
  },

  // NHÓM 6: HỒ SƠ CÁ NHÂN & FIREBASE DEMO SHOWCASE (SCR-08)
  {
    category: 'NHÓM 6: HỒ SƠ CÁ NHÂN & FIREBASE DEMO (SCR-08)',
    id: 'UC-31',
    functionScreen: 'SCR-08 Profile: Thẻ sinh viên Trần Hoàng Long, MSSV SE180504, GPA 3.42',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Avatar tròn, pill Đã tích lũy: 90 / 145 TC và pill ⭐ GPA: 3.42 (Giỏi)'
  },
  {
    category: 'NHÓM 6: HỒ SƠ CÁ NHÂN & FIREBASE DEMO (SCR-08)',
    id: 'UC-32',
    functionScreen: 'SCR-08 Thẻ học kỳ Fall 2024: Nút "Chi tiết >" mở lại màn hình SCR-07',
    level: 'Simple (N=1)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Touch target 48dp, chuyển hướng mượt mà sang bản tổng kết kế hoạch đã lưu'
  },
  {
    category: 'NHÓM 6: HỒ SƠ CÁ NHÂN & FIREBASE DEMO (SCR-08)',
    id: 'UC-33',
    functionScreen: 'SCR-08 Nhóm cài đặt 3 Switch: Nhắc hạn Lab, Cảnh báo quá tải, Sync Calendar',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Chiều cao mỗi tile >= 56dp, đồng bộ trạng thái toggle tức thời lên Cloud Firestore'
  },
  {
    category: 'NHÓM 6: HỒ SƠ CÁ NHÂN & FIREBASE DEMO (SCR-08)',
    id: 'UC-34',
    functionScreen: 'SCR-08 Firebase Demo Showcase: Crashlytics test, Remote Config & FCM inbox',
    level: 'Medium (N=4)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Nút test Crashlytics (non-fatal error & crash), hiển thị giá trị Remote Config động'
  },
  {
    category: 'NHÓM 6: HỒ SƠ CÁ NHÂN & FIREBASE DEMO (SCR-08)',
    id: 'UC-35',
    functionScreen: 'Overlay_Logout Modal: Hộp thoại xác nhận đăng xuất tài khoản',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Dialog 320dp bo góc 16dp, 2 nút Hủy và Đăng xuất (50/50), xóa session về SCR-01'
  },

  // NHÓM 7: ĐO LƯỜNG SỰ KIỆN & KIỂM THỬ E2E (Analytics & Testing)
  {
    category: 'NHÓM 7: ĐO LƯỜNG SỰ KIỆN & KIỂM THỬ E2E (Analytics & Testing)',
    id: 'UC-36',
    functionScreen: 'Gắn mã ghi nhận 8 sự kiện Firebase Analytics (DebugView verification)',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Đầy đủ parameters không PII: login, search, view_detail, conflict, resolve, export...'
  },
  {
    category: 'NHÓM 7: ĐO LƯỜNG SỰ KIỆN & KIỂM THỬ E2E (Analytics & Testing)',
    id: 'UC-37',
    functionScreen: 'Gắn Semantics Labels trợ năng cho toàn bộ nút bấm, card, ô nhập liệu',
    level: 'Simple (N=2)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Phục vụ khả năng tiếp cận WCAG và giúp AI Agent ARTEMIS đọc cây widget'
  },
  {
    category: 'NHÓM 7: ĐO LƯỜNG SỰ KIỆN & KIỂM THỬ E2E (Analytics & Testing)',
    id: 'UC-38',
    functionScreen: 'Xây dựng kịch bản kiểm thử E2E tự động với Google ARTEMIS / Pytest',
    level: 'Hard (N=6)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: '>= 10 test cases trong e2e_test/, bao gồm luồng chính, native dialog và error-path'
  },
  {
    category: 'NHÓM 7: ĐO LƯỜNG SỰ KIỆN & KIỂM THỬ E2E (Analytics & Testing)',
    id: 'UC-39',
    functionScreen: 'Thực hiện AI-Assisted Code Review & lưu bằng chứng docs/code-review.md',
    level: 'Medium (N=3)',
    responsible: '',
    date: '',
    status: 'Chưa bắt đầu',
    note: 'Ghi nhận >= 5 findings, ra quyết định chấp nhận/từ chối và >= 3 commit sửa lỗi'
  }
];

// Tạo cấu trúc Workbook
const wb = XLSX.utils.book_new();

// Header dòng 1
const headers = [
  'ID',
  'Function / Screen',
  'Level',
  'Responsible by',
  'Date',
  'Trạng thái',
  'Note'
];

// Dựng các hàng
const rows = [headers];

let currentCategory = '';
tasks.forEach(t => {
  if (t.category !== currentCategory) {
    currentCategory = t.category;
    // Dòng nhóm phân tách
    rows.push([currentCategory, '', '', '', '', '', '']);
  }
  rows.push([
    t.id,
    t.functionScreen,
    t.level,
    t.responsible,
    t.date,
    t.status,
    t.note
  ]);
});

const ws = XLSX.utils.aoa_to_sheet(rows);

// Thiết lập độ rộng cột (Column Widths)
ws['!cols'] = [
  { wch: 12 }, // ID
  { wch: 60 }, // Function / Screen
  { wch: 16 }, // Level
  { wch: 18 }, // Responsible by
  { wch: 14 }, // Date
  { wch: 16 }, // Trạng thái
  { wch: 65 }, // Note
];

XLSX.utils.book_append_sheet(wb, ws, 'EduPlan_Tasks');

const outPath = path.join(__dirname, '..', 'EduPlan_Project_Tasks_UC.xlsx');
XLSX.writeFile(wb, outPath);

console.log(`Đã tạo thành công file Excel tại: ${outPath}`);
