import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_plan_model.dart';
import '../utils/app_logger.dart';
import 'database_seeder.dart';

class PlanService {
  final FirebaseFirestore _firestore;

  PlanService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('study_plans');

  /// Tải kế hoạch học tập của sinh viên từ Firestore
  Future<StudyPlanModel> getStudyPlan({
    required String userId,
    String semester = 'Fall 2024',
  }) async {
    final docId = '${userId}_$semester';
    try {
      final doc = await _plansRef.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return StudyPlanModel.fromMap(doc.data()!, doc.id);
      }

      // Khởi tạo kế hoạch ban đầu mang trạng thái xung đột để sinh viên thao tác
      final initialPlan = DatabaseSeeder.getInitialConflictPlan(userId);
      await _plansRef.doc(docId).set(initialPlan.toMap());
      return initialPlan;
    } catch (e) {
      AppLogger.warning('Lỗi khi đọc StudyPlan từ Firestore, trả về plan mẫu: $e');
      return DatabaseSeeder.getInitialConflictPlan(userId);
    }
  }

  /// Lưu kế hoạch học tập lên Firestore
  Future<void> saveStudyPlan(StudyPlanModel plan) async {
    try {
      await _plansRef.doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
      AppLogger.info('Đã lưu kế hoạch ${plan.id} lên Firestore thành công');
    } catch (e, st) {
      AppLogger.error('Lỗi khi lưu StudyPlan lên Firestore', e, st);
    }
  }
}
