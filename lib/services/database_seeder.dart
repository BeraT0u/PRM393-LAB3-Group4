import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/student_profile_model.dart';
import '../models/study_plan_model.dart';
import '../utils/app_logger.dart';

class DatabaseSeeder {
  /// Bộ dữ liệu mẫu các môn học chuẩn theo Figma Handoff Lab 2 / Lab 3
  static final List<CourseModel> sampleCourses = [
    const CourseModel(
      id: 'PRM393',
      code: 'PRM393',
      name: 'Lập trình Di động',
      credits: 3,
      difficulty: 4.0,
      defaultSelfStudyHours: 8,
      prerequisiteCode: 'PRO192',
      category: 'Chuyên ngành SE',
      assessmentBreakdown: {
        'Đồ án': 40,
        'Thực hành (Lab)': 30,
        'Thi cuối kỳ (FE)': 30,
      },
      studyTips: [
        'Tập trung hoàn thiện Đồ án sớm theo chuẩn MVVM và Riverpod để đạt điểm tối đa.',
        'Nắm vững quy tắc thiết kế Material 3 Warm Paper và chuẩn tiếp cận WCAG trước buổi bảo vệ.',
      ],
      selectedGradeTarget: 'A',
      plannedSelfStudyHours: 8.0,
    ),
    const CourseModel(
      id: 'SWE302',
      code: 'SWE302',
      name: 'Kiến trúc Phần mềm',
      credits: 3,
      difficulty: 3.5,
      defaultSelfStudyHours: 7,
      prerequisiteCode: 'CSD201',
      category: 'Chuyên ngành SE',
      assessmentBreakdown: {
        'Assignment': 30,
        'Lab thực hành': 20,
        'Thi cuối kỳ (FE)': 50,
      },
      studyTips: [
        'Nắm vững mô hình C4 Model và phân tích kiến trúc Monolith vs Microservices.',
        'Thực hành vẽ sơ đồ tuần tự và kiến trúc phân tầng trong báo cáo đồ án.',
      ],
      selectedGradeTarget: 'B',
      plannedSelfStudyHours: 7.0,
    ),
    const CourseModel(
      id: 'AIE411',
      code: 'AIE411',
      name: 'Trí tuệ Nhân tạo Ứng dụng',
      credits: 3,
      difficulty: 4.0,
      defaultSelfStudyHours: 7,
      prerequisiteCode: 'MAS291',
      category: 'Chuyên ngành SE',
      assessmentBreakdown: {
        'Đồ án AI': 40,
        'Quiz & Lab': 20,
        'Thi cuối kỳ (FE)': 40,
      },
      studyTips: [
        'Tận dụng Gemini API và các mô hình đa phương thức cho bài toán thực tế.',
      ],
      selectedGradeTarget: 'A',
      plannedSelfStudyHours: 7.0,
    ),
    const CourseModel(
      id: 'IAE201',
      code: 'IAE201',
      name: 'An toàn Thông tin',
      credits: 3,
      difficulty: 4.5,
      defaultSelfStudyHours: 12,
      prerequisiteCode: 'NWC203', // Sinh viên chưa học môn này -> Báo động tiên quyết!
      category: 'Chuyên ngành SE',
      assessmentBreakdown: {
        'Lab Bảo mật': 30,
        'Đồ án an ninh': 30,
        'Thi cuối kỳ (FE)': 40,
      },
      studyTips: [
        'Thực hành cấu hình mã hóa RSA, AES và chữ ký số trên máy ảo Linux.',
      ],
      selectedGradeTarget: 'A',
      plannedSelfStudyHours: 12.0,
    ),
    const CourseModel(
      id: 'PRM323',
      code: 'PRM323',
      name: 'Thiết kế Giao diện UI/UX',
      credits: 3,
      difficulty: 3.0,
      defaultSelfStudyHours: 4,
      prerequisiteCode: null, // Không có tiên quyết -> Dùng thay thế IAE201 để gỡ xung đột
      category: 'Chuyên ngành SE',
      assessmentBreakdown: {
        'Figma Prototype': 40,
        'Usability Testing': 30,
        'Thi cuối kỳ (FE)': 30,
      },
      studyTips: [
        'Tuân thủ độ tương phản WCAG 2.1 AA/AAA và thiết kế đồng bộ Design System.',
      ],
      selectedGradeTarget: 'B',
      plannedSelfStudyHours: 4.0,
    ),
    const CourseModel(
      id: 'OSG209',
      code: 'OSG209',
      name: 'Hệ điều hành',
      credits: 3,
      difficulty: 3.5,
      defaultSelfStudyHours: 4,
      prerequisiteCode: 'CSD201',
      category: 'Cơ sở ngành',
      assessmentBreakdown: {
        'Lab Shell Script': 30,
        'Kiểm tra giữa kỳ': 20,
        'Thi cuối kỳ (FE)': 50,
      },
      studyTips: [
        'Hiểu rõ cơ chế định thời CPU (Round Robin, SRTF) và Semaphore giải quyết Deadlock.',
      ],
      selectedGradeTarget: 'A',
      plannedSelfStudyHours: 4.0,
    ),
    const CourseModel(
      id: 'DBI202',
      code: 'DBI202',
      name: 'Hệ quản trị Cơ sở Dữ liệu',
      credits: 3,
      difficulty: 3.5,
      defaultSelfStudyHours: 5,
      prerequisiteCode: 'MAD101',
      category: 'Cơ sở ngành',
      assessmentBreakdown: {
        'Lab SQL': 30,
        'Assignment': 20,
        'Thi cuối kỳ (FE)': 50,
      },
      studyTips: [
        'Ôn tập kỹ Stored Procedure, Trigger và Indexing trước buổi thực hành cuối kỳ.',
      ],
      selectedGradeTarget: 'A',
      plannedSelfStudyHours: 5.0,
    ),
  ];

