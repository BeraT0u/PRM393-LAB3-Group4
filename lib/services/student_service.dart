import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/student_profile_model.dart';
import '../utils/app_logger.dart';
import 'database_seeder.dart';

class StudentService {
  final FirebaseFirestore _firestore;

  StudentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection('students');

  /// Lấy hồ sơ sinh viên từ Firestore theo UID, hỗ trợ đa Persona hoặc khởi tạo hồ sơ rỗng
  Future<StudentProfileModel> getStudentProfile(
    String uid, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final doc = await _studentsRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StudentProfileModel.fromMap(doc.data()!, doc.id);
      }

      // Xác định hồ sơ phù hợp: Persona Long/Linh/Tuấn hoặc Hồ sơ rỗng cho tài khoản mới
      final profile = DatabaseSeeder.resolveProfileForUser(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      await _studentsRef.doc(uid).set(profile.toMap());
      AppLogger.info('Đã tạo hồ sơ cho người dùng $uid (isNew=${profile.isNewStudent})');
      return profile;
    } catch (e) {
      AppLogger.warning('Lỗi khi lấy thông tin sinh viên từ Firestore: $e');
      return DatabaseSeeder.resolveProfileForUser(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
    }
  }

  /// Cập nhật thông tin cá nhân trên màn hình Profile Setting (SCR-08)
  Future<void> updatePersonalInfo({
    required String uid,
    required String fullName,
    required String studentId,
    String? avatarUrl,
    double? targetGpa,
  }) async {
    try {
      final updates = <String, dynamic>{
        'fullName': fullName,
        'studentId': studentId,
        'isNewStudent': false, // Đã hoàn tất setup thông tin
      };
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (targetGpa != null) updates['targetGpa'] = targetGpa;

      await _studentsRef.doc(uid).set(updates, SetOptions(merge: true));
      AppLogger.info('Đã cập nhật thông tin cá nhân cho $studentId ($fullName)');
    } catch (e, st) {
      AppLogger.error('Lỗi khi cập nhật thông tin cá nhân', e, st);
      rethrow;
    }
  }

  /// Khai báo thêm môn đã học theo kỳ (SCR-03)
  /// Kiểm tra 2 điều kiện:
  /// 1. Tiến trình kỳ: Kỳ N chỉ được thêm nếu Kỳ 1..N-1 đã có môn hoàn thành ("kì 2 phải có kì 1")
  /// 2. Tiên quyết: Môn thêm vào phải có môn tiên quyết nằm trong passedCourseCodes
  Future<void> addCompletedCourse({
    required String uid,
    required int semesterIndex, // 1..9
    required CourseModel course,
    required double grade,
  }) async {
    final profile = await getStudentProfile(uid);

    // 1. Kiểm tra ràng buộc tiến trình kỳ học ("kì 2 phải có kì 1")
    if (semesterIndex > 1) {
      // Đếm số môn đã có ở các kỳ trước
      final prevSemestersSnapshot = await _studentsRef
          .doc(uid)
          .collection('completed_courses')
          .where('semesterIndex', isLessThan: semesterIndex)
          .limit(1)
          .get();

      final hasPreviousCourses = prevSemestersSnapshot.docs.isNotEmpty ||
          (profile.passedCourseCodes.isNotEmpty && semesterIndex <= 4);

      if (!hasPreviousCourses) {
        throw ArgumentError(
          'Không thể thêm môn vào Kỳ $semesterIndex khi Kỳ 1 chưa có môn học nào hoàn thành. Vui lòng thêm các môn của kỳ trước đó trước!',
        );
      }
    }

    // 2. Kiểm tra điều kiện môn tiên quyết
    if (course.prerequisiteCode != null &&
        course.prerequisiteCode!.trim().isNotEmpty) {
      final reqCode = course.prerequisiteCode!.trim();
      final hasPrereq = profile.passedCourseCodes.contains(reqCode);
      if (!hasPrereq) {
        throw ArgumentError(
          'Không thể thêm môn ${course.code} vì chưa hoàn thành môn tiên quyết $reqCode!',
        );
      }
    }

    // 3. Ghi vào subcollection completed_courses
    final courseDoc = _studentsRef
        .doc(uid)
        .collection('completed_courses')
        .doc(course.code);

    final courseData = {
      'courseId': course.id,
      'code': course.code,
      'name': course.name,
      'credits': course.credits,
      'grade': grade,
      'gradeLetter': grade >= 8.5 ? 'A' : (grade >= 7.0 ? 'B' : 'C'),
      'semesterIndex': semesterIndex,
      'completedAt': FieldValue.serverTimestamp(),
    };

    await courseDoc.set(courseData);

    // 4. Cập nhật hồ sơ sinh viên: tăng tín chỉ tích lũy & thêm mã môn đã Pass
    final updatedPassedCodes = Set<String>.from(profile.passedCourseCodes)..add(course.code);
    final updatedCredits = profile.accumulatedCredits + course.credits;

    await _studentsRef.doc(uid).set({
      'passedCourseCodes': updatedPassedCodes.toList(),
      'accumulatedCredits': updatedCredits,
    }, SetOptions(merge: true));

    AppLogger.info('Đã thêm môn ${course.code} vào Kỳ $semesterIndex cho $uid (+${course.credits} TC)');
  }

