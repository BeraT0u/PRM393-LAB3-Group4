import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/completed_course_model.dart';
import '../models/course_model.dart';
import '../models/student_profile_model.dart';
import '../models/study_plan_model.dart';
import '../utils/app_logger.dart';
import '../utils/gpa_calculator.dart';
import 'database_seeder.dart';

class StudentService {
  final FirebaseFirestore? _firestore;

  /// Bộ nhớ đệm cục bộ giúp dữ liệu sinh viên và môn đã học luôn đồng bộ tức thì giữa các màn hình
  final Map<String, StudentProfileModel> _localProfiles = {};
  final Map<String, List<CompletedCourseModel>> _localCompletedCourses = {};

  StudentService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  CollectionReference<Map<String, dynamic>>? get _studentsRef =>
      _firestore?.collection('students');

  /// Xác định số thứ tự học kỳ hiện tại của tài khoản dựa trên dữ liệu môn đã học (SCR-03)
  /// VD: Chưa học kỳ nào -> 1 (Học kỳ 1); Đã học xong Kỳ 1 -> 2 (Học kỳ 2)
  static int computeCurrentSemesterIndex(List<CompletedCourseModel> completed) {
    if (completed.isEmpty) return 1;
    final maxCompletedSemester = completed
        .map((c) => c.semesterIndex ?? 0)
        .fold<int>(0, (prev, elem) => elem > prev ? elem : prev);
    if (maxCompletedSemester <= 0) return 1;
    return (maxCompletedSemester + 1).clamp(1, 9);
  }

  /// Trả về tên hiển thị chuẩn cho học kỳ hiện tại (VD: "Học kỳ 1", "Học kỳ 2")
  static String computeCurrentSemesterName(List<CompletedCourseModel> completed) {
    return 'Học kỳ ${computeCurrentSemesterIndex(completed)}';
  }

  /// Lấy thông tin sinh viên từ Firestore hoặc bộ nhớ đệm
  Future<StudentProfileModel> getStudentProfile(
    String uid, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    final ref = _studentsRef;
    if (ref == null) {
      final cached = _localProfiles[uid] ??
          DatabaseSeeder.resolveProfileForUser(
            uid: uid,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
          );
      final localDone = _localCompletedCourses[uid];
      if (localDone != null && localDone.isNotEmpty) {
        final localCredits = localDone
            .where((c) => c.isActuallyPassed)
            .fold<int>(0, (int total, c) => total + c.credits);
        final localCodes = localDone
            .where((c) => c.isActuallyPassed)
            .map((c) => c.code)
            .toList();
        final localGpa = GpaCalculator.calculateGpa(localDone);
        final synced = cached.copyWith(
          accumulatedCredits: localCredits,
          passedCourseCodes: localCodes,
          currentGpa: localGpa,
        );
        _localProfiles[uid] = synced;
        return synced;
      }
      _localProfiles[uid] = cached;
      return cached;
    }

    try {
      final doc = await ref.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        var loaded = StudentProfileModel.fromMap(doc.data()!, doc.id);

        // Với tài khoản đăng nhập thực tế (không phải seed mẫu), đồng bộ từ completed_courses
        if (uid != DatabaseSeeder.defaultStudent.uid) {
          final completedSnap =
              await ref.doc(uid).collection('completed_courses').get();
          final realCompleted = completedSnap.docs
              .map((d) => CompletedCourseModel.fromMap(d.data(), d.id))
              .toList();
          _localCompletedCourses[uid] = realCompleted;

          final realCredits = realCompleted
              .where((c) => c.isActuallyPassed)
              .fold<int>(0, (int total, c) => total + c.credits);
          final realCodes = realCompleted
              .where((c) => c.isActuallyPassed)
              .map((c) => c.code)
              .toList();
          final realGpa = GpaCalculator.calculateGpa(realCompleted);

          final bool hadFakeSeedId = loaded.studentId == 'SE180504' &&
              (loaded.email == null ||
                  !loaded.email!.toLowerCase().contains('se180504'));

          loaded = loaded.copyWith(
            email: email ?? loaded.email,
            avatarUrl: (photoUrl != null && photoUrl.startsWith('http'))
                ? photoUrl
                : loaded.avatarUrl,
            studentId: hadFakeSeedId ? '' : loaded.studentId,
            major: hadFakeSeedId ? '' : loaded.major,
            cohort: hadFakeSeedId ? '' : loaded.cohort,
            currentGpa: realCompleted.isNotEmpty
                ? realGpa
                : ((hadFakeSeedId && realCompleted.isEmpty)
                    ? 0.0
                    : loaded.currentGpa),
            targetGpa: ((hadFakeSeedId || loaded.isNewStudent) &&
                    loaded.targetGpa == 3.50 &&
                    realCompleted.isEmpty)
                ? 0.0
                : (hadFakeSeedId ? 0.0 : loaded.targetGpa),
            accumulatedCredits: realCredits,
            passedCourseCodes: realCodes,
            isNewStudent: hadFakeSeedId ? true : loaded.isNewStudent,
          );
          await ref.doc(uid).set(loaded.toMap(), SetOptions(merge: true));
        }

        _localProfiles[uid] = loaded;
        return loaded;
      }

      // Khởi tạo hồ sơ rỗng cho tài khoản mới
      final profile = DatabaseSeeder.resolveProfileForUser(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      _localProfiles[uid] = profile;
      await ref.doc(uid).set(profile.toMap());
      AppLogger.info('Đã tạo hồ sơ cho người dùng $uid (isNew=${profile.isNewStudent})');
      return profile;
    } catch (e) {
      AppLogger.warning('Lỗi khi lấy thông tin sinh viên từ Firestore: $e');
      final fallback = _localProfiles[uid] ??
          DatabaseSeeder.resolveProfileForUser(
            uid: uid,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
          );
      final localDone = _localCompletedCourses[uid];
      if (localDone != null && localDone.isNotEmpty) {
        final localCredits = localDone
            .where((c) => c.isActuallyPassed)
            .fold<int>(0, (int total, c) => total + c.credits);
        final localCodes = localDone
            .where((c) => c.isActuallyPassed)
            .map((c) => c.code)
            .toList();
        final localGpa = GpaCalculator.calculateGpa(localDone);
        final syncedFallback = fallback.copyWith(
          accumulatedCredits: localCredits,
          passedCourseCodes: localCodes,
          currentGpa: localGpa,
        );
        _localProfiles[uid] = syncedFallback;
        return syncedFallback;
      }
      _localProfiles[uid] = fallback;
      return fallback;
    }
  }

