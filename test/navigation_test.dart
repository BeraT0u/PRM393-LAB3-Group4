import 'package:eduplan/screens/completed_courses_screen.dart';
import 'package:eduplan/screens/course_catalog_screen.dart';
import 'package:eduplan/screens/home_screen.dart';
import 'package:eduplan/screens/profile_screen.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({String initialRoute = '/home'}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.warmPaperTheme,
        initialRoute: initialRoute,
        routes: {
          '/home': (_) => const HomeScreen(),
          '/completed-courses': (_) => const CompletedCoursesScreen(),
          '/catalog': (_) => const CourseCatalogScreen(),
          '/profile': (_) => const ProfileScreen(),
        },
      ),
    );
  }

  testWidgets('HomeScreen hiển thị logo app và các nút navigation bar chuyển màn hình mượt mà',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp(initialRoute: '/home'));
    await tester.pumpAndSettle();

    // 1. Kiểm tra màn hình Home hiển thị logo EduPlan (Image.asset) thay vì Icon menu_book
    expect(find.text('EduPlan'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byIcon(Icons.menu_book_rounded), findsNothing);

    // 2. Chuyển sang Tab "Đã học" (index 1)
    await tester.tap(find.text('Đã học'));
    await tester.pumpAndSettle();
    expect(find.text('Môn Đã Học'), findsOneWidget);

    // 3. Chuyển sang Tab "Tìm môn" (index 2)
    await tester.tap(find.text('Tìm môn'));
    await tester.pumpAndSettle();
    expect(find.text('Tìm Môn'), findsOneWidget);

    // 4. Chuyển sang Tab "Cá nhân" (index 3)
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Hồ Sơ Cá Nhân'), findsOneWidget);

    // 5. Quay về Tab "Trang chủ" (index 0)
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    expect(find.text('Chào Hoàng Long 👋'), findsOneWidget);
  });
}
