import 'package:eduplan/main.dart';
import 'package:eduplan/models/completed_course_model.dart';
import 'package:eduplan/models/study_plan_model.dart';
import 'package:eduplan/services/database_seeder.dart';
import 'package:eduplan/services/service_providers.dart';
import 'package:eduplan/viewmodels/completed_courses_viewmodel.dart';
import 'package:eduplan/viewmodels/plan_analyzer_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('New Account Persona Journey Tests (0 TC -> Kỳ 1 -> Kỳ 2)', () {
    testWidgets(
      '1. Trang Login không còn nút tài khoản giả lập; tài khoản mới ở Home không hiện dữ liệu giả (PRM393/SWE302/Fall 2024)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(
            child: EduPlanApp(),
          ),
        );

        // Kiểm tra LoginScreen không có nút tài khoản giả lập
        expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
        expect(find.textContaining('Chế độ thử nghiệm'), findsNothing);
        expect(find.textContaining('Đổi'), findsNothing);

        // Bấm Đăng nhập bằng Google -> vào tài khoản mới trống (0 TC)
        await tester.tap(find.text('Đăng nhập bằng Google'));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Kiểm tra HomeScreen hiển thị đúng trạng thái tài khoản mới 0 TC, Học kỳ 1, không có dữ liệu giả
        expect(find.textContaining('Tích lũy: 0/145 TC'), findsOneWidget);
        expect(find.textContaining('GPA mục tiêu: Chưa có thông tin'), findsOneWidget);
        expect(find.text('📅 Kế hoạch Học kỳ 1'), findsOneWidget);
        expect(find.text('Chưa có thông tin môn học trọng tâm'), findsOneWidget);
        expect(find.textContaining('Chưa có thông tin gợi ý học tập'), findsOneWidget);

        // Tuyệt đối không hiển thị dữ liệu giả PRM393 / SWE302 / Fall 2024 khi chưa chọn môn
        expect(find.textContaining('PRM393'), findsNothing);
        expect(find.textContaining('SWE302'), findsNothing);
        expect(find.textContaining('Fall 2024'), findsNothing);
      },
    );

    testWidgets(
      '2. Setup hồ sơ -> Nhập môn đã học Kỳ 1 -> Tự động chuyển sang Học kỳ 2 -> Lập kế hoạch & Lưu Học kỳ 2',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const EduPlanApp(),
          ),
        );

        // Đăng nhập tài khoản mới
        await tester.tap(find.text('Đăng nhập bằng Google'));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Bước 1: Thiết lập thông tin cá nhân (Persona)
        final completedVm =
            container.read(completedCoursesViewModelProvider.notifier);
        await completedVm.updatePersonalInfo(
          fullName: 'Nguyễn Trọng Hiếu',
          studentId: 'SE180504',
          major: 'Kỹ thuật Phần mềm',
          cohort: 'K18',
          targetGpa: 3.60,
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('GPA mục tiêu: 3.60'), findsOneWidget);

        // Bước 2: Nhập các môn đã học của Học kỳ 1 (PRO192, MAD101, PRM323)
        final pro192 = DatabaseSeeder.sampleCourses
            .firstWhere((c) => c.code == 'PRO192');
        final mad101 = DatabaseSeeder.sampleCourses
            .firstWhere((c) => c.code == 'MAD101');
        final prm323 = DatabaseSeeder.sampleCourses
            .firstWhere((c) => c.code == 'PRM323');

        expect(
          await completedVm.addCompletedCourse(
            semesterIndex: 1,
            course: pro192,
            grade: 8.5,
          ),
          isNull,
        );
        expect(
          await completedVm.addCompletedCourse(
            semesterIndex: 1,
            course: mad101,
            grade: 8.0,
          ),
          isNull,
        );
        expect(
          await completedVm.addCompletedCourse(
            semesterIndex: 1,
            course: prm323,
            grade: 8.2,
          ),
          isNull,
        );
        await tester.pumpAndSettle();

        // Kiểm tra tín chỉ tích lũy = 9/145 TC và học kỳ tự động chuyển thành Học kỳ 2
        expect(find.textContaining('Tích lũy: 9/145 TC'), findsOneWidget);
        expect(find.text('📅 Kế hoạch Học kỳ 2'), findsOneWidget);

        // Bước 3: Thêm các môn đang học của Học kỳ 2 bằng Course Planner (PRM393, CSD201, DBI202)
        // Các môn này đều yêu cầu tiên quyết PRO192 / MAD101 (đã hoàn thành ở Kỳ 1)
        final planVm = container.read(planAnalyzerViewModelProvider.notifier);
        final prm393 = DatabaseSeeder.sampleCourses
            .firstWhere((c) => c.code == 'PRM393');
        final csd201 = DatabaseSeeder.sampleCourses
            .firstWhere((c) => c.code == 'CSD201');
        final dbi202 = DatabaseSeeder.sampleCourses
            .firstWhere((c) => c.code == 'DBI202');

        planVm.applyIncomingCourse(prm393);
        planVm.applyIncomingCourse(csd201);
        planVm.applyIncomingCourse(dbi202);
        await tester.pumpAndSettle();

        final planState = container.read(planAnalyzerViewModelProvider);
        expect(planState.plan.semesterName, 'Học kỳ 2');
        expect(planState.courseCount, 3);
        expect(planState.totalCredits, 9);
        expect(planState.hasConflict, isFalse);

        // Bước 4: Lưu kế hoạch Học kỳ 2
        final saved = await planVm.savePlan();
        expect(saved, isTrue);
        await tester.pumpAndSettle();

        // Kiểm tra Home hiển thị Học kỳ 2 đã lưu kèm dữ liệu môn học thực tế từ kế hoạch
        expect(find.text('📅 Kế hoạch Học kỳ 2'), findsOneWidget);
        expect(find.text('Đã lưu Cloud ✅'), findsOneWidget);
        expect(find.text('Lập trình Di động (PRM393)'), findsOneWidget);
      },
    );

    testWidgets(
      '3. GPA tự động tính từ điểm thang 10 của các môn đã học; Nghiệm thu kỳ học với môn Đạt và môn Rớt',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final studentService = container.read(studentServiceProvider);
        const uid = 'student_test_gpa_journey';

        // 1. Thêm 3 môn vào Kỳ 1:
        // PRO192: 8.5 (A -> 4.0, 3 TC)
        // MAD101: 8.0 (B+ -> 3.5, 3 TC)
        // PRM323: 6.5 (C+ -> 2.5, 3 TC)
        // Trung bình GPA hệ 4 = (4.0*3 + 3.5*3 + 2.5*3) / 9 = 30 / 9 = 3.33
        final pro192 = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'PRO192');
        final mad101 = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'MAD101');
        final prm323 = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'PRM323');

        await studentService.addCompletedCourse(uid: uid, semesterIndex: 1, course: pro192, grade: 8.5);
        await studentService.addCompletedCourse(uid: uid, semesterIndex: 1, course: mad101, grade: 8.0);
        await studentService.addCompletedCourse(uid: uid, semesterIndex: 1, course: prm323, grade: 6.5);

        final profileK1 = await studentService.getStudentProfile(uid);
        expect(profileK1.accumulatedCredits, 9);
        expect(profileK1.currentGpa, 3.33);

        // 2. Nghiệm thu Học kỳ 2 với 2 môn Đạt và 1 môn Rớt:
        // PRM393: Đạt, grade 8.5 (A -> 4.0, 3 TC)
        // CSD201: Đạt, grade 7.0 (B -> 3.0, 3 TC)
        // DBI202: Rớt, grade 3.0 (F -> 0.0, 3 TC)
        // Môn rớt KHÔNG cộng tín chỉ tích lũy: TC = 9 + 6 = 15 TC.
        // Môn rớt KHÔNG nằm trong passedCourseCodes (không mở khóa tiên quyết).
        // Môn rớt VẪN tính vào GPA:
        // Tổng GPA = (30 + 4.0*3 + 3.0*3 + 0.0*3) / 18 = 51 / 18 = 2.83
        final prm393 = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'PRM393');
        final csd201 = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'CSD201');
        final dbi202 = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'DBI202');

        final planK2 = StudyPlanModel(
          id: '${uid}_Hoc_ky_2',
          userId: uid,
          semesterName: 'Học kỳ 2',
          selectedCourses: [prm393, csd201, dbi202],
          updatedAt: DateTime.now(),
        );

        final targetSemester = await studentService.completeSemesterFromPlan(
          uid: uid,
          plan: planK2,
          courseGrades: [
            CourseGradeItem(course: prm393, isPassed: true, grade: 8.5),
            CourseGradeItem(course: csd201, isPassed: true, grade: 7.0),
            CourseGradeItem(course: dbi202, isPassed: false, grade: 3.0),
          ],
        );

        expect(targetSemester, 2); // Đã chuyển lên Kỳ 2

        final profileK2 = await studentService.getStudentProfile(uid);
        expect(profileK2.accumulatedCredits, 15);
        expect(profileK2.passedCourseCodes.contains('PRM393'), isTrue);
        expect(profileK2.passedCourseCodes.contains('CSD201'), isTrue);
        expect(profileK2.passedCourseCodes.contains('DBI202'), isFalse); // Môn rớt không có trong passed codes
        expect(profileK2.currentGpa, 2.83); // Điểm rớt kéo GPA xuống đúng theo chuẩn tín chỉ
      },
    );
  });
}
