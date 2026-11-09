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

  /// Xóa bộ nhớ đệm kế hoạch cục bộ (khi đăng xuất hoặc chuyển đổi tài khoản)
  void clearLocalCache([String? userId]) {
    if (userId != null) {
      _localDraftPlans.remove(userId);
    } else {
      _localDraftPlans.clear();
    }
  }

  PlanService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  CollectionReference<Map<String, dynamic>>? get _plansRef =>
      _firestore?.collection('study_plans');

  /// Lấy bản kế hoạch đang lưu ở local của sinh viên (hoặc khởi tạo rỗng 0 môn nếu chưa chọn môn nào)
  StudyPlanModel getLocalDraftPlan({
    required String userId,
    String? semester,
    double? maxSafeHours,
    double? maxSafeThresholdHours,
  }) {
    final safeHours = maxSafeThresholdHours ?? maxSafeHours ?? 25.0;
    final existing = _localDraftPlans[userId];
    if (existing != null) {
      final resolvedSemester = semester ?? existing.semesterName;
      final updated = existing.copyWith(
        id: '${userId}_${resolvedSemester.replaceAll(' ', '_')}',
        semesterName: resolvedSemester,
        maxSafeThresholdHours: safeHours,
      );
      _localDraftPlans[userId] = updated;
      return updated;
    }
    final resolvedSemester = semester ?? 'Học kỳ 1';
    final emptyPlan = DatabaseSeeder.getEmptyPlan(
      userId,
      semesterName: resolvedSemester,
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
    String semester = 'Học kỳ 1',
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

  /// Lắng nghe realtime các bản kế hoạch của sinh viên trên Cloud Firestore
  /// Giúp Mobile tự động cập nhật ngay khi Cố vấn duyệt kế hoạch hoặc duyệt nghiệm thu điểm trên Web
  Stream<List<StudyPlanModel>> watchUserPlans(String userId) {
    final ref = _plansRef;
    if (ref == null || userId.isEmpty) {
      return const Stream.empty();
    }
    return ref.where('userId', isEqualTo: userId).snapshots().map((snap) {
      return snap.docs
          .map((d) => StudyPlanModel.fromMap(d.data(), d.id))
          .toList();
    });
  }

  /// Tải kế hoạch học tập của sinh viên (luôn đồng bộ trạng thái duyệt mới nhất từ Cloud Firestore)
  Future<StudyPlanModel> getStudyPlan({
    required String userId,
    String semester = 'Học kỳ 1',
    double maxSafeHours = 25.0,
  }) async {
    final local = _localDraftPlans[userId];
    final ref = _plansRef;

    if (ref == null) {
      if (local != null && local.selectedCourses.isNotEmpty) {
        final updated = local.copyWith(
          id: '${userId}_${semester.replaceAll(' ', '_')}',
          semesterName: semester,
          maxSafeThresholdHours: maxSafeHours,
        );
        _localDraftPlans[userId] = updated;
        return updated;
      }
      return getLocalDraftPlan(
        userId: userId,
        semester: semester,
        maxSafeHours: maxSafeHours,
      );
    }

    // Nếu người dùng đang chọn môn nháp ở local (chưa bấm gửi duyệt), giữ bản nháp đang chỉnh sửa
    if (local != null &&
        local.selectedCourses.isNotEmpty &&
        !local.isSaved &&
        local.status == 'draft') {
      final updated = local.copyWith(
        id: '${userId}_${semester.replaceAll(' ', '_')}',
        semesterName: semester,
        maxSafeThresholdHours: maxSafeHours,
      );
      _localDraftPlans[userId] = updated;
      return updated;
    }

    final docIdUnderscore = '${userId}_${semester.replaceAll(' ', '_')}';
    final docIdCompact = '${userId}_${semester.replaceAll(' ', '')}';

    try {
      for (final candidateId in [docIdUnderscore, docIdCompact]) {
        final doc = await ref.doc(candidateId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final isDone =
              data['isCompleted'] == true || data['status'] == 'completed';
          if (!isDone) {
            final cloudPlan = StudyPlanModel.fromMap(data, doc.id).copyWith(
              id: doc.id,
              isSaved: true,
            );
            _localDraftPlans[userId] = cloudPlan;
            return cloudPlan;
          } else if (local != null && local.id == doc.id) {
            // Kế hoạch vừa được Cố vấn duyệt nghiệm thu hoàn tất -> xóa cache cũ
            _localDraftPlans.remove(userId);
          }
        }
      }

      // Tìm bản kế hoạch chưa hoàn thành của userId trên Cloud Firestore
      final querySnap =
          await ref.where('userId', isEqualTo: userId).get();
      for (final d in querySnap.docs) {
        final data = d.data();
        final isDone =
            data['isCompleted'] == true || data['status'] == 'completed';
        if (!isDone) {
          final cloudPlan = StudyPlanModel.fromMap(data, d.id).copyWith(
            id: d.id,
            isSaved: true,
          );
          if (cloudPlan.selectedCourses.isNotEmpty) {
            _localDraftPlans[userId] = cloudPlan;
            return cloudPlan;
          }
        }
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

  /// Lưu và gửi duyệt kế hoạch học tập lên Cloud Firestore (status = 'pending')
  Future<void> saveStudyPlan(StudyPlanModel plan) async {
    final normalizedStatus =
        (plan.status == 'draft' || plan.status == 'rejected')
            ? 'pending'
            : plan.status;
    final planToSave = plan.copyWith(
      isSaved: true,
      status: normalizedStatus,
    );
    _localDraftPlans[planToSave.userId] = planToSave;

    final ref = _plansRef;
    if (ref == null) {
      AppLogger.info('Chế độ Offline: Đã lưu StudyPlan cục bộ: ${planToSave.id}');
      return;
    }
    try {
      await ref.doc(planToSave.id).set(planToSave.toMap(), SetOptions(merge: true));
      AppLogger.info(
        'Đã gửi kế hoạch ${planToSave.id} (status=${planToSave.status}) lên Cloud Firestore thành công!',
      );
    } catch (e, st) {
      AppLogger.error('Lỗi khi lưu StudyPlan lên Firestore', e, st);
    }
  }
}
