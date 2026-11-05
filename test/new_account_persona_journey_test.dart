import 'package:eduplan/main.dart';
import 'package:eduplan/services/database_seeder.dart';
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
          currentGpa: 3.20,
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
  });
}