  /// Hồ sơ Persona 1: Trần Hoàng Long (SE180504 - Tiêu chuẩn, kịch bản kế hoạch 34h -> 26h)
  static final StudentProfileModel defaultStudent = StudentProfileModel(
    uid: 'student_se180504',
    email: 'longth.se180504@gmail.com',
    fullName: 'Trần Hoàng Long',
    studentId: 'SE180504',
    accumulatedCredits: 90,
    totalGraduationCredits: 145,
    currentGpa: 3.42,
    targetGpa: 3.65,
    passedCourseCodes: const ['PRO192', 'MAD101', 'CSD201', 'DBI202', 'MAS291'],
    notifyLabDeadlines: true,
    autoWarnWorkload: true,
    syncGoogleCalendar: false,
    isNewStudent: false,
  );

  /// Hồ sơ Persona 2: Nguyễn Mai Linh (SE170123 - Sinh viên xuất sắc năm cuối, 125/145 TC)
  static final StudentProfileModel personaLinh = StudentProfileModel(
    uid: 'student_se170123',
    email: 'linhnm.se170123@gmail.com',
    fullName: 'Nguyễn Mai Linh',
    studentId: 'SE170123',
    accumulatedCredits: 125,
    totalGraduationCredits: 145,
    currentGpa: 3.82,
    targetGpa: 3.90,
    passedCourseCodes: const [
      'PRO192', 'MAD101', 'CSD201', 'DBI202', 'MAS291',
      'PRM393', 'SWE302', 'AIE411', 'PRM323', 'OSG209', 'NWC203', 'IAE201'
    ],
    notifyLabDeadlines: true,
    autoWarnWorkload: true,
    syncGoogleCalendar: true,
    isNewStudent: false,
  );

  /// Hồ sơ Persona 3: Lê Minh Tuấn (SE190456 - Sinh viên năm 2, nguy cơ học vụ, 35/145 TC)
  static final StudentProfileModel personaTuan = StudentProfileModel(
    uid: 'student_se190456',
    email: 'tuanlm.se190456@gmail.com',
    fullName: 'Lê Minh Tuấn',
    studentId: 'SE190456',
    accumulatedCredits: 35,
    totalGraduationCredits: 145,
    currentGpa: 2.65,
    targetGpa: 3.20,
    passedCourseCodes: const ['PRO192', 'MAD101'],
    notifyLabDeadlines: false,
    autoWarnWorkload: true,
    syncGoogleCalendar: false,
    isNewStudent: false,
  );

  /// Khởi tạo hồ sơ rỗng cho tài khoản Google mới chưa định danh
  static StudentProfileModel getEmptyProfile(
    String uid, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return StudentProfileModel(
      uid: uid,
      email: email,
      fullName: (displayName != null && displayName.trim().isNotEmpty)
          ? displayName
          : 'Sinh viên mới',
      studentId: '',
      accumulatedCredits: 0,
      totalGraduationCredits: 145,
      currentGpa: 0.0,
      targetGpa: 3.50,
      avatarUrl: photoUrl,
      passedCourseCodes: const [],
      notifyLabDeadlines: true,
      autoWarnWorkload: true,
      syncGoogleCalendar: false,
      isNewStudent: true, // Đánh dấu tài khoản cần thiết lập
    );
  }