  /// Nghiệm thu kỳ học: Đánh dấu hoàn thành kỳ học từ bản kế hoạch (SCR-07)
  /// Tự động chuyển tất cả các môn trong study_plan sang completed_courses
  Future<void> markSemesterPlanCompleted({
    required String uid,
    required String planId,
  }) async {
    try {
      final planDoc = await _firestore.collection('study_plans').doc(planId).get();
      if (!planDoc.exists || planDoc.data() == null) {
        throw StateError('Không tìm thấy bản kế hoạch $planId để nghiệm thu.');
      }

      final planData = planDoc.data()!;
      final coursesList = (planData['selectedCourses'] as List<dynamic>?) ?? [];
      final profile = await getStudentProfile(uid);

      final batch = _firestore.batch();
      final newPassedCodes = Set<String>.from(profile.passedCourseCodes);
      int addedCredits = 0;

      for (final rawCourse in coursesList) {
        final courseMap = Map<String, dynamic>.from(rawCourse as Map);
        final courseId = (courseMap['id'] ?? courseMap['code'] ?? '') as String;
        final course = CourseModel.fromMap(courseMap, courseId);

        final completedRef = _studentsRef
            .doc(uid)
            .collection('completed_courses')
            .doc(course.code);

        batch.set(completedRef, {
          'courseId': course.id,
          'code': course.code,
          'name': course.name,
          'credits': course.credits,
          'grade': course.selectedGradeTarget == 'A' ? 9.0 : 8.0,
          'gradeLetter': course.selectedGradeTarget,
          'semesterName': planData['semesterName'] ?? 'Fall 2024',
          'completedAt': FieldValue.serverTimestamp(),
        });

        newPassedCodes.add(course.code);
        addedCredits += course.credits;
      }

      // Cập nhật lại tín chỉ sinh viên
      batch.set(_studentsRef.doc(uid), {
        'accumulatedCredits': profile.accumulatedCredits + addedCredits,
        'passedCourseCodes': newPassedCodes.toList(),
      }, SetOptions(merge: true));

      // Cập nhật trạng thái bản kế hoạch
      batch.update(planDoc.reference, {
        'isCompleted': true,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      AppLogger.info('Đã nghiệm thu kỳ học $planId cho $uid: Đã chuyển ${coursesList.length} môn sang Đã Học');
    } catch (e, st) {
      AppLogger.error('Lỗi khi nghiệm thu kỳ học $planId', e, st);
      rethrow;
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
