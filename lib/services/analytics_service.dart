import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/app_logger.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      AppLogger.info('Analytics: Đã gắn userId = $userId');
    } catch (e) {
      AppLogger.warning('Analytics setUserId error: $e');
    }
  }

  Future<void> logLogin({String method = 'google'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      AppLogger.info('Analytics: Đã ghi nhận sự kiện login');
    } catch (e) {
      AppLogger.warning('Analytics logLogin error: $e');
    }
  }

  Future<void> logSearch({required String searchTerm, required int resultCount}) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: {'result_count': resultCount},
      );
      AppLogger.info('Analytics: Đã ghi nhận search ($searchTerm, $resultCount)');
    } catch (e) {
      AppLogger.warning('Analytics logSearch error: $e');
    }
  }

  Future<void> logViewCourseDetail({
    required String courseId,
    required String courseName,
    required int credits,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'view_course_detail',
        parameters: {
          'course_id': courseId,
          'course_name': courseName,
          'credits': credits,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics logViewCourseDetail error: $e');
    }
  }

  Future<void> logSelectGradeTarget({
    required String courseId,
    required String targetGrade,
    required int plannedHours,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'select_grade_target',
        parameters: {
          'course_id': courseId,
          'target_grade': targetGrade,
          'planned_hours': plannedHours,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics logSelectGradeTarget error: $e');
    }
  }

  Future<void> logDetectPlanConflict({
    required int totalHours,
    required String violatedCourseId,
    required String conflictType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'detect_plan_conflict',
        parameters: {
          'total_hours': totalHours,
          'violated_course_id': violatedCourseId,
          'conflict_type': conflictType,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics logDetectPlanConflict error: $e');
    }
  }

  Future<void> logResolvePlanConflict({
    required String oldCourseId,
    required String newCourseId,
    required int newTotalHours,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'resolve_plan_conflict',
        parameters: {
          'old_course_id': oldCourseId,
          'new_course_id': newCourseId,
          'new_total_hours': newTotalHours,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics logResolvePlanConflict error: $e');
    }
  }

  Future<void> logExportReport({
    String format = 'PDF_A4',
    required int coursesCount,
    required int totalCredits,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'export_report',
        parameters: {
          'format': format,
          'courses_count': coursesCount,
          'total_credits': totalCredits,
        },
      );
      AppLogger.info('Analytics: Đã ghi nhận export_report');
    } catch (e) {
      AppLogger.warning('Analytics logExportReport error: $e');
    }
  }

  Future<void> logLogout({int sessionDurationSec = 0}) async {
    try {
      await _analytics.logEvent(
        name: 'logout',
        parameters: {'session_duration_sec': sessionDurationSec},
      );
      AppLogger.info('Analytics: Đã ghi nhận logout');
    } catch (e) {
      AppLogger.warning('Analytics logLogout error: $e');
    }
  }
}
