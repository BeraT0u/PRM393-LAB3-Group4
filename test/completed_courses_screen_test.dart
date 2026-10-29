import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/models/completed_course_model.dart';
import 'package:eduplan/models/course_model.dart';
import 'package:eduplan/models/student_profile_model.dart';
import 'package:eduplan/screens/completed_courses_screen.dart';
import 'package:eduplan/services/database_seeder.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/viewmodels/completed_courses_viewmodel.dart';
import 'package:eduplan/widgets/widgets.dart';

class _FakeCompletedCoursesViewModel extends CompletedCoursesViewModel {
  final StudentProfileModel testProfile;
  final List<CompletedCourseModel> testCompleted;
  final List<CourseModel> testCatalog;

  _FakeCompletedCoursesViewModel({
    StudentProfileModel? profile,
    List<CompletedCourseModel>? completed,
    List<CourseModel>? catalog,
  })  : testProfile = profile ?? DatabaseSeeder.defaultStudent,
        testCompleted = completed ??
            [
              const CompletedCourseModel(
                code: 'PRO192',
                name: 'Lập trình Hướng đối tượng',
                credits: 3,
                semesterIndex: 1,
                grade: 8.5,
              ),
              const CompletedCourseModel(
                code: 'MAD101',
                name: 'Toán Rời rạc',
                credits: 3,
                semesterIndex: 2,
                grade: 7.5,
              ),
            ],
        testCatalog = catalog ?? DatabaseSeeder.sampleCourses;

  @override
  Future<CompletedCoursesState> build() {
    final completedCodes = testCompleted.map((c) => c.code).toSet();
    final legacy = testProfile.passedCourseCodes
        .where((c) => !completedCodes.contains(c))
        .toSet();

    return Future.value(CompletedCoursesState(
      profile: testProfile,
      completed: List.of(testCompleted),
      legacyPassedCodes: legacy,
      catalog: testCatalog,
    ));
  }

  @override
  Future<String?> addCompletedCourse({
    required int semesterIndex,
    required CourseModel course,
    required double? grade,
  }) async {
    final err = validateAdd(semesterIndex: semesterIndex, course: course);
    if (err != null) return err;
    if (grade == null || grade < 4.0 || grade > 10.0) {
      return 'Điểm tổng kết môn phải từ 4.0 đến 10.0 để được công nhận.';
    }

    testCompleted.add(CompletedCourseModel(
      code: course.code,
      name: course.name,
      credits: course.credits,
      semesterIndex: semesterIndex,
      grade: grade,
    ));

    final current = state.value!;
    state = AsyncData(CompletedCoursesState(
      profile: current.profile.copyWith(
        accumulatedCredits: current.profile.accumulatedCredits + course.credits,
      ),
      completed: List.of(testCompleted),
      legacyPassedCodes: current.legacyPassedCodes,
      catalog: testCatalog,
      selectedFilter: current.selectedFilter,
    ));
    return null;
  }
}

