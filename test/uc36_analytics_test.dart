import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/models/course_model.dart';
import 'package:eduplan/screens/course_catalog_screen.dart';
import 'package:eduplan/services/analytics_service.dart';
import 'package:eduplan/services/service_providers.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:eduplan/utils/grade_target.dart';
import 'package:eduplan/viewmodels/course_detail_viewmodel.dart';
import 'package:eduplan/viewmodels/plan_analyzer_viewmodel.dart';

/// Test Spy ghi nhận toàn bộ sự kiện Analytics để kiểm thử UC-36
class RecordedAnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  RecordedAnalyticsEvent(this.name, this.parameters);
}

class TestAnalyticsService extends AnalyticsService {
  final List<RecordedAnalyticsEvent> recordedEvents = [];
  String? currentUserId;

  @override
  Future<void> setUserId(String userId) async {
    currentUserId = userId;
  }

  @override
  Future<void> logLogin({String method = 'google'}) async {
    recordedEvents.add(RecordedAnalyticsEvent('login', {'method': method}));
    await super.logLogin(method: method);
  }

  @override
  Future<void> logLogout() async {
    recordedEvents.add(RecordedAnalyticsEvent('logout', {'session_duration_sec': 5}));
    await super.logLogout();
  }

  @override
  Future<void> logSearch({required String searchTerm, required int resultCount}) async {
    recordedEvents.add(RecordedAnalyticsEvent('search', {
      'search_term': searchTerm,
      'result_count': resultCount,
    }));
  }

  @override
  Future<void> logViewCourseDetail({
    required String courseId,
    required String courseName,
    required int credits,
  }) async {
    recordedEvents.add(RecordedAnalyticsEvent('view_course_detail', {
      'course_id': courseId,
      'course_name': courseName,
      'credits': credits,
    }));
  }

  @override
  Future<void> logSelectGradeTarget({
    required String courseId,
    required String targetGrade,
    required double estimatedHours,
  }) async {
    recordedEvents.add(RecordedAnalyticsEvent('select_grade_target', {
      'course_id': courseId,
      'target_grade': targetGrade,
      'planned_hours': estimatedHours.round(),
    }));
  }

  @override
  Future<void> logDetectPlanConflict({
    required int totalHours,
    required String violatedCourseId,
    required String conflictType,
  }) async {
    recordedEvents.add(RecordedAnalyticsEvent('detect_plan_conflict', {
      'total_hours': totalHours,
      'violated_course_id': violatedCourseId,
      'conflict_type': conflictType,
    }));
  }

  @override
  Future<void> logResolvePlanConflict({
    required String oldCourseId,
    required String newCourseId,
    required int newTotalHours,
  }) async {
    recordedEvents.add(RecordedAnalyticsEvent('resolve_plan_conflict', {
      'old_course_id': oldCourseId,
      'new_course_id': newCourseId,
      'new_total_hours': newTotalHours,
    }));
  }

  @override
  Future<void> logExportReport({
    String format = 'pdf',
    required int coursesCount,
    required int totalCredits,
  }) async {
    recordedEvents.add(RecordedAnalyticsEvent('export_report', {
      'format': format,
      'courses_count': coursesCount,
      'total_credits': totalCredits,
    }));
  }
}