  /// Cập nhật thông tin cá nhân trên màn hình Profile Setting (SCR-08)
  Future<StudentProfileModel> updatePersonalInfo({
    required String uid,
    required String fullName,
    required String studentId,
    String? major,
    String? cohort,
    String? email,
    String? avatarUrl,
    double? currentGpa,
    double? targetGpa,
    int? totalGraduationCredits,
  }) async {
    final current = await getStudentProfile(uid, email: email);
    final hasHttpAvatar =
        current.avatarUrl != null && current.avatarUrl!.startsWith('http');
    final resolvedAvatar = (avatarUrl != null && avatarUrl.startsWith('http'))
        ? avatarUrl
        : (hasHttpAvatar
            ? current.avatarUrl
            : (avatarUrl ?? current.avatarUrl));

    // GPA hiện tại luôn được tính tự động từ danh sách môn đã học (không cho phép nhập đè)
    final existingCompleted = await getCompletedCourses(uid);
    final calculatedCurrentGpa = existingCompleted.isNotEmpty
        ? GpaCalculator.calculateGpa(existingCompleted)
        : current.currentGpa;

    final updated = current.copyWith(
      fullName: fullName.trim(),
      studentId: studentId.trim().toUpperCase(),
      major: major != null ? major.trim() : current.major,
      cohort: cohort != null ? cohort.trim() : current.cohort,
      email: email ?? current.email,
      avatarUrl: resolvedAvatar,
      currentGpa: calculatedCurrentGpa,
      targetGpa: targetGpa ?? current.targetGpa,
      totalGraduationCredits:
          totalGraduationCredits ?? current.totalGraduationCredits,
      isNewStudent: false, // Đã hoàn tất thiết lập thông tin cá nhân
    );

    _localProfiles[uid] = updated;

    final ref = _studentsRef;
    if (ref != null) {
      try {
        await ref.doc(uid).set(updated.toMap(), SetOptions(merge: true));
        AppLogger.info('Đã cập nhật thông tin cá nhân cho ${updated.studentId} (${updated.fullName})');
      } catch (e, st) {
        AppLogger.error('Lỗi khi cập nhật thông tin cá nhân lên Firestore', e, st);
      }
    }
    return updated;
  }

