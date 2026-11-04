import 'package:eduplan/screens/plan_analyzer_screen.dart';
import 'package:eduplan/services/database_seeder.dart';
import 'package:eduplan/services/plan_service.dart';
import 'package:eduplan/services/service_providers.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/viewmodels/plan_analyzer_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlanService planService;

  setUp(() {
    planService = PlanService();
  });

  Widget buildTestableScreen({bool seedConflictPlan = false}) {
    if (seedConflictPlan) {
      planService.saveLocalDraftPlan(
        DatabaseSeeder.getInitialConflictPlan(
          DatabaseSeeder.defaultStudent.uid,
        ),
      );
    }
    return ProviderScope(
      overrides: [
        planServiceProvider.overrideWithValue(planService),
      ],
      child: MaterialApp(
        theme: AppTheme.warmPaperTheme,
        home: const PlanAnalyzerScreen(),
        routes: {
          '/selected-courses': (_) =>
              const Scaffold(body: Text('SCR-06B Môn Đã Chọn')),
          '/catalog': (_) => const Scaffold(body: Text('SCR-04 Tìm Môn')),
        },
      ),
    );
  }

  group('SCR-06A PlanAnalyzerScreen Dynamic & Conflict Tests (UC-20, UC-21, UC-22)', () {
    testWidgets(
      'Bắt đầu ở 0 môn -> Hiện nút Thêm môn góc trên phải -> Thêm dần từng môn tới khi báo đỏ thì ẩn nút Thêm môn',
      (tester) async {
        await tester.pumpWidget(buildTestableScreen(seedConflictPlan: false));
        await tester.pumpAndSettle();

        // 1. Trạng thái 0 môn được chọn
        expect(find.text('Chưa có môn học nào được chọn'), findsOneWidget);
        expect(find.text('Tổng giờ tự học: 0 giờ / tuần'), findsOneWidget);
        // Không báo đỏ -> Có nút "Thêm môn" ở góc trên phải
        expect(find.byKey(const Key('btn_add_course_top_right')), findsOneWidget);
        expect(find.text('Thêm môn'), findsOneWidget);

        // 2. Thêm môn thứ 1: PRM393 (8h) -> Vẫn cân bằng (8h <= 25h), vẫn hiện nút Thêm môn
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PlanAnalyzerScreen)),
        );
        final vm = container.read(planAnalyzerViewModelProvider.notifier);

        final prm393 =
            DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'PRM393');
        vm.applyIncomingCourse(prm393);
        await tester.pumpAndSettle();

        expect(find.text('Tổng giờ tự học: 8 giờ / tuần'), findsOneWidget);
        expect(
          find.text('Kế hoạch học tập cân bằng & hợp lệ (0 Xung đột) ✅'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn_add_course_top_right')), findsOneWidget);

        // 3. Thêm môn gây xung đột (IAE201 thiếu tiên quyết & thêm SWE302, AIE411 vượt 25h) -> Báo đỏ & ẩn nút Thêm môn góc phải
        final swe302 =
            DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'SWE302');
        final aie411 =
            DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'AIE411');
        final iae201 =
            DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'IAE201');
        vm.applyIncomingCourse(swe302);
        vm.applyIncomingCourse(aie411);
        vm.applyIncomingCourse(iae201);
        await tester.pumpAndSettle();

        expect(
          find.text('⚠️ Cảnh báo: Vi phạm tiên quyết & Quá tải!'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn_add_course_top_right')), findsNothing);
      },
    );

    testWidgets('UC-20: Hiển thị banner báo động đỏ quá tải & vi phạm tiên quyết', (tester) async {
      await tester.pumpWidget(buildTestableScreen(seedConflictPlan: true));
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình
      expect(find.text('Phân Tích Kế Hoạch'), findsOneWidget);

      // UC-20: Banner báo động đỏ
      expect(find.text('⚠️ Cảnh báo: Vi phạm tiên quyết & Quá tải!'), findsOneWidget);
    });

    testWidgets('UC-21: Thẻ Workload Meter đo lường 34h vượt ngưỡng an toàn 25h', (tester) async {
      await tester.pumpWidget(buildTestableScreen(seedConflictPlan: true));
      await tester.pumpAndSettle();

      // UC-21: Workload Meter
      expect(find.text('Workload Meter'), findsOneWidget);
      expect(find.text('Quá tải ⚠️'), findsOneWidget);
      expect(find.text('Tổng giờ tự học: 34 giờ / tuần'), findsOneWidget);
      expect(find.text('Vượt ngưỡng an toàn (Khuyến nghị: 25h/tuần)'), findsOneWidget);
      expect(find.text('Ngưỡng an toàn: 25h'), findsOneWidget);
    });

    testWidgets('UC-22: Danh sách 4 môn, trong đó có thẻ lỗi đỏ IAE201', (tester) async {
      await tester.pumpWidget(buildTestableScreen(seedConflictPlan: true));
      await tester.pumpAndSettle();

      // 4 môn trong kế hoạch ban đầu
      expect(find.text('PRM393 • Mục tiêu A'), findsOneWidget);
      expect(find.text('SWE302 • Mục tiêu B'), findsOneWidget);
      expect(find.text('AIE411 • Mục tiêu A'), findsOneWidget);

      // Thẻ lỗi đỏ IAE201
      expect(find.text('IAE201 (An toàn Thông tin)'), findsOneWidget);
      expect(find.textContaining('LỖI: Chưa học tiên quyết NWC203'), findsOneWidget);

      // Nút điều chỉnh chân trang
      final adjustBtn = find.text('Điều chỉnh kế hoạch (4 môn) ➔');
      expect(adjustBtn, findsOneWidget);

      // Bấm nút điều hướng sang SCR-06B
      await tester.tap(adjustBtn);
      await tester.pumpAndSettle();
      expect(find.text('SCR-06B Môn Đã Chọn'), findsOneWidget);
    });
  });
}