void main() {
  group('UC-36: Firebase Analytics Events & Privacy Compliance Tests', () {
    late TestAnalyticsService testAnalytics;

    setUp(() {
      testAnalytics = TestAnalyticsService();
    });

    test('1. AnalyticsService ghi nhận login và setUserId chuẩn anonymous UID không PII', () async {
      await testAnalytics.setUserId('firebase_anon_uid_12345');
      await testAnalytics.logLogin(method: 'google');

      expect(testAnalytics.currentUserId, equals('firebase_anon_uid_12345'));
      expect(testAnalytics.recordedEvents.length, 1);
      final event = testAnalytics.recordedEvents.first;
      expect(event.name, equals('login'));
      expect(event.parameters['method'], equals('google'));
      // Đảm bảo không chứa PII
      expect(event.parameters.containsKey('email'), isFalse);
      expect(event.parameters.containsKey('fullName'), isFalse);
      expect(event.parameters.containsKey('studentId'), isFalse);
    });

    test('2. AnalyticsService ghi nhận search với search_term và result_count', () async {
      await testAnalytics.logSearch(searchTerm: 'PRM393', resultCount: 1);

      expect(testAnalytics.recordedEvents.length, 1);
      final event = testAnalytics.recordedEvents.first;
      expect(event.name, equals('search'));
      expect(event.parameters['search_term'], equals('PRM393'));
      expect(event.parameters['result_count'], equals(1));
    });

    test('3. AnalyticsService ghi nhận view_course_detail và select_grade_target với planned_hours', () async {
      await testAnalytics.logViewCourseDetail(
        courseId: 'PRM393',
        courseName: 'Lập trình Di động',
        credits: 3,
      );
      await testAnalytics.logSelectGradeTarget(
        courseId: 'PRM393',
        targetGrade: 'A',
        estimatedHours: 8.0,
      );

      expect(testAnalytics.recordedEvents.length, 2);
      final viewEvent = testAnalytics.recordedEvents[0];
      expect(viewEvent.name, equals('view_course_detail'));
      expect(viewEvent.parameters['course_id'], equals('PRM393'));
      expect(viewEvent.parameters['credits'], equals(3));

      final selectEvent = testAnalytics.recordedEvents[1];
      expect(selectEvent.name, equals('select_grade_target'));
      expect(selectEvent.parameters['course_id'], equals('PRM393'));
      expect(selectEvent.parameters['target_grade'], equals('A'));
      expect(selectEvent.parameters['planned_hours'], equals(8));
      expect(selectEvent.parameters['planned_hours'], isA<int>());
    });

    test('4. AnalyticsService ghi nhận detect_plan_conflict và resolve_plan_conflict', () async {
      await testAnalytics.logDetectPlanConflict(
        totalHours: 34,
        violatedCourseId: 'IAE201',
        conflictType: 'overload_and_prerequisite',
      );
      await testAnalytics.logResolvePlanConflict(
        oldCourseId: 'IAE201',
        newCourseId: 'PRM323',
        newTotalHours: 26,
      );

      expect(testAnalytics.recordedEvents.length, 2);
      final detectEvent = testAnalytics.recordedEvents[0];
      expect(detectEvent.name, equals('detect_plan_conflict'));
      expect(detectEvent.parameters['total_hours'], equals(34));
      expect(detectEvent.parameters['violated_course_id'], equals('IAE201'));

      final resolveEvent = testAnalytics.recordedEvents[1];
      expect(resolveEvent.name, equals('resolve_plan_conflict'));
      expect(resolveEvent.parameters['old_course_id'], equals('IAE201'));
      expect(resolveEvent.parameters['new_course_id'], equals('PRM323'));
      expect(resolveEvent.parameters['new_total_hours'], equals(26));
    });

    test('5. AnalyticsService ghi nhận logout & export_report', () async {
      await testAnalytics.logLogout();
      await testAnalytics.logExportReport(coursesCount: 5, totalCredits: 15);

      expect(testAnalytics.recordedEvents.length, 2);
      final logoutEvent = testAnalytics.recordedEvents[0];
      expect(logoutEvent.name, equals('logout'));
      expect(logoutEvent.parameters.containsKey('session_duration_sec'), isTrue);

      final exportEvent = testAnalytics.recordedEvents[1];
      expect(exportEvent.name, equals('export_report'));
      expect(exportEvent.parameters['courses_count'], equals(5));
      expect(exportEvent.parameters['total_credits'], equals(15));
      expect(exportEvent.parameters['format'], equals('pdf'));
    });
  });

  group('UC-36: ViewModel & Screen Integration Tests', () {
    test('PlanAnalyzerViewModel tự động phát hiện xung đột và ghi nhận detect_plan_conflict', () {
      final testAnalytics = TestAnalyticsService();
      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(testAnalytics),
        ],
      );
      addTearDown(container.dispose);

      // Đọc ViewModel kích hoạt build()
      final state = container.read(planAnalyzerViewModelProvider);
      expect(state.hasConflict, isTrue);
      expect(state.totalHours, equals(34.0));

      // Kiểm tra sự kiện detect_plan_conflict được ghi nhận
      final hasDetect = testAnalytics.recordedEvents.any((e) =>
          e.name == 'detect_plan_conflict' &&
          e.parameters['violated_course_id'] == 'IAE201' &&
          e.parameters['total_hours'] == 34);
      expect(hasDetect, isTrue);

      // Giải quyết xung đột (đổi môn sang PRM323)
      container.read(planAnalyzerViewModelProvider.notifier).replaceConflictCourse();

      final hasResolve = testAnalytics.recordedEvents.any((e) =>
          e.name == 'resolve_plan_conflict' &&
          e.parameters['old_course_id'] == 'IAE201' &&
          e.parameters['new_course_id'] == 'PRM323' &&
          e.parameters['new_total_hours'] == 26);
      expect(hasResolve, isTrue);
    });

    test('CourseDetailViewModel ghi nhận view_course_detail và select_grade_target khi đổi mục tiêu', () async {
      final testAnalytics = TestAnalyticsService();
      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(testAnalytics),
        ],
      );
      addTearDown(container.dispose);

      // Load CourseDetailViewModel cho PRM393
      final provider = courseDetailViewModelProvider('PRM393');
      final state = await container.read(provider.future);
      expect(state.course.code, equals('PRM393'));

      // Kiểm tra view_course_detail đã được ghi nhận
      final hasView = testAnalytics.recordedEvents.any((e) =>
          e.name == 'view_course_detail' && e.parameters['course_id'] == 'PRM393');
      expect(hasView, isTrue);

      // Đổi mục tiêu điểm sang B
      container.read(provider.notifier).selectTarget(GradeTargetOption.gradeB);

      final hasSelectB = testAnalytics.recordedEvents.any((e) =>
          e.name == 'select_grade_target' &&
          e.parameters['course_id'] == 'PRM393' &&
          e.parameters['target_grade'] == 'B');
      expect(hasSelectB, isTrue);
    });

    testWidgets('CourseCatalogScreen kích hoạt sự kiện search sau khi debounce dừng gõ', (tester) async {
      final testAnalytics = TestAnalyticsService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsServiceProvider.overrideWithValue(testAnalytics),
          ],
          child: MaterialApp(
            theme: AppTheme.warmPaperTheme,
            home: const CourseCatalogScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nhập từ khóa tìm kiếm
      final searchField = find.byType(TextFormField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'PRM');
      await tester.pump();

      // Ngay sau khi gõ, chưa quá 800ms nên chưa log
      expect(testAnalytics.recordedEvents.where((e) => e.name == 'search'), isEmpty);

      // Chờ qua khoảng debounce 800ms
      await tester.pump(const Duration(milliseconds: 900));

      // Đã ghi nhận sự kiện search
      final searchEvents = testAnalytics.recordedEvents.where((e) => e.name == 'search').toList();
      expect(searchEvents.length, equals(1));
      expect(searchEvents.first.parameters['search_term'], equals('PRM'));
    });
  });
}