  /// Lấy danh sách môn đã học của sinh viên (SCR-03)
  Future<List<CompletedCourseModel>> getCompletedCourses(String uid) async {
    final ref = _studentsRef;
    if (ref == null) {
      return List<CompletedCourseModel>.from(_localCompletedCourses[uid] ?? const []);
    }
    try {
      final snapshot = await ref.doc(uid).collection('completed_courses').get();
      final remoteList = snapshot.docs
          .map((d) => CompletedCourseModel.fromMap(d.data(), d.id))
          .toList();

      // Hợp nhất với dữ liệu local nếu có môn vừa thêm
      final localList = _localCompletedCourses[uid] ?? const [];
      final mergedMap = <String, CompletedCourseModel>{
        for (final c in remoteList) c.code: c,
        for (final c in localList) c.code: c,
      };
      final merged = mergedMap.values.toList();
      _localCompletedCourses[uid] = merged;
      return merged;
    } catch (e) {
      AppLogger.warning('Lỗi khi tải môn đã học của $uid: $e');
      return List<CompletedCourseModel>.from(_localCompletedCourses[uid] ?? const []);
    }
  }

  /// Khai báo thêm môn đã học theo kỳ (SCR-03)
  Future<void> addCompletedCourse({
    required String uid,
    required int semesterIndex, // 1..9
    required CourseModel course,
    required double grade,
  }) async {
    final profile = await getStudentProfile(uid);
    final existingCompleted = await getCompletedCourses(uid);

    // 1. Kiểm tra ràng buộc tiến trình kỳ học ("kì 2 phải có kì 1")
    for (var k = 1; k < semesterIndex; k++) {
      final hasSemesterK = existingCompleted.any((c) => c.semesterIndex == k);
      if (!hasSemesterK) {
        throw ArgumentError(
          'Không thể thêm môn vào Kỳ $semesterIndex khi Kỳ $k chưa có môn học nào hoàn thành. Vui lòng khai báo Kỳ $k trước!',
        );
      }
    }

    // 2. Kiểm tra điều kiện môn tiên quyết
    if (course.prerequisiteCode != null &&
        course.prerequisiteCode!.trim().isNotEmpty) {
      final reqCode = course.prerequisiteCode!.trim();
      final hasPrereqInPrevSemesters = profile.passedCourseCodes.contains(reqCode) ||
          existingCompleted.any(
            (c) =>
                c.code == reqCode &&
                c.isActuallyPassed &&
                (c.semesterIndex == null || c.semesterIndex! < semesterIndex),
          );
      if (!hasPrereqInPrevSemesters) {
        throw ArgumentError(
          'Không thể thêm môn ${course.code} vào Kỳ $semesterIndex vì chưa hoàn thành môn tiên quyết $reqCode ở các kỳ trước!',
        );
      }
    }

    final isPassed = grade >= 4.0;
    final newCompletedCourse = CompletedCourseModel(
      code: course.code,
      name: course.name,
      credits: course.credits,
      semesterIndex: semesterIndex,
      grade: grade,
      gradeLetter: GpaCalculator.grade10ToLetter(grade),
      isPassed: isPassed,
    );

    // Cập nhật bộ nhớ đệm local ngay lập tức
    final updatedCompletedList = [
      ...existingCompleted.where((c) => c.code != course.code),
      newCompletedCourse,
    ];
    _localCompletedCourses[uid] = updatedCompletedList;

    final updatedPassedCodes = updatedCompletedList
        .where((c) => c.isActuallyPassed)
        .map((c) => c.code)
        .toSet()
        .toList();

    final updatedCredits = updatedCompletedList
        .where((c) => c.isActuallyPassed)
        .fold<int>(0, (int total, c) => total + c.credits);

    final updatedGpa = GpaCalculator.calculateGpa(updatedCompletedList);

    final updatedProfile = profile.copyWith(
      passedCourseCodes: updatedPassedCodes,
      accumulatedCredits: updatedCredits,
      currentGpa: updatedGpa,
      isNewStudent: false,
    );
    _localProfiles[uid] = updatedProfile;

    // 3. Ghi lên Cloud Firestore nếu có kết nối
    final ref = _studentsRef;
    if (ref != null) {
      try {
        final courseDoc = ref
            .doc(uid)
            .collection('completed_courses')
            .doc(course.code);

        final courseData = {
          'courseId': course.id,
          'code': course.code,
          'name': course.name,
          'credits': course.credits,
          'grade': grade,
          'gradeLetter': GpaCalculator.grade10ToLetter(grade),
          'isPassed': isPassed,
          'semesterIndex': semesterIndex,
          'completedAt': FieldValue.serverTimestamp(),
        };

        await courseDoc.set(courseData);
        await ref.doc(uid).set({
          'passedCourseCodes': updatedPassedCodes,
          'accumulatedCredits': updatedCredits,
          'currentGpa': updatedGpa,
          'isNewStudent': false,
        }, SetOptions(merge: true));
      } catch (e) {
        AppLogger.warning('Đã lưu môn học vào bộ nhớ máy (chờ đồng bộ Cloud): $e');
      }
    }

    AppLogger.info('Đã thêm môn ${course.code} vào Kỳ $semesterIndex cho $uid (+${course.credits} TC, GPA=$updatedGpa)');
  }

