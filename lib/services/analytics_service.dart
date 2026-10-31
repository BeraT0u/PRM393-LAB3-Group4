import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/app_logger.dart';

class AnalyticsService {
  final FirebaseAnalytics? _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? (Firebase.apps.isNotEmpty ? FirebaseAnalytics.instance : null);

  Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      AppLogger.info('Analytics: Đã gắn userId = $userId');
    } catch (e) {
      AppLogger.warning('Analytics setUserId error: $e');
    }
  }

  Future<void> logLogin({String method = 'google'}) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
      AppLogger.info('Analytics: Đã ghi nhận sự kiện login');
    } catch (e) {
      AppLogger.warning('Analytics logLogin error: $e');
    }
  }

  Future<void> logSearch({required String searchTerm, required int resultCount}) async {
    try {
      await _analytics?.logSearch(
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
      await _analytics?.logEvent(
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
    required double estimatedHours,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'select_grade_target',
        parameters: {
          'course_id': courseId,
          'target_grade': targetGrade,
          'estimated_hours': estimatedHours,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics logSelectGradeTarget error: $e');
    }
  }

  Future<void> logAddCourseToPlan({
    required String courseId,
    required String targetGrade,
    required double weeklyHours,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'add_course_to_plan',
        parameters: {
          'course_id': courseId,
          'target_grade': targetGrade,
          'weekly_hours': weeklyHours,
        },
      );
      AppLogger.info('Analytics: Đã ghi nhận add_course_to_plan ($courseId, $targetGrade)');
    } catch (e) {
      AppLogger.warning('Analytics logAddCourseToPlan error: $e');
    }
  }

  Future<void> logDetectPlanConflict({
    required int totalHours,
    required String violatedCourseId,
    required String conflictType,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'detect_plan_conflict',
        parameters: {
          'total_hours': totalHours,
          'violated_course_id': violatedCourseId,
          'conflict_type': conflictType,
        },
      );
      AppLogger.info('Analytics: Đã ghi nhận detect_plan_conflict ($violatedCourseId, $totalHours h)');
    } catch (e) {
      AppLogger.warning('Analytics logDetectPlanConflict error: $e');
    }
  }

  Future<void> logResolvePlanConflict({
    required String oldCourseId,
    required String newCourseId,
    required int newTotalHours,
  }) async {
    return logResolveConflict(
      oldCourseId: oldCourseId,
      newCourseId: newCourseId,
      newTotalHours: newTotalHours,
    );
  }

  Future<void> logResolveConflict({
    required String oldCourseId,
    required String newCourseId,
    required int newTotalHours,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'resolve_conflict',
        parameters: {
          'old_course_id': oldCourseId,
          'new_course_id': newCourseId,
          'new_total_hours': newTotalHours,
        },
      );
      AppLogger.info('Analytics: Đã ghi nhận resolve_conflict ($oldCourseId -> $newCourseId, $newTotalHours h)');
    } catch (e) {
      AppLogger.warning('Analytics logResolveConflict error: $e');
    }
  }

  Future<void> logSaveStudyPlan({
    required String planId,
    required int courseCount,
    required int totalCredits,
    required double totalHours,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'save_study_plan',
        parameters: {
          'plan_id': planId,
          'course_count': courseCount,
          'total_credits': totalCredits,
          'total_hours': totalHours,
        },
      );
      AppLogger.info('Analytics: Đã ghi nhận save_study_plan ($planId, $courseCount môn, $totalCredits TC)');
    } catch (e) {
      AppLogger.warning('Analytics logSaveStudyPlan error: $e');
    }
  }
}
