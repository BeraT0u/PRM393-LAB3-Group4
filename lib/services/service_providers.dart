import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'course_service.dart';
import 'student_service.dart';
import 'plan_service.dart';
import 'storage_service.dart';
import 'analytics_service.dart';
import 'pdf_report_service.dart';
import 'ai_advisor_service.dart';
import 'announcement_service.dart';
import '../models/announcement_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService();
});

final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService();
});

final planServiceProvider = Provider<PlanService>((ref) {
  return PlanService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final pdfReportServiceProvider = Provider<PdfReportService>((ref) {
  return PdfReportService();
});

final aiAdvisorServiceProvider = Provider<AiAdvisorService>((ref) {
  return AiAdvisorService();
});

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService();
});

final announcementsStreamProvider =
    StreamProvider<List<AnnouncementModel>>((ref) {
  final service = ref.watch(announcementServiceProvider);
  return service.streamAnnouncements();
});
