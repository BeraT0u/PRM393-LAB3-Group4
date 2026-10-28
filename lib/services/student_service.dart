import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_profile_model.dart';
import '../utils/app_logger.dart';
import 'database_seeder.dart';

class StudentService {
  final FirebaseFirestore _firestore;

  StudentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection('students');

  /// Lấy hồ sơ sinh viên từ Firestore theo UID
  Future<StudentProfileModel> getStudentProfile(String uid) async {
    try {
      final doc = await _studentsRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StudentProfileModel.fromMap(doc.data()!, doc.id);
      }

      // Nếu chưa có trên cloud, lưu và trả về hồ sơ mặc định
      final defaultProfile = DatabaseSeeder.defaultStudent.copyWith(uid: uid);
      await _studentsRef.doc(uid).set(defaultProfile.toMap());
      return defaultProfile;
    } catch (e) {
      AppLogger.warning('Lỗi khi lấy thông tin sinh viên từ Firestore: $e');
      return DatabaseSeeder.defaultStudent.copyWith(uid: uid);
    }
  }

  /// Cập nhật toàn bộ thông tin hồ sơ sinh viên
  Future<void> updateProfile(StudentProfileModel profile) async {
    try {
      await _studentsRef.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
      AppLogger.info('Đã cập nhật hồ sơ sinh viên ${profile.studentId} lên Firestore');
    } catch (e, st) {
      AppLogger.error('Lỗi khi cập nhật hồ sơ sinh viên', e, st);
    }
  }

  /// Cập nhật các công tắc thiết lập thông báo
  Future<void> updateSettings({
    required String uid,
    bool? notifyLabDeadlines,
    bool? autoWarnWorkload,
    bool? syncGoogleCalendar,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (notifyLabDeadlines != null) updates['notifyLabDeadlines'] = notifyLabDeadlines;
      if (autoWarnWorkload != null) updates['autoWarnWorkload'] = autoWarnWorkload;
      if (syncGoogleCalendar != null) updates['syncGoogleCalendar'] = syncGoogleCalendar;

      await _studentsRef.doc(uid).update(updates);
      AppLogger.info('Đã lưu cài đặt thông báo cho $uid');
    } catch (e) {
      AppLogger.warning('Lỗi khi lưu cài đặt: $e');
    }
  }
}
