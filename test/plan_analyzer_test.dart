import 'package:eduplan/screens/plan_analyzer_screen.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableScreen() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.warmPaperTheme,
        home: const PlanAnalyzerScreen(),
        routes: {
          '/selected-courses': (_) => const Scaffold(body: Text('SCR-06B Môn Đã Chọn')),
        },
      ),
    );
  }

  group('SCR-06A PlanAnalyzerScreen Tests (UC-20, UC-21, UC-22)', () {
    testWidgets('UC-20: Hiển thị banner báo động đỏ quá tải & vi phạm tiên quyết', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình
      expect(find.text('Phân Tích Kế Hoạch'), findsOneWidget);

      // UC-20: Banner báo động đỏ
      expect(find.text('⚠️ Cảnh báo: Vi phạm tiên quyết & Quá tải!'), findsOneWidget);
    });

    testWidgets('UC-21: Thẻ Workload Meter đo lường 34h vượt ngưỡng an toàn 25h', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // UC-21: Workload Meter
      expect(find.text('Workload Meter'), findsOneWidget);
      expect(find.text('Quá tải ⚠️'), findsOneWidget);
      expect(find.text('Tổng giờ tự học: 34 giờ / tuần'), findsOneWidget);
      expect(find.text('Vượt ngưỡng an toàn (Khuyến nghị: 25h/tuần)'), findsOneWidget);
      expect(find.text('Ngưỡng an toàn: 25h'), findsOneWidget);
    });

    testWidgets('UC-22: Danh sách 4 môn, trong đó có thẻ lỗi đỏ IAE201', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
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
