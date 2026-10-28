import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/models/course_model.dart';
import 'package:eduplan/screens/course_detail_screen.dart';
import 'package:eduplan/services/database_seeder.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/utils/grade_target.dart';
import 'package:eduplan/viewmodels/course_detail_viewmodel.dart';

/// ViewModel giả: bỏ qua Firestore, dùng dữ liệu mẫu.
class _FakeDetailViewModel extends CourseDetailViewModel {
  final bool prerequisiteMet;
  _FakeDetailViewModel(super.courseCode, {this.prerequisiteMet = true});

  @override
  Future<CourseDetailState> build() {
    final course = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == courseCode);
    return Future.value(CourseDetailState(
      course: course,
      target: GradeTargetOption.fromCode(course.selectedGradeTarget),
      prerequisiteMet: prerequisiteMet,
    ));
  }
}

CourseModel _course(String code) =>
    DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == code);

Widget _app({
  String code = 'PRM393',
  bool prerequisiteMet = true,
  void Function(RouteSettings)? onRoute,
}) {
  return ProviderScope(
    overrides: [
      courseDetailViewModelProvider(code)
          .overrideWith(() => _FakeDetailViewModel(code, prerequisiteMet: prerequisiteMet)),
    ],
    child: MaterialApp(
      theme: AppTheme.warmPaperTheme,
      home: CourseDetailScreen(courseCode: code),
      onGenerateRoute: (settings) {
        onRoute?.call(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('PLAN_ANALYZER')),
        );
      },
    ),
  );
}

void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('GradeTargetOption', () {
    test('PRM393 (8h): A = 8h, B = 5h, Qua môn = 3.5h', () {
      final c = _course('PRM393');
      expect(GradeTargetOption.gradeA.hoursFor(c), 8.0);
      expect(GradeTargetOption.gradeB.hoursFor(c), 5.0);
      expect(GradeTargetOption.pass.hoursFor(c), 3.5);
    });

    test('mã lạ quay về mức A và định dạng giờ', () {
      expect(GradeTargetOption.fromCode('???').code, 'A');
      expect(GradeTargetOption.formatHours(8), '8h');
      expect(GradeTargetOption.formatHours(3.5), '3.5h');
    });
  });

  group('CourseDetailScreen', () {
    testWidgets('UC-16/17: header, badge, cấu trúc điểm 40/30/30 và tips', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Lập trình Di động (PRM393)'), findsOneWidget);
      expect(find.text('3 Tín chỉ'), findsOneWidget);
      expect(find.text('Độ khó: 4/5 ⭐'), findsOneWidget);
      expect(find.text('Tiên quyết: PRO192 ✅'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('30%'), findsNWidgets(2));
      expect(find.textContaining('Tips học tập'), findsOneWidget);
      // Ẩn hoàn toàn Bottom Bar
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('tiên quyết chưa học hiện badge cảnh báo', (tester) async {
      await tester.pumpWidget(_app(prerequisiteMet: false));
      await tester.pumpAndSettle();

      expect(find.textContaining('PRO192 ❌'), findsOneWidget);
    });

    testWidgets('UC-18: chọn mục tiêu cập nhật giờ tự học dự kiến', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Giờ tự học dự kiến: 8h/tuần'), findsOneWidget);

      await tester.tap(find.textContaining('Mục tiêu: Điểm B'));
      await tester.pumpAndSettle();
      expect(find.text('Giờ tự học dự kiến: 5h/tuần'), findsOneWidget);

      await tester.tap(find.textContaining('Mục tiêu: Qua môn'));
      await tester.pumpAndSettle();
      expect(find.text('Giờ tự học dự kiến: 3.5h/tuần'), findsOneWidget);
    });

    testWidgets('UC-19: yêu thích đổi trạng thái; Thêm vào Kế hoạch sang SCR-06A', (tester) async {
      _useTallScreen(tester);
      RouteSettings? pushed;
      await tester.pumpWidget(_app(onRoute: (s) => pushed = s));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      // Chọn mục tiêu B rồi thêm vào kế hoạch: môn gửi đi mang mục tiêu và giờ đã chọn
      await tester.tap(find.textContaining('Mục tiêu: Điểm B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm vào Kế hoạch'));
      await tester.pumpAndSettle();

      expect(pushed?.name, '/plan-analyzer');
      final sent = pushed!.arguments as CourseModel;
      expect(sent.code, 'PRM393');
      expect(sent.selectedGradeTarget, 'B');
      expect(sent.plannedSelfStudyHours, 5.0);
      expect(find.text('PLAN_ANALYZER'), findsOneWidget);
    });
  });
}