  /// Nghiệm thu kỳ học từ bản kế hoạch (SCR-07: Nút "✅ Đã Hoàn Thành Kỳ Học")
  /// Tự động lưu tất cả các môn đã chọn kèm điểm số và trạng thái Đạt/Rớt do người dùng chọn.
  Future<int> completeSemesterFromPlan({
    required String uid,
    required StudyPlanModel plan,
    List<CourseGradeItem>? courseGrades,
  }) async {
    if (plan.selectedCourses.isEmpty) return 0;

    final profile = await getStudentProfile(uid);
    final existingCompleted = await getCompletedCourses(uid);

    // Xác định kỳ học tiếp theo dựa trên các kỳ đã có dữ liệu (Kỳ 1, Kỳ 2, ...)
    final maxExistingSemester = existingCompleted
        .map((c) => c.semesterIndex ?? 0)
        .fold<int>(0, (prev, elem) => elem > prev ? elem : prev);
    final targetSemester = maxExistingSemester + 1;

    final updatedCompletedMap = <String, CompletedCourseModel>{
      for (final c in existingCompleted) c.code: c,
    };
    final newPassedCodes = Set<String>.from(profile.passedCourseCodes);
    int addedCredits = 0;

    final Map<String, CourseGradeItem> gradeMap = {
      if (courseGrades != null)
        for (final item in courseGrades) item.course.code: item,
    };

    for (final course in plan.selectedCourses) {
      final gradeItem = gradeMap[course.code];
      final bool isPassed = gradeItem?.isPassed ?? true;
      final double defaultGrade = course.selectedGradeTarget == 'A'
          ? 8.8
          : (course.selectedGradeTarget == 'B' ? 7.5 : 6.0);
      final double grade = gradeItem?.grade ?? defaultGrade;
      final String gradeLetter = GpaCalculator.grade10ToLetter(grade);

      final isActuallyPassed = isPassed && grade >= 4.0;
      final isAlreadyPassed = newPassedCodes.contains(course.code);

      updatedCompletedMap[course.code] = CompletedCourseModel(
        code: course.code,
        name: course.name,
        credits: course.credits,
        semesterIndex: targetSemester,
        semesterName: plan.semesterName,
        grade: grade,
        gradeLetter: gradeLetter,
        isPassed: isActuallyPassed,
      );

      if (isActuallyPassed) {
        newPassedCodes.add(course.code);
        if (!isAlreadyPassed) {
          addedCredits += course.credits;
        }
      }
    }

    final allCompletedList = updatedCompletedMap.values.toList();
    _localCompletedCourses[uid] = allCompletedList;

    final updatedGpa = GpaCalculator.calculateGpa(allCompletedList);

    final updatedProfile = profile.copyWith(
      accumulatedCredits: profile.accumulatedCredits + addedCredits,
      passedCourseCodes: newPassedCodes.toList(),
      currentGpa: updatedGpa,
      isNewStudent: false,
    );
    _localProfiles[uid] = updatedProfile;

    // Đồng bộ lên Cloud Firestore nếu khả dụng
    final firestore = _firestore;
    final ref = _studentsRef;
    if (firestore != null && ref != null) {
      try {
        final batch = firestore.batch();
        for (final course in plan.selectedCourses) {
          final completedItem = updatedCompletedMap[course.code]!;
          final completedRef = ref
              .doc(uid)
              .collection('completed_courses')
              .doc(course.code);

          batch.set(completedRef, {
            'courseId': course.id,
            'code': course.code,
            'name': course.name,
            'credits': course.credits,
            'grade': completedItem.grade,
            'gradeLetter': completedItem.gradeLetter,
            'isPassed': completedItem.isActuallyPassed,
            'semesterIndex': targetSemester,
            'semesterName': plan.semesterName,
            'completedAt': FieldValue.serverTimestamp(),
          });
        }

        batch.set(ref.doc(uid), {
          'accumulatedCredits': updatedProfile.accumulatedCredits,
          'passedCourseCodes': updatedProfile.passedCourseCodes,
          'currentGpa': updatedProfile.currentGpa,
          'isNewStudent': false,
        }, SetOptions(merge: true));

        final planRef = firestore.collection('study_plans').doc(plan.id);
        batch.set(planRef, {
          ...plan.toMap(),
          'isCompleted': true,
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
        AppLogger.info(
          'Đã nghiệm thu kỳ học ${plan.id} vào Kỳ $targetSemester cho $uid (+$addedCredits TC, GPA=$updatedGpa)',
        );
      } catch (e, st) {
        AppLogger.warning('Đã lưu hoàn thành kỳ học ở local, lỗi đồng bộ Firestore: $e');
        AppLogger.error('Chi tiết lỗi completeSemesterFromPlan', e, st);
      }
    }

    return targetSemester;
  }

  /// Giữ tương thích với hàm markSemesterPlanCompleted theo planId
  Future<void> markSemesterPlanCompleted({
    required String uid,
    required String planId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final planDoc = await firestore.collection('study_plans').doc(planId).get();
    if (!planDoc.exists || planDoc.data() == null) return;
    final plan = StudyPlanModel.fromMap(planDoc.data()!, planDoc.id);
    await completeSemesterFromPlan(uid: uid, plan: plan);
  }

  /// Cập nhật toàn bộ thông tin hồ sơ sinh viên
  Future<void> updateProfile(StudentProfileModel profile) async {
    _localProfiles[profile.uid] = profile;
    final ref = _studentsRef;
    if (ref == null) return;
    try {
      await ref.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
      AppLogger.info('Đã cập nhật hồ sơ sinh viên ${profile.studentId} lên Firestore');
    } catch (e, st) {
      AppLogger.error('Lỗi khi cập nhật hồ sơ sinh viên', e, st);
    }
  }

  /// Cập nhật các công tắc thiết lập thông báo
  Future<StudentProfileModel> updateSettings({
    required String uid,
    bool? notifyLabDeadlines,
    bool? autoWarnWorkload,
    bool? syncGoogleCalendar,
  }) async {
    final current = await getStudentProfile(uid);
    final updated = current.copyWith(
      notifyLabDeadlines: notifyLabDeadlines ?? current.notifyLabDeadlines,
      autoWarnWorkload: autoWarnWorkload ?? current.autoWarnWorkload,
      syncGoogleCalendar: syncGoogleCalendar ?? current.syncGoogleCalendar,
    );
    _localProfiles[uid] = updated;

    final ref = _studentsRef;
    if (ref != null) {
      try {
        final updates = <String, dynamic>{};
        if (notifyLabDeadlines != null) updates['notifyLabDeadlines'] = notifyLabDeadlines;
        if (autoWarnWorkload != null) updates['autoWarnWorkload'] = autoWarnWorkload;
        if (syncGoogleCalendar != null) updates['syncGoogleCalendar'] = syncGoogleCalendar;

        await ref.doc(uid).set(updates, SetOptions(merge: true));
        AppLogger.info('Đã lưu cài đặt thông báo cho $uid');
      } catch (e) {
        AppLogger.warning('Lỗi khi lưu cài đặt: $e');
      }
    }
    return updated;
  }
}
