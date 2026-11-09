import 'package:eduplan/models/ai_plan_advice_model.dart';
import 'package:eduplan/models/course_model.dart';
import 'package:eduplan/screens/plan_analyzer_screen.dart';
import 'package:eduplan/services/ai_advisor_service.dart';
import 'package:eduplan/services/database_seeder.dart';
import 'package:eduplan/services/plan_service.dart';
import 'package:eduplan/services/service_providers.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/viewmodels/plan_analyzer_viewmodel.dart';
import 'package:eduplan/widgets/ai_advisor_modal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAiAdvisorService extends AiAdvisorService {
  @override
  Future<AiPlanAdviceModel> analyzePlanAndAdvise({
    required PlanAnalyzerState state,
    required List<CourseModel> allCourses,
  }) async {
    return const AiPlanAdviceModel(
      provider: 'gemini',
      riskLevel: 'high',
      analysis: 'Thời gian tự học 34h/tuần vượt quá ngưỡng an toàn 25h/tuần.',
      recommendedAction: 'replace',
      targetCourseCode: 'IAE201',
      suggestedCourseCode: 'PRM323',
      estimatedHoursAfter: 26.0,
      reason: 'Thay IAE201 bằng PRM323 để giảm 8h tự học.',
      strategicTips: [
        'Ưu tiên làm assignment môn chuyên ngành trước tuần 7.',
        'Sắp xếp 2h ôn bài xen kẽ các ngày trong tuần.',
      ],
    );
  }
}

class ReduceHoursMockAiAdvisorService extends AiAdvisorService {
  final AiPlanAdviceModel advice;
  ReduceHoursMockAiAdvisorService(this.advice);

  @override
  Future<AiPlanAdviceModel> analyzePlanAndAdvise({
    required PlanAnalyzerState state,
    required List<CourseModel> allCourses,
  }) async {
    return advice;
  }
}

void main() {
  late PlanService planService;
  late MockAiAdvisorService mockAiService;

  setUp(() {
    planService = PlanService();
    mockAiService = MockAiAdvisorService();
  });

  Widget buildTestableWidget({required Widget child, bool seedConflict = true}) {
    if (seedConflict) {
      planService.saveLocalDraftPlan(
        DatabaseSeeder.getInitialConflictPlan(
          DatabaseSeeder.defaultStudent.uid,
        ),
      );
    }
    return ProviderScope(
      overrides: [
        planServiceProvider.overrideWithValue(planService),
        aiAdvisorServiceProvider.overrideWithValue(mockAiService),
      ],
      child: MaterialApp(
        theme: AppTheme.warmPaperTheme,
        home: child,
      ),
    );
  }

  group('AI Advisor & Plan Analyzer Integration Tests', () {
    testWidgets('PlanAnalyzerScreen hiển thị banner AI khi có xung đột và mở Modal Sheet',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PlanAnalyzerScreen(),
          seedConflict: true,
        ),
      );
      await tester.pumpAndSettle();

      // Banner Cố vấn AI hiển thị khi có xung đột
      expect(find.text('Cố vấn AI (Gemini & DeepSeek)'), findsOneWidget);
      expect(find.text('Tư vấn ngay'), findsOneWidget);

      // Bấm vào nút Tư vấn ngay
      await tester.tap(find.text('Tư vấn ngay'));
      await tester.pumpAndSettle();

      // Modal Bottom Sheet mở ra
      expect(find.byType(AiAdvisorModalSheet), findsOneWidget);
      expect(find.text('Cố Vấn Học Tập AI'), findsOneWidget);
      expect(find.text('Google Gemini 3.8 Flash'), findsOneWidget);

      // Hiển thị đề xuất thay môn IAE201 -> PRM323
      expect(find.text('IAE201 (Nặng)'), findsOneWidget);
      expect(find.text('PRM323 (Cân bằng)'), findsOneWidget);
      expect(find.text('Áp Dụng Gợi Ý Này'), findsOneWidget);

      // Bấm nút Áp Dụng Gợi Ý Này
      await tester.tap(find.text('Áp Dụng Gợi Ý Này'));
      await tester.pumpAndSettle();

      // BottomSheet đóng lại, plan được cập nhật: môn IAE201 đã được đổi thành PRM323
      expect(find.byType(AiAdvisorModalSheet), findsNothing);
      expect(find.textContaining('IAE201'), findsNothing);
      expect(find.textContaining('PRM323'), findsWidgets);
    });

    testWidgets('AiAdvisorModalSheet hiển thị đầy đủ chiến lược học tập và mẹo từ AI',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(body: AiAdvisorModalSheet()),
          seedConflict: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mẹo chiến lược từ Cố vấn:'), findsOneWidget);
      expect(
        find.text('• Ưu tiên làm assignment môn chuyên ngành trước tuần 7.'),
        findsOneWidget,
      );
      expect(
        find.text('• Sắp xếp 2h ôn bài xen kẽ các ngày trong tuần.'),
        findsOneWidget,
      );
    });

    testWidgets('AiAdvisorModalSheet áp dụng gợi ý giảm giờ tự học (reduce_hours) và cập nhật tổng giờ an toàn',
        (tester) async {
      planService.saveLocalDraftPlan(
        DatabaseSeeder.getInitialConflictPlan(
          DatabaseSeeder.defaultStudent.uid,
        ),
      );

      final reduceAdvice = const AiPlanAdviceModel(
        provider: 'gemini',
        riskLevel: 'high',
        analysis: 'Kế hoạch học tập 27.5h/tuần vượt nhẹ ngưỡng an toàn 25h/tuần.',
        recommendedAction: 'reduce_hours',
        estimatedHoursAfter: 23.5,
        adjustedHours: {'PRM393': 6.0, 'SWE302': 5.5},
        hoursReductions: [
          {'code': 'PRM393', 'oldHours': 8.0, 'newHours': 6.0, 'saved': 2.0},
          {'code': 'SWE302', 'oldHours': 7.0, 'newHours': 5.5, 'saved': 1.5},
        ],
        reason: 'Giảm giờ tự học các môn nặng đưa về 23.5h/tuần an toàn.',
      );

      final customMockService = ReduceHoursMockAiAdvisorService(reduceAdvice);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planServiceProvider.overrideWithValue(planService),
            aiAdvisorServiceProvider.overrideWithValue(customMockService),
          ],
          child: MaterialApp(
            theme: AppTheme.warmPaperTheme,
            home: const PlanAnalyzerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mở modal sheet với lời khuyên giảm giờ
      await tester.tap(find.text('Tư vấn ngay'));
      await tester.pumpAndSettle();

      expect(find.text('Đề xuất: Giảm thời gian tự học môn học'), findsOneWidget);
      expect(find.text('PRM393'), findsOneWidget);
      expect(find.text('6h/tuần'), findsWidgets);
      expect(find.text('Áp Dụng Gợi Ý Này'), findsOneWidget);

      // Bấm nút áp dụng giảm giờ
      await tester.tap(find.text('Áp Dụng Gợi Ý Này'));
      await tester.pumpAndSettle();

      // Modal sheet đóng lại
      expect(find.byType(AiAdvisorModalSheet), findsNothing);
    });
  });
}
