import 'package:eduplan/models/study_plan_model.dart';
import 'package:eduplan/screens/course_catalog_screen.dart';
import 'package:eduplan/screens/selected_courses_screen.dart';
import 'package:eduplan/services/plan_service.dart';
import 'package:eduplan/services/service_providers.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/widgets/course_strategy_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlanService extends PlanService {
  StudyPlanModel? savedPlan;

  @override
  Future<void> saveStudyPlan(StudyPlanModel plan) async {
    savedPlan = plan;
  }
}

void main() {
  late _FakePlanService fakePlanService;

  setUp(() {
    fakePlanService = _FakePlanService();
  });

  Widget buildTestableScreen() {
    return ProviderScope(
      overrides: [
        planServiceProvider.overrideWithValue(fakePlanService),
      ],
      child: MaterialApp(
        theme: AppTheme.warmPaperTheme,
        home: const SelectedCoursesScreen(),
        routes: {
          '/selected-courses': (_) => const SelectedCoursesScreen(),
          '/catalog': (_) => const CourseCatalogScreen(),
          '/summary': (_) => const Scaffold(body: Text('SCR-07 Tổng Kết Kế Hoạch')),
        },
      ),
    );
  }

  group('SCR-06B SelectedCoursesScreen Tests (UC-23, UC-24, UC-25)', () {
    testWidgets('UC-23: State lỗi: Nút Lưu BỊ KHÓA và môn IAE201 có nút Đổi môn khác', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình
      expect(find.text('Môn Đã Chọn'), findsOneWidget);

      // Thẻ tổng quan hiển thị 34h và xung đột
      expect(find.text('4 Môn • 12 Tín chỉ'), findsOneWidget);
      expect(find.text('1 Xung đột ⚠️'), findsOneWidget);
      expect(find.text('Tổng khối lượng: 34h/tuần (Quá tải)'), findsOneWidget);

      // Thẻ lỗi IAE201 có nút Đổi môn khác
      expect(find.text('An toàn Thông tin (IAE201)'), findsOneWidget);
      final replaceBtn = find.text('⇄ Đổi môn khác');
      expect(replaceBtn, findsOneWidget);

      // Nút Lưu chân trang BỊ KHÓA
      final lockedBtn = find.text('🔒 Giải quyết 1 xung đột để lưu');
      expect(lockedBtn, findsOneWidget);

      // Thử tap nút bị khóa -> Không lưu và không đổi màn hình
      await tester.tap(lockedBtn);
      await tester.pump();
      expect(fakePlanService.savedPlan, isNull);
    });

    testWidgets('UC-24 & UC-25: Bấm Đổi môn khác -> quay về Course Catalog (auto filter tiên quyết) -> chọn PRM323 mở khóa Lưu', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Bấm nút "⇄ Đổi môn khác"
      final replaceBtn = find.text('⇄ Đổi môn khác');
      await tester.tap(replaceBtn);
      await tester.pumpAndSettle();

      // Chuyển sang màn hình Course Catalog
      expect(find.text('Tìm Môn'), findsOneWidget);
      expect(find.text('Đã xong tiên quyết'), findsOneWidget);
      expect(find.textContaining('Đổi môn cho IAE201'), findsOneWidget);

      // Chỉ hiển thị các môn hợp lệ (PRM323 có trong danh sách)
      expect(find.textContaining('PRM323'), findsWidgets);

      // Bấm vào môn PRM323
      final prm323Card = find.widgetWithText(CourseStrategyCard, 'Thiết kế Giao diện UI/UX (PRM323)');
      await tester.tap(prm323Card);
      await tester.pumpAndSettle();

      // Hộp thoại xác nhận đổi sang môn này
      expect(find.text('Đổi sang môn này?'), findsOneWidget);
      final confirmBtn = find.text('Đổi sang PRM323');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Dọn dẹp SnackBar thông báo để không che nút Lưu chân trang
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
      await tester.pumpAndSettle();

      // UC-24: Kiểm tra trạng thái đã giải quyết (SCR-06B_Resolved)
      expect(find.text('Cân bằng ✅'), findsOneWidget);
      expect(find.text('Tổng khối lượng: 26h tự học/tuần (Cân bằng ✅)'), findsOneWidget);
      expect(find.text('Thiết kế Giao diện UI/UX (PRM323)'), findsOneWidget);

      // Nút Lưu Kế Hoạch đã MỞ KHÓA MÀU XANH ACTIVE
      final saveBtn = find.text('Lưu Kế Hoạch Học Tập');
      expect(saveBtn, findsOneWidget);
      expect(find.text('🔒 Giải quyết 1 xung đột để lưu'), findsNothing);

      // UC-25: Bấm Lưu Kế Hoạch Học Tập
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Xác minh đã gọi PlanService để lưu kế hoạch vào Firestore
      expect(fakePlanService.savedPlan, isNotNull);
      expect(fakePlanService.savedPlan!.isSaved, isTrue);
      expect(fakePlanService.savedPlan!.totalSelfStudyHours, 26.0);

      // Xác minh đã điều hướng sang SCR-07
      expect(find.text('SCR-07 Tổng Kết Kế Hoạch'), findsOneWidget);
    });
  });
}
