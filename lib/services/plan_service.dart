import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/study_plan_model.dart';
import '../utils/app_logger.dart';
import 'database_seeder.dart';

class PlanService {
  final FirebaseFirestore? _firestore;

  /// Bộ nhớ lưu trữ cục bộ (Local Persistence) cho các môn đã chọn của từng sinh viên
  /// Giữ nguyên dữ liệu kể cả khi người dùng chuyển qua lại giữa các màn hình/tab khác
  final Map<String, StudyPlanModel> _localDraftPlans = {};

  PlanService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  CollectionReference<Map<String, dynamic>>? get _plansRef =>
      _firestore?.collection('study_plans');

  /// Lấy bản kế hoạch đang lưu ở local của sinh viên (hoặc khởi tạo rỗng 0 môn nếu chưa chọn môn nào)
  StudyPlanModel getLocalDraftPlan({
    required String userId,
    String semester = 'Fall 2024',
    double? maxSafeHours,
    double? maxSafeThresholdHours,
  }) {
    final safeHours = maxSafeThresholdHours ?? maxSafeHours ?? 25.0;
    final existing = _localDraftPlans[userId];
    if (existing != null) {
      return existing.copyWith(maxSafeThresholdHours: safeHours);
    }
    final emptyPlan = DatabaseSeeder.getEmptyPlan(
      userId,
      semesterName: semester,
      maxSafeThresholdHours: safeHours,
    );
    _localDraftPlans[userId] = emptyPlan;
    return emptyPlan;
  }

  /// Lưu danh sách môn đã chọn vào bộ nhớ cục bộ (Local Persistence) mỗi khi thêm/xóa/đổi môn
  void saveLocalDraftPlan(StudyPlanModel plan) {
    _localDraftPlans[plan.userId] = plan;
    AppLogger.info(
      'Đã lưu tạm kế hoạch local cho ${plan.userId}: ${plan.selectedCourses.length} môn (${plan.totalSelfStudyHours}h)',
    );
  }

  /// Xóa trắng kế hoạch cục bộ về 0 môn (khi bắt đầu kỳ mới hoặc sau khi đã hoàn thành kỳ học)
  StudyPlanModel clearLocalDraftPlan(
    String userId, {
    String semester = 'Fall 2024',
    double maxSafeHours = 25.0,
  }) {
    final empty = DatabaseSeeder.getEmptyPlan(
      userId,
      semesterName: semester,
      maxSafeThresholdHours: maxSafeHours,
    );
    _localDraftPlans[userId] = empty;
    return empty;
  }

  /// Tải kế hoạch học tập của sinh viên (ưu tiên Local Draft, sau đó kiểm tra Cloud Firestore)
  Future<StudyPlanModel> getStudyPlan({
    required String userId,
    String semester = 'Fall 2024',
    double maxSafeHours = 25.0,
  }) async {
    final local = _localDraftPlans[userId];
    if (local != null && local.selectedCourses.isNotEmpty) {
      return local;
    }

    final docId = '${userId}_${semester.replaceAll(' ', '')}';
    final ref = _plansRef;
    if (ref == null) {
      return getLocalDraftPlan(
        userId: userId,
        semester: semester,
        maxSafeHours: maxSafeHours,
      );
    }

    try {
      final doc = await ref.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Nếu bản kế hoạch đã được đánh dấu hoàn thành kỳ học thì tạo kỳ mới rỗng
        if (data['isCompleted'] == true) {
          return getLocalDraftPlan(
            userId: userId,
            semester: semester,
            maxSafeHours: maxSafeHours,
          );
        }
        final cloudPlan = StudyPlanModel.fromMap(data, doc.id);
        _localDraftPlans[userId] = cloudPlan;
        return cloudPlan;
      }
    } catch (e) {
      AppLogger.warning('Lỗi khi đọc StudyPlan từ Firestore, dùng dữ liệu local: $e');
    }

    return getLocalDraftPlan(
      userId: userId,
      semester: semester,
      maxSafeHours: maxSafeHours,
    );
  }

  /// Lưu chính thức kế hoạch học tập lên Cloud Firestore (chỉ gọi khi đã hết xung đột)
  Future<void> saveStudyPlan(StudyPlanModel plan) async {
    _localDraftPlans[plan.userId] = plan;

    final ref = _plansRef;
    if (ref == null) {
      AppLogger.info('Chế độ Offline: Đã lưu StudyPlan cục bộ: ${plan.id}');
      return;
    }
    try {
      await ref.doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
      AppLogger.info('Đã lưu kế hoạch ${plan.id} lên Cloud Firestore thành công!');
    } catch (e, st) {
      AppLogger.error('Lỗi khi lưu StudyPlan lên Firestore', e, st);
    }
  }
}