  /// Nhận diện hồ sơ phù hợp dựa trên Email hoặc UID người dùng
  static StudentProfileModel resolveProfileForUser({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    final lowerEmail = (email ?? '').toLowerCase().trim();

    // 1. Khớp Persona 1: Trần Hoàng Long
    if (lowerEmail.contains('long') || uid == defaultStudent.uid) {
      return defaultStudent.copyWith(
        uid: uid,
        email: email ?? defaultStudent.email,
        avatarUrl: photoUrl ?? defaultStudent.avatarUrl,
      );
    }

    // 2. Khớp Persona 2: Nguyễn Mai Linh
    if (lowerEmail.contains('linh') || uid == personaLinh.uid) {
      return personaLinh.copyWith(
        uid: uid,
        email: email ?? personaLinh.email,
        avatarUrl: photoUrl ?? personaLinh.avatarUrl,
      );
    }

    // 3. Khớp Persona 3: Lê Minh Tuấn
    if (lowerEmail.contains('tuan') || uid == personaTuan.uid) {
      return personaTuan.copyWith(
        uid: uid,
        email: email ?? personaTuan.email,
        avatarUrl: photoUrl ?? personaTuan.avatarUrl,
      );
    }

    // 4. Tài khoản mới hoàn toàn: Khởi tạo hồ sơ rỗng để sinh viên tự điền
    return getEmptyProfile(
      uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  /// Kế hoạch học tập ban đầu (Trạng thái XUNG ĐỘT QUÁ TẢI 34h: PRM393, SWE302, AIE411, IAE201)
  static StudyPlanModel getInitialConflictPlan(String userId) {
    final conflictCourses = [
      sampleCourses.firstWhere((c) => c.code == 'PRM393'),
      sampleCourses.firstWhere((c) => c.code == 'SWE302'),
      sampleCourses.firstWhere((c) => c.code == 'AIE411'),
      sampleCourses.firstWhere((c) => c.code == 'IAE201'), // Vi phạm NWC203 + 12h
    ];

    return StudyPlanModel(
      id: '${userId}_Fall2024',
      userId: userId,
      semesterName: 'Fall 2024',
      selectedCourses: conflictCourses,
      maxSafeThresholdHours: 25.0,
      targetGpa: 3.65,
      tuitionFee: 14250000,
      isSaved: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Kế hoạch học tập sau khi giải quyết xung đột (Đổi IAE201 -> PRM323, tải 26h tự học Cân Bằng)
  static StudyPlanModel getResolvedPlan(String userId) {
    final resolvedCourses = [
      sampleCourses.firstWhere((c) => c.code == 'PRM393'),
      sampleCourses.firstWhere((c) => c.code == 'SWE302'),
      sampleCourses.firstWhere((c) => c.code == 'AIE411'),
      sampleCourses.firstWhere((c) => c.code == 'PRM323'), // Đổi sang môn này (4h)
      sampleCourses.firstWhere((c) => c.code == 'OSG209'), // Thêm môn (4h)
    ];

    return StudyPlanModel(
      id: '${userId}_Fall2024',
      userId: userId,
      semesterName: 'Fall 2024',
      selectedCourses: resolvedCourses,
      maxSafeThresholdHours: 25.0,
      targetGpa: 3.65,
      tuitionFee: 14250000,
      isSaved: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Nạp tự động dữ liệu lên Cloud Firestore nếu Firestore đang trống
  static Future<void> seedDatabaseIfEmpty() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final coursesCollection = firestore.collection('courses');

      final snapshot = await coursesCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        AppLogger.info('Firestore đã có dữ liệu môn học, bỏ qua bước seeder.');
        return;
      }

      AppLogger.info('Firestore đang trống. Bắt đầu nạp dữ liệu mẫu lên Cloud...');

      // 1. Nạp danh mục môn học
      final batch = firestore.batch();
      for (final course in sampleCourses) {
        final docRef = coursesCollection.doc(course.id);
        batch.set(docRef, course.toMap());
      }

      // 2. Nạp hồ sơ sinh viên mặc định
      final studentRef = firestore.collection('students').doc(defaultStudent.uid);
      batch.set(studentRef, defaultStudent.toMap());

      // 3. Nạp kế hoạch học tập mẫu
      final plan = getInitialConflictPlan(defaultStudent.uid);
      final planRef = firestore.collection('study_plans').doc(plan.id);
      batch.set(planRef, plan.toMap());

      await batch.commit();
      AppLogger.info('Đã nạp thành công 7 môn học, hồ sơ sinh viên và kế hoạch mẫu lên Cloud Firestore!');
    } catch (e, st) {
      AppLogger.warning('Chưa thể nạp dữ liệu lên Firestore (Offline hoặc chưa cấu hình quyền): $e');
      AppLogger.error('Chi tiết lỗi seeder', e, st);
    }
  }
}
