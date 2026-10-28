import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/screens/course_catalog_screen.dart';
import 'package:eduplan/services/database_seeder.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/utils/course_filter.dart';
import 'package:eduplan/viewmodels/course_catalog_viewmodel.dart';

/// ViewModel giả: bỏ qua Firestore, trả dữ liệu mẫu (hoặc treo mãi để test loading).
class _FakeCatalogViewModel extends CourseCatalogViewModel {
  final bool never;
  _FakeCatalogViewModel({this.never = false});

  @override
  Future<CourseCatalogState> build() {
    if (never) return Future.any(const []);
    return Future.value(CourseCatalogState(allCourses: DatabaseSeeder.sampleCourses));
  }
}

Widget _app({bool never = false}) {
  return ProviderScope(
    overrides: [
      courseCatalogViewModelProvider.overrideWith(() => _FakeCatalogViewModel(never: never)),
    ],
    child: MaterialApp(
      theme: AppTheme.warmPaperTheme,
      home: const CourseCatalogScreen(),
    ),
  );
}

void main() {
  group('CourseFilter', () {
    final courses = DatabaseSeeder.sampleCourses;

    test('không lọc trả về toàn bộ', () {
      expect(CourseFilter.apply(courses), hasLength(courses.length));
    });

    test('tìm theo mã hoặc tên, không phân biệt hoa thường', () {
      expect(CourseFilter.apply(courses, query: 'prm393').map((c) => c.code), ['PRM393']);
      expect(CourseFilter.apply(courses, query: 'hệ điều hành').map((c) => c.code), ['OSG209']);
    });

    test('từ khóa không khớp trả về rỗng', () {
      expect(CourseFilter.apply(courses, query: 'XYZ99'), isEmpty);
    });

    test('chip Chuyên ngành SE và Cơ sở', () {
      final se = CourseFilter.apply(courses, category: CourseFilter.categorySE);
      final basic = CourseFilter.apply(courses, category: CourseFilter.categoryBasic);
      expect(se.every((c) => c.category.contains('SE')), isTrue);
      expect(basic.map((c) => c.code), containsAll(['OSG209', 'DBI202']));
      expect(se.length + basic.length, courses.length);
    });
  });

  group('CourseCatalogScreen', () {
    testWidgets('hiển thị danh sách môn và nút Chiến lược', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Tìm Môn'), findsOneWidget);
      expect(find.textContaining('PRM393'), findsWidgets);
      expect(find.text('Chiến lược >'), findsWidgets);
    });

    testWidgets('trạng thái loading hiển thị skeleton', (tester) async {
      await tester.pumpWidget(_app(never: true));
      await tester.pump();

      expect(find.bySemanticsLabel('Đang tải danh sách dữ liệu'), findsOneWidget);
      expect(find.text('Chiến lược >'), findsNothing);
    });

    testWidgets('tìm XYZ99 hiện empty state và Xóa bộ lọc khôi phục danh sách', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'XYZ99');
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy môn học nào'), findsOneWidget);
      expect(find.text('Chiến lược >'), findsNothing);

      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy môn học nào'), findsNothing);
      expect(find.text('Chiến lược >'), findsWidgets);
    });

    testWidgets('chip Cơ sở chỉ còn môn cơ sở ngành', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cơ sở'));
      await tester.pumpAndSettle();

      expect(find.textContaining('OSG209'), findsWidgets);
      expect(find.textContaining('PRM393'), findsNothing);
    });
  });
}
