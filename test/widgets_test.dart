import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/models/course_model.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/widgets/widgets.dart';

void main() {
  const sampleCourse = CourseModel(
    id: 'PRM393',
    code: 'PRM393',
    name: 'Lập trình Di động',
    credits: 3,
    difficulty: 4.0,
    defaultSelfStudyHours: 8,
    prerequisiteCode: 'PRO192',
    category: 'Chuyên ngành SE',
    assessmentBreakdown: {'Đồ án': 40, 'Lab': 30, 'FE': 30},
    studyTips: ['Tip 1'],
    selectedGradeTarget: 'A',
    plannedSelfStudyHours: 8.0,
  );

  testWidgets('UC-01 & UC-04: AppButtons and StatusBadge render properly', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.warmPaperTheme,
        home: Scaffold(
          body: Column(
            children: [
              AppPrimaryButton(
                label: 'Lưu Kế Hoạch Học Tập',
                onPressed: () => tapped = true,
              ),
              const AppTonalButton(label: 'Chiến lược >'),
              const AppDestructiveButton(label: '⇄ Đổi môn khác'),
              const StatusBadge(
                label: 'Mục tiêu: Điểm A',
                type: StatusBadgeType.success,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Lưu Kế Hoạch Học Tập'), findsOneWidget);
    expect(find.text('Chiến lược >'), findsOneWidget);
    expect(find.text('⇄ Đổi môn khác'), findsOneWidget);
    expect(find.text('Mục tiêu: Điểm A'), findsOneWidget);

    await tester.tap(find.text('Lưu Kế Hoạch Học Tập'));
    expect(tapped, isTrue);
  });

  testWidgets('UC-02 & UC-05: CourseStrategyCard & AppAlertBanner render conflict state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.warmPaperTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AppAlertBanner(
                  message: '⚠️ Cảnh báo: Vi phạm tiên quyết & Quá tải!',
                ),
                CourseStrategyCard(
                  course: sampleCourse,
                  variant: CourseCardVariant.selected,
                  hasConflict: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('⚠️ Cảnh báo: Vi phạm tiên quyết & Quá tải!'), findsOneWidget);
    expect(find.text('Lập trình Di động (PRM393)'), findsOneWidget);
    expect(find.text('⇄ Đổi môn khác'), findsOneWidget);
  });

  testWidgets('UC-03, UC-06 & UC-07: SearchBar, FilterChips, EmptyState & MainScaffold', (tester) async {
    String selectedCat = 'Tất cả';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.warmPaperTheme,
        home: MainScaffold(
          appBar: const AppTopBar(
            title: 'EduPlan',
            subtitle: 'Trang Chủ',
            showLogo: true,
          ),
          body: Column(
            children: [
              const AppSearchBar(),
              AppFilterChips(
                categories: const ['Tất cả', 'Chuyên ngành SE', 'Cơ sở'],
                selectedCategory: selectedCat,
                onSelected: (val) => selectedCat = val,
              ),
              const Expanded(
                child: AppEmptyState(
                  title: 'Không tìm thấy môn học nào',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('EduPlan'), findsOneWidget);
    expect(find.text('Chuyên ngành SE'), findsOneWidget);
    expect(find.text('Không tìm thấy môn học nào'), findsOneWidget);

    await tester.tap(find.text('Chuyên ngành SE'));
    expect(selectedCat, equals('Chuyên ngành SE'));
  });
}