Widget _buildApp({_FakeCompletedCoursesViewModel? vm}) {
  final fakeVm = vm ?? _FakeCompletedCoursesViewModel();
  return ProviderScope(
    overrides: [
      completedCoursesViewModelProvider.overrideWith(() => fakeVm),
    ],
    child: MaterialApp(
      theme: AppTheme.warmPaperTheme,
      home: const CompletedCoursesScreen(),
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
  group('CompletedCoursesScreen (UC-13 & UC-13B)', () {
    testWidgets('UC-13: hiển thị card tiến độ 90/145 TC (62%) và unlock hint', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Tiêu đề & AppBar
      expect(find.text('Môn Đã Học'), findsWidgets);
      expect(find.text('Tiến độ tích lũy tín chỉ tốt nghiệp'), findsOneWidget);

      // Card tiến độ tích lũy 90/145 TC (62%)
      expect(find.text('90'), findsOneWidget);
      expect(find.text(' / 145 TC'), findsOneWidget);
      expect(find.text('62%'), findsOneWidget);

      // Unlock hint: PRO192 đã pass -> mở khóa PRM393
      expect(find.textContaining('Đã hoàn thành PRO192 → mở khóa PRM393'), findsOneWidget);

      // Danh sách môn
      expect(find.text('PRO192'), findsOneWidget);
      expect(find.text('MAD101'), findsOneWidget);
    });

    testWidgets('UC-13: lọc danh sách môn theo Filter Chips', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Kiểm tra filter chips xuất hiện bên trong AppFilterChips
      final chipK1 = find.descendant(of: find.byType(AppFilterChips), matching: find.text('Kỳ 1'));
      final chipK2 = find.descendant(of: find.byType(AppFilterChips), matching: find.text('Kỳ 2'));
      final chipAll = find.descendant(of: find.byType(AppFilterChips), matching: find.text('Tất cả'));

      expect(chipAll, findsOneWidget);
      expect(chipK1, findsOneWidget);
      expect(chipK2, findsOneWidget);

      // Chọn Kỳ 1 -> chỉ hiện PRO192, không hiện MAD101
      await tester.tap(chipK1);
      await tester.pumpAndSettle();

      expect(find.text('PRO192'), findsOneWidget);
      expect(find.text('MAD101'), findsNothing);

      // Chọn Kỳ 2 -> chỉ hiện MAD101, không hiện PRO192
      await tester.tap(chipK2);
      await tester.pumpAndSettle();

      expect(find.text('PRO192'), findsNothing);
      expect(find.text('MAD101'), findsOneWidget);

      // Chọn lại Tất cả -> hiện cả hai
      await tester.tap(chipAll);
      await tester.pumpAndSettle();

      expect(find.text('PRO192'), findsOneWidget);
      expect(find.text('MAD101'), findsOneWidget);
    });

    testWidgets('UC-13B: mở bottom sheet thêm môn và kiểm tra giao diện', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final addBtn = find.text('Thêm môn đã học');
      expect(addBtn, findsOneWidget);

      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Thêm môn đã học'), findsWidgets);
      expect(find.text('Kỳ học'), findsOneWidget);
      expect(find.text('Môn học'), findsOneWidget);
      expect(find.text('Điểm (thang 10)'), findsOneWidget);
      expect(find.text('Thêm môn'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('UC-13B: cảnh báo vi phạm tiên quyết khi chọn môn chưa thỏa', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm môn đã học'));
      await tester.pumpAndSettle();

      // Chọn môn IAE201 (tiên quyết NWC203 chưa học)
      await tester.tap(find.widgetWithText(DropdownButtonFormField<CourseModel>, 'Môn học'));
      await tester.pumpAndSettle();

      final iaeItem = find.textContaining('IAE201').last;
      await tester.tap(iaeItem);
      await tester.pumpAndSettle();

      // Phải xuất hiện cảnh báo yêu cầu hoàn thành NWC203 trước trong AppAlertBanner
      expect(
        find.descendant(of: find.byType(AppAlertBanner), matching: find.textContaining('NWC203')),
        findsOneWidget,
      );
    });

    testWidgets('UC-13B: thêm môn hợp lệ vào Kỳ 2 thành công và cập nhật UI', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm môn đã học'));
      await tester.pumpAndSettle();

      // Chọn Kỳ 2 từ dropdown
      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Kỳ 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kỳ 2').last);
      await tester.pumpAndSettle();

      // Chọn PRM393 (đã học PRO192 ở Kỳ 1 nên hợp lệ)
      await tester.tap(find.widgetWithText(DropdownButtonFormField<CourseModel>, 'Môn học'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('PRM393').last);
      await tester.pumpAndSettle();

      // Không có cảnh báo lỗi banner
      expect(find.byType(AppAlertBanner), findsNothing);

      // Bấm nút "Thêm môn"
      await tester.tap(find.text('Thêm môn'));
      await tester.pumpAndSettle();

      // Đóng sheet và hiển thị SnackBar thành công
      expect(find.textContaining('Đã thêm PRM393 vào Kỳ 2'), findsOneWidget);

      // PRM393 đã xuất hiện trên danh sách
      expect(find.text('PRM393'), findsOneWidget);
    });
  });
}
