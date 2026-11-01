import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/models/course_model.dart';
import 'package:eduplan/services/database_seeder.dart';
import 'package:eduplan/screens/course_catalog_screen.dart';
import 'package:eduplan/screens/course_detail_screen.dart';
import 'package:eduplan/screens/plan_analyzer_screen.dart';
import 'package:eduplan/screens/selected_courses_screen.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/widgets/widgets.dart';

void main() {
  group('UC-37: Semantics & Accessibility (WCAG / ARTEMIS) Widget Tests', () {
    testWidgets('1. AppButtons có đầy đủ Semantics flag isButton và label chuẩn', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.warmPaperTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppPrimaryButton(
                  label: 'Lưu Kế Hoạch Học Tập',
                  semanticsLabel: 'Lưu Kế Hoạch Học Tập hợp lệ',
                  onPressed: () {},
                ),
                AppTonalButton(
                  label: 'Xem Chiến Lược',
                  semanticsLabel: 'Xem Chiến Lược môn học',
                  onPressed: () {},
                ),
                AppDestructiveButton(
                  label: 'Xóa môn',
                  semanticsLabel: 'Xóa môn khỏi kế hoạch',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra nút Primary
      final primaryFinder = find.bySemanticsLabel('Lưu Kế Hoạch Học Tập hợp lệ');
      expect(primaryFinder, findsOneWidget);
      final primaryNode = tester.getSemantics(primaryFinder);
      expect(primaryNode.hasFlag(SemanticsFlag.isButton), isTrue);

      // Kiểm tra nút Tonal
      final tonalFinder = find.bySemanticsLabel('Xem Chiến Lược môn học');
      expect(tonalFinder, findsOneWidget);
      final tonalNode = tester.getSemantics(tonalFinder);
      expect(tonalNode.hasFlag(SemanticsFlag.isButton), isTrue);

      // Kiểm tra nút Destructive
      final destructiveFinder = find.bySemanticsLabel('Xóa môn khỏi kế hoạch');
      expect(destructiveFinder, findsOneWidget);
      final destructiveNode = tester.getSemantics(destructiveFinder);
      expect(destructiveNode.hasFlag(SemanticsFlag.isButton), isTrue);

      handle.dispose();
    });

    testWidgets('2. AppSearchBar có Semantics isTextField và Filter Chips có Semantics isButton & selected', (tester) async {
      final handle = tester.ensureSemantics();

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.warmPaperTheme,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: Column(
                children: [
                  const AppSearchBar(
                    hintText: 'Tìm mã môn hoặc tên môn...',
                  ),
                  AppFilterChips(
                    categories: const ['Tất cả', 'Chuyên ngành SE'],
                    selectedCategory: 'Tất cả',
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra SearchBar qua byType(AppSearchBar)
      final searchNode = tester.getSemantics(find.byType(AppSearchBar));
      expect(searchNode.hasFlag(SemanticsFlag.isTextField), isTrue);

      // Kiểm tra Chip 'Tất cả' đang được chọn
      final selectedChip = tester.getSemantics(find.bySemanticsLabel(RegExp(r'Bộ lọc Tất cả')));
      expect(selectedChip.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(selectedChip.hasFlag(SemanticsFlag.isSelected), isTrue);

      // Kiểm tra Chip 'Chuyên ngành SE' chưa được chọn
      final unselectedChip = tester.getSemantics(find.bySemanticsLabel(RegExp(r'Bộ lọc Chuyên ngành SE')));
      expect(unselectedChip.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(unselectedChip.hasFlag(SemanticsFlag.isSelected), isFalse);

      handle.dispose();
    });

    testWidgets('3. CourseStrategyCard có Semantics container với tên và mã môn', (tester) async {
      final handle = tester.ensureSemantics();

      final sampleCourse = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'PRM393');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.warmPaperTheme,
          home: Scaffold(
            body: CourseStrategyCard(
              course: sampleCourse,
              variant: CourseCardVariant.catalog,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Semantics của CourseStrategyCard qua byType
      final cardNode = tester.getSemantics(find.byType(CourseStrategyCard));
      expect(cardNode.label, contains('PRM393'));
      expect(cardNode.label, contains('Lập trình Di động'));

      handle.dispose();
    });

    testWidgets('4. CourseDetailScreen có Semantics chọn mục tiêu điểm A/B/Qua môn chuẩn accessibility', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.warmPaperTheme,
            home: const CourseDetailScreen(courseCode: 'PRM393'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tìm semantics của các mục tiêu điểm
      final targetAFinder = find.byWidgetPredicate((w) =>
          w is Semantics && (w.properties.label?.contains('Mục tiêu Điểm A') ?? false));
      expect(targetAFinder, findsOneWidget);

      final targetANode = tester.getSemantics(targetAFinder);
      expect(targetANode.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(targetANode.hasFlag(SemanticsFlag.isChecked), isTrue); // Mặc định là điểm A

      final targetBFinder = find.byWidgetPredicate((w) =>
          w is Semantics && (w.properties.label?.contains('Mục tiêu Điểm B') ?? false));
      expect(targetBFinder, findsOneWidget);

      final targetBNode = tester.getSemantics(targetBFinder);
      expect(targetBNode.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(targetBNode.hasFlag(SemanticsFlag.isChecked), isFalse);

      handle.dispose();
    });

    testWidgets('5. PlanAnalyzerScreen & Workload Meter có Semantics container giải thích rõ ràng', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.warmPaperTheme,
            home: const PlanAnalyzerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Semantics của Workload Meter
      final meterFinder = find.byWidgetPredicate((w) =>
          w is Semantics &&
          (w.properties.label?.contains('Workload Meter: tổng 34 giờ tự học mỗi tuần') ?? false));
      expect(meterFinder, findsOneWidget);

      final meterNode = tester.getSemantics(meterFinder);
      expect(meterNode.label, contains('vượt ngưỡng an toàn 25 giờ'));

      // Kiểm tra tiêu đề danh sách có Semantics isHeader
      final headerFinder = find.byWidgetPredicate((w) =>
          w is Semantics && w.properties.header == true);
      expect(headerFinder, findsWidgets);

      handle.dispose();
    });

    testWidgets('6. SelectedCoursesScreen có Semantics cho nút lưu và các hành động', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.warmPaperTheme,
            home: const SelectedCoursesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Khi còn xung đột, nút lưu có semantics thông báo bị khóa
      final lockedSaveBtn = find.bySemanticsLabel('Nút lưu bị khóa do có xung đột');
      expect(lockedSaveBtn, findsOneWidget);

      handle.dispose();
    });
  });
}
