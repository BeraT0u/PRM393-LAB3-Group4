import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eduplan/main.dart';

void main() {
  testWidgets('UC-08: SCR-01 Login screen & SCR-01_Loading state smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EduPlanApp(),
      ),
    );

    // Kiểm tra các thành phần chính trên màn hình SCR-01 Login
    expect(find.text('EduPlan'), findsOneWidget);
    expect(find.text('Lên lịch học thật dễ!'), findsOneWidget);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
    expect(find.text('Xếp lịch thông minh'), findsOneWidget);
    expect(find.text('Không trùng môn'), findsOneWidget);

    // Chạm nút Đăng nhập để kiểm tra trạng thái SCR-01_Loading
    await tester.tap(find.text('Đăng nhập bằng Google'));
    await tester.pump();
    expect(find.text('Đang xác thực Google...'), findsOneWidget);

    // Đợi chuyển màn hình hoàn tất
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
