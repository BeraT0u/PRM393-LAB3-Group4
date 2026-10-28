import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eduplan/main.dart';

void main() {
  testWidgets('EduPlanApp launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EduPlanApp(),
      ),
    );

    // Kiểm tra tiêu đề hoặc nút trên màn hình Login
    expect(find.text('EduPlan'), findsOneWidget);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
  });
}
