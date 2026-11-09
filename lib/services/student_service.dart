import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Lấy nhanh hồ sơ sinh viên đã lưu trong bộ nhớ đệm (nếu có)
  StudentProfileModel? getCachedProfile(String uid) => _localProfiles[uid];

  /// Xóa bộ nhớ đệm cục bộ (khi đăng xuất hoặc chuyển đổi tài khoản)
  void clearLocalCache([String? uid]) {
    if (uid != null) {
      _localProfiles.remove(uid);
      _localCompletedCourses.remove(uid);
    } else {
      _localProfiles.clear();
      _localCompletedCourses.clear();
    }
  }

  StudentService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  CollectionReference<Map<String, dynamic>>? get _studentsRef =>
      _firestore?.collection('students');

  /// Hợp nhất thông tin hồ sơ từ Firestore với bộ nhớ đệm để không bao giờ làm mất thông tin cá nhân đã nhập
  StudentProfileModel _mergePreservingPersonalInfo(
    StudentProfileModel loaded,
    StudentProfileModel? cached, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    String resolvedFullName = loaded.fullName.trim();
    if ((resolvedFullName.isEmpty || resolvedFullName == 'Sinh viên mới') &&
        cached != null &&
        cached.fullName.trim().isNotEmpty &&
        cached.fullName != 'Sinh viên mới') {
      resolvedFullName = cached.fullName.trim();
    }
    if ((resolvedFullName.isEmpty || resolvedFullName == 'Sinh viên mới') &&
        displayName != null &&
        displayName.trim().isNotEmpty) {
      resolvedFullName = displayName.trim();
    }
    if (resolvedFullName.isEmpty) {
      resolvedFullName = loaded.fullName;
    }

    final resolvedStudentId = loaded.studentId.trim().isNotEmpty
        ? loaded.studentId.trim()
        : (cached?.studentId.trim() ?? '');
    final resolvedMajor = loaded.major.trim().isNotEmpty
        ? loaded.major.trim()
        : (cached?.major.trim() ?? '');
    final resolvedCohort = loaded.cohort.trim().isNotEmpty
        ? loaded.cohort.trim()
        : (cached?.cohort.trim() ?? '');
    final resolvedTargetGpa = loaded.targetGpa > 0
        ? loaded.targetGpa
        : (cached != null && cached.targetGpa > 0 ? cached.targetGpa : 0.0);

    final resolvedEmail = (loaded.email != null && loaded.email!.trim().isNotEmpty)
        ? loaded.email
        : ((email != null && email.trim().isNotEmpty) ? email : cached?.email);

    final resolvedAvatar = (photoUrl != null && photoUrl.startsWith('http'))
        ? photoUrl
        : ((loaded.avatarUrl != null && loaded.avatarUrl!.trim().isNotEmpty)
            ? loaded.avatarUrl
            : cached?.avatarUrl);

    return loaded.copyWith(
      fullName: resolvedFullName,
      studentId: resolvedStudentId,
      major: resolvedMajor,
      cohort: resolvedCohort,
      targetGpa: resolvedTargetGpa,
      email: resolvedEmail,
      avatarUrl: resolvedAvatar,
      autoWarnWorkload: cached?.autoWarnWorkload ?? loaded.autoWarnWorkload,
      notifyLabDeadlines:
          cached?.notifyLabDeadlines ?? loaded.notifyLabDeadlines,
      syncGoogleCalendar:
          cached?.syncGoogleCalendar ?? loaded.syncGoogleCalendar,
      isNewStudent: (resolvedStudentId.isNotEmpty ||
              resolvedMajor.isNotEmpty ||
              resolvedCohort.isNotEmpty ||
              resolvedTargetGpa > 0)
          ? false
          : loaded.isNewStudent,
    );
  }

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
    if (Firebase.apps.isNotEmpty) {
      try {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null && authUser.uid == uid) {
          email ??= authUser.email;
          displayName ??= authUser.displayName;
          photoUrl ??= authUser.photoURL;
        }
      } catch (_) {}
    }

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
        final uniquePassed = <String, CompletedCourseModel>{};
        for (final c in localDone) {
          if (c.isActuallyPassed) {
            uniquePassed[c.code] = c;
          }
        }
        final localCredits = uniquePassed.values
            .fold<int>(0, (int total, c) => total + c.credits);
        final localCodes = uniquePassed.keys.toList();
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
      var doc = await ref.doc(uid).get();

      // Nếu chưa có doc theo uid, kiểm tra xem email này đã từng có tài khoản trong hệ thống chưa
      if ((!doc.exists || doc.data() == null) &&
          email != null &&
          email.trim().isNotEmpty) {
        final normalizedEmail = email.trim().toLowerCase();
        final emailQuery = await ref
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
        if (emailQuery.docs.isNotEmpty) {
          doc = emailQuery.docs.first;
          AppLogger.info(
            'Đã tìm thấy tài khoản sinh viên qua email: $normalizedEmail (id: ${doc.id})',
          );
        }
      }

      if (doc.exists && doc.data() != null) {
        final localCached = _localProfiles[uid];
        var loaded = _mergePreservingPersonalInfo(
          StudentProfileModel.fromMap(doc.data()!, doc.id),
          localCached,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        );

        // Với tài khoản đăng nhập thực tế (không phải seed mẫu), đồng bộ từ completed_courses
        if (uid != DatabaseSeeder.defaultStudent.uid) {
          final realCompleted = await getCompletedCourses(uid);

          final uniquePassed = <String, CompletedCourseModel>{};
          for (final c in realCompleted) {
            if (c.isActuallyPassed) {
              uniquePassed[c.code] = c;
            }
          }
          final realCredits = uniquePassed.values
              .fold<int>(0, (int total, c) => total + c.credits);
          final realCodes = uniquePassed.keys.toList();
          final realGpa = GpaCalculator.calculateGpa(realCompleted);

          // Kiểm tra lại cache lần nữa phòng trường hợp người dùng vừa lưu thông tin cá nhân trong lúc chờ mạng
          final latestCached = _localProfiles[uid];
          loaded = _mergePreservingPersonalInfo(
            loaded,
            latestCached,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
          );

          loaded = loaded.copyWith(
            currentGpa:
                realCompleted.isNotEmpty ? realGpa : loaded.currentGpa,
            accumulatedCredits: realCredits,
            passedCourseCodes: realCodes,
            isNewStudent: (loaded.studentId.isEmpty &&
                loaded.major.isEmpty &&
                loaded.cohort.isEmpty &&
                loaded.targetGpa <= 0 &&
                realCompleted.isEmpty),
          );

          _localProfiles[uid] = loaded;

          // Chỉ đồng bộ các trường học thuật tính toán (TUYỆT ĐỐI KHÔNG ghi đè studentId, major, cohort, targetGpa rỗng)
          final syncUpdates = <String, dynamic>{
            'accumulatedCredits': realCredits,
            'passedCourseCodes': realCodes,
            'isNewStudent': loaded.isNewStudent,
            if (realCompleted.isNotEmpty) 'currentGpa': realGpa,
            if (loaded.email != null && loaded.email!.trim().isNotEmpty)
              'email': loaded.email,
            if (loaded.avatarUrl != null && loaded.avatarUrl!.trim().isNotEmpty)
              'avatarUrl': loaded.avatarUrl,
            if (loaded.fullName.trim().isNotEmpty &&
                loaded.fullName != 'Sinh viên mới')
              'fullName': loaded.fullName,
          };
          ref.doc(uid).set(syncUpdates, SetOptions(merge: true)).ignore();
          return loaded;
        }

        _localProfiles[uid] = loaded;
        return loaded;
      }

      // Khởi tạo hồ sơ cho tài khoản mới (giữ lại thông tin cá nhân nếu đã có trong cache)
      final profile = _mergePreservingPersonalInfo(
        DatabaseSeeder.resolveProfileForUser(
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        ),
        _localProfiles[uid],
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      _localProfiles[uid] = profile;
      final initMap = <String, dynamic>{
        'uid': uid,
        'fullName': profile.fullName,
        if (profile.email != null && profile.email!.trim().isNotEmpty)
          'email': profile.email,
        if (profile.avatarUrl != null && profile.avatarUrl!.trim().isNotEmpty)
          'avatarUrl': profile.avatarUrl,
        if (profile.studentId.trim().isNotEmpty) 'studentId': profile.studentId,
        if (profile.major.trim().isNotEmpty) 'major': profile.major,
        if (profile.cohort.trim().isNotEmpty) 'cohort': profile.cohort,
        if (profile.targetGpa > 0) 'targetGpa': profile.targetGpa,
        'totalGraduationCredits': profile.totalGraduationCredits,
        'notifyLabDeadlines': profile.notifyLabDeadlines,
        'autoWarnWorkload': profile.autoWarnWorkload,
        'syncGoogleCalendar': profile.syncGoogleCalendar,
      };
      ref.doc(uid).set(initMap, SetOptions(merge: true)).ignore();
      AppLogger.info(
        'Đã tạo hồ sơ cho người dùng $uid (isNew=${profile.isNewStudent})',
      );
      return profile;
    } catch (e) {
      AppLogger.warning('Lỗi khi lấy thông tin sinh viên từ Firestore: $e');
      final existingCached = _localProfiles[uid];
      final fallback = existingCached ??
          DatabaseSeeder.resolveProfileForUser(
            uid: uid,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
          );
      final localDone = _localCompletedCourses[uid];
      if (localDone != null && localDone.isNotEmpty) {
        final uniquePassed = <String, CompletedCourseModel>{};
        for (final c in localDone) {
          if (c.isActuallyPassed) {
            uniquePassed[c.code] = c;
          }
        }
        final localCredits = uniquePassed.values
            .fold<int>(0, (int total, c) => total + c.credits);
        final localCodes = uniquePassed.keys.toList();
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
    final current = _localProfiles[uid] ??
        DatabaseSeeder.resolveProfileForUser(
          uid: uid,
          email: email,
          displayName: fullName,
          photoUrl: avatarUrl,
        );
    final hasHttpAvatar =
        current.avatarUrl != null && current.avatarUrl!.startsWith('http');
    final resolvedAvatar = (avatarUrl != null && avatarUrl.startsWith('http'))
        ? avatarUrl
        : (hasHttpAvatar
            ? current.avatarUrl
            : (avatarUrl ?? current.avatarUrl));

    // GPA hiện tại luôn được tính tự động từ danh sách môn đã học
    final existingCompleted = _localCompletedCourses[uid];
    final calculatedCurrentGpa =
        (existingCompleted != null && existingCompleted.isNotEmpty)
            ? GpaCalculator.calculateGpa(existingCompleted)
            : (currentGpa ?? current.currentGpa);

    final cleanName =
        fullName.trim().isNotEmpty ? fullName.trim() : current.fullName;
    final cleanStudentId = studentId.trim().isNotEmpty
        ? studentId.trim().toUpperCase()
        : current.studentId;
    final cleanMajor =
        major != null ? major.trim() : current.major;
    final cleanCohort =
        cohort != null ? cohort.trim() : current.cohort;
    final cleanTargetGpa =
        (targetGpa != null && targetGpa > 0) ? targetGpa : current.targetGpa;

    final updated = current.copyWith(
      fullName: cleanName,
      studentId: cleanStudentId,
      major: cleanMajor,
      cohort: cleanCohort,
      email: email ?? current.email,
      avatarUrl: resolvedAvatar,
      currentGpa: calculatedCurrentGpa,
      targetGpa: cleanTargetGpa,
      totalGraduationCredits:
          totalGraduationCredits ?? current.totalGraduationCredits,
      isNewStudent: false, // Đã hoàn tất thiết lập thông tin cá nhân
    );

    // Cập nhật bộ nhớ đệm ngay lập tức (0ms) để mọi màn hình và tác vụ đọc song song nhận dữ liệu mới
    _localProfiles[uid] = updated;

    final ref = _studentsRef;
    if (ref != null) {
      try {
        final personalMap = <String, dynamic>{
          'fullName': updated.fullName,
          'studentId': updated.studentId,
          'major': updated.major,
          'cohort': updated.cohort,
          if (updated.email != null) 'email': updated.email,
          if (updated.avatarUrl != null) 'avatarUrl': updated.avatarUrl,
          'targetGpa': updated.targetGpa,
        };
        final updates = <String, dynamic>{
          'uid': uid,
          ...personalMap,
          'currentGpa': updated.currentGpa,
          'totalGraduationCredits': updated.totalGraduationCredits,
          'isNewStudent': false,
          'personalInfo': personalMap,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await ref
            .doc(uid)
            .set(updates, SetOptions(merge: true))
            .timeout(const Duration(seconds: 3), onTimeout: () {});
        AppLogger.info(
          'Đã cập nhật thông tin cá nhân cho ${updated.studentId} (${updated.fullName}) lên Firebase',
        );
      } catch (e, st) {
        AppLogger.error(
          'Lỗi khi cập nhật thông tin cá nhân lên Firestore',
          e,
          st,
        );
      }
    }
    return updated;
  }

  /// Lấy danh sách các môn học đang chờ Cố vấn duyệt nghiệm thu điểm trên cổng Web
  Future<List<CompletedCourseModel>> getPendingAcceptanceCourses(String uid) async {
    final firestore = _firestore;
    if (firestore == null || uid.isEmpty) return const [];
    try {
      final snap = await firestore
          .collection('study_plans')
          .where('userId', isEqualTo: uid)
          .get();
      final pendingList = <CompletedCourseModel>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        if (status == 'pending_acceptance' || status == 'acceptance_rejected') {
          final semesterName = data['semesterName'] as String?;
          final grades = (data['submittedGrades'] as List<dynamic>?) ?? const [];
          for (final g in grades) {
            if (g is Map) {
              final map = Map<String, dynamic>.from(g);
              map['semesterName'] ??= semesterName;
              pendingList.add(
                CompletedCourseModel.fromMap(
                  map,
                  (map['code'] as String?) ?? doc.id,
                ),
              );
            }
          }
        }
      }
      return pendingList;
    } catch (e) {
      AppLogger.warning('Lỗi khi tải danh sách môn chờ duyệt nghiệm thu: $e');
      return const [];
    }
  }

  /// Lấy danh sách môn đã học chính thức (đã được Cố vấn duyệt nghiệm thu) của sinh viên (SCR-03)
  Future<List<CompletedCourseModel>> getCompletedCourses(String uid) async {
    final ref = _studentsRef;
    if (ref == null) {
      return List<CompletedCourseModel>.from(
        _localCompletedCourses[uid] ?? const [],
      );
    }
    try {
      final snapshot =
          await ref.doc(uid).collection('completed_courses').get();
      final remoteList = snapshot.docs
          .map((d) => CompletedCourseModel.fromMap(d.data(), d.id))
          .toList();

      // Tự động chuẩn hóa dữ liệu nếu có môn bị sai lệch semesterIndex so với semesterName
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawIndex = (data['semesterIndex'] as num?)?.toInt();
        final sName = data['semesterName'] as String?;
        if (sName != null) {
          final m = RegExp(
            r'(?:Học kỳ|Kỳ)\s*(\d+)',
            caseSensitive: false,
          ).firstMatch(sName);
          final expectedIndex = m != null ? int.tryParse(m.group(1)!) : null;
          if (expectedIndex != null && expectedIndex != rawIndex) {
            ref.doc(uid).collection('completed_courses').doc(doc.id).update({
              'semesterIndex': expectedIndex,
            }).catchError((_) {});
          }
        }
      }

      // Chỉ sử dụng danh sách môn đã được duyệt chính thức trên Firestore
      final mergedMap = <String, CompletedCourseModel>{
        for (final c in remoteList) '${c.semesterIndex ?? 0}_${c.code}': c,
      };

      // Đồng bộ bổ sung từ các study_plans đã có status == 'completed' (nếu có)
      final firestore = _firestore;
      if (firestore != null) {
        final completedPlansSnap = await firestore
            .collection('study_plans')
            .where('userId', isEqualTo: uid)
            .get();
        for (final pDoc in completedPlansSnap.docs) {
          final pData = pDoc.data();
          if (pData['status'] == 'completed' || pData['isCompleted'] == true) {
            final submitted =
                (pData['submittedGrades'] as List<dynamic>?) ?? const [];
            for (final item in submitted) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                m['semesterName'] ??= pData['semesterName'];
                final cModel = CompletedCourseModel.fromMap(
                  m,
                  (m['code'] as String?) ?? '',
                );
                final key = '${cModel.semesterIndex ?? 0}_${cModel.code}';
                mergedMap.putIfAbsent(key, () => cModel);
              }
            }
          }
        }
      }

      final merged = mergedMap.values.toList();
      _localCompletedCourses[uid] = merged;
      return merged;
    } catch (e) {
      AppLogger.warning('Lỗi khi tải môn đã học của $uid: $e');
      return List<CompletedCourseModel>.from(
        _localCompletedCourses[uid] ?? const [],
      );
    }
  }

  /// Khai báo thêm môn đã học theo kỳ (SCR-03)
  /// - Khi kết nối Cloud Firestore: Gửi yêu cầu nghiệm thu điểm (status = 'pending_acceptance') lên Web Admin để Cố vấn duyệt trước khi cộng tín chỉ.
  /// - Khi chạy Offline Unit Test (_firestore == null): Lưu vào bộ nhớ cục bộ để phục vụ kiểm thử.
  Future<void> addCompletedCourse({
    required String uid,
    required int semesterIndex, // 1..9
    required CourseModel course,
    required double grade,
  }) async {
    final profile = _localProfiles[uid] ?? await getStudentProfile(uid);
    final existingCompleted = await getCompletedCourses(uid);
    final pendingAcceptance = await getPendingAcceptanceCourses(uid);
    final combinedForValidation = [...existingCompleted, ...pendingAcceptance];

    // 1. Kiểm tra ràng buộc tiến trình kỳ học ("kì 2 phải có kì 1")
    for (var k = 1; k < semesterIndex; k++) {
      final hasSemesterK =
          combinedForValidation.any((c) => c.semesterIndex == k);
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
      final hasPrereqInPrevSemesters =
          profile.passedCourseCodes.contains(reqCode) ||
              combinedForValidation.any(
                (c) =>
                    c.code == reqCode &&
                    c.isActuallyPassed &&
                    (c.semesterIndex == null ||
                        c.semesterIndex! < semesterIndex),
              );
      if (!hasPrereqInPrevSemesters) {
        throw ArgumentError(
          'Không thể thêm môn ${course.code} vào Kỳ $semesterIndex vì chưa hoàn thành môn tiên quyết $reqCode ở các kỳ trước!',
        );
      }
    }

    final isPassed = grade >= 4.0;
    final gradeLetter = GpaCalculator.grade10ToLetter(grade);

    // 3. Nếu có kết nối Cloud Firestore: Gửi lên study_plans với status = 'pending_acceptance' chờ Cố vấn duyệt trên Web
    final firestore = _firestore;
    if (firestore != null) {
      final semesterName = 'Học kỳ $semesterIndex';
      final planId = '${uid}_Hoc_ky_$semesterIndex';
      final planRef = firestore.collection('study_plans').doc(planId);
      final existingSnap = await planRef.get();

      final existingCourses = <Map<String, dynamic>>[];
      final existingGrades = <Map<String, dynamic>>[];

      if (existingSnap.exists && existingSnap.data() != null) {
        final data = existingSnap.data()!;
        // Chỉ gộp nếu bản ghi đó đang chờ duyệt nghiệm thu hoặc bị từ chối nghiệm thu
        if (data['status'] != 'completed') {
          final rawCourses = (data['courses'] as List<dynamic>?) ?? const [];
          for (final c in rawCourses) {
            if (c is Map && c['code'] != course.code) {
              existingCourses.add(Map<String, dynamic>.from(c));
            }
          }
          final rawGrades =
              (data['submittedGrades'] as List<dynamic>?) ?? const [];
          for (final g in rawGrades) {
            if (g is Map && g['code'] != course.code) {
              existingGrades.add(Map<String, dynamic>.from(g));
            }
          }
        }
      }

      existingCourses.add(course.toMap());
      existingGrades.add({
        'courseId': course.id,
        'code': course.code,
        'name': course.name,
        'credits': course.credits,
        'grade': grade,
        'gradeLetter': gradeLetter,
        'isPassed': isPassed,
        'semesterIndex': semesterIndex,
        'semesterName': semesterName,
      });

      final totalCredits = existingCourses.fold<int>(
        0,
        (acc, c) => acc + ((c['credits'] as num?)?.toInt() ?? 3),
      );
      final totalHours = existingCourses.fold<double>(
        0.0,
        (acc, c) =>
            acc + ((c['plannedSelfStudyHours'] as num?)?.toDouble() ?? 6.0),
      );

      await planRef.set({
        'id': planId,
        'userId': uid,
        'studentName': profile.fullName,
        'studentCode': profile.studentId,
        'studentEmail': profile.email ?? '',
        'semesterName': semesterName,
        'courses': existingCourses,
        'submittedGrades': existingGrades,
        'totalCredits': totalCredits,
        'totalSelfStudyHours': totalHours,
        'maxSafeThresholdHours': 25.0,
        'targetGpa': profile.targetGpa > 0 ? profile.targetGpa : 3.65,
        'tuitionFee': totalCredits * 950000,
        'isSaved': true,
        'isCompleted': false,
        'status': 'pending_acceptance',
        'reviewReason': null,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      AppLogger.info(
        'Đã gửi môn ${course.code} (Kỳ $semesterIndex, điểm $grade) lên hàng đợi chờ Cố vấn duyệt nghiệm thu trên Web!',
      );
      return;
    }

    // 4. Chế độ Offline / Unit Test (_firestore == null): Cập nhật local phục vụ test
    final newCompletedCourse = CompletedCourseModel(
      code: course.code,
      name: course.name,
      credits: course.credits,
      semesterIndex: semesterIndex,
      grade: grade,
      gradeLetter: gradeLetter,
      isPassed: isPassed,
    );

    final updatedCompletedList = [
      ...existingCompleted.where(
        (c) => !(c.code == course.code && c.semesterIndex == semesterIndex),
      ),
      newCompletedCourse,
    ];
    _localCompletedCourses[uid] = updatedCompletedList;

    final uniquePassed = <String, CompletedCourseModel>{};
    for (final c in updatedCompletedList) {
      if (c.isActuallyPassed) {
        uniquePassed[c.code] = c;
      }
    }

    final updatedPassedCodes = uniquePassed.keys.toList();
    final updatedCredits = uniquePassed.values
        .fold<int>(0, (int total, c) => total + c.credits);
    final updatedGpa = GpaCalculator.calculateGpa(updatedCompletedList);

    final latestProfile = _localProfiles[uid] ?? profile;
    _localProfiles[uid] = latestProfile.copyWith(
      passedCourseCodes: updatedPassedCodes,
      accumulatedCredits: updatedCredits,
      currentGpa: updatedGpa,
      isNewStudent: false,
    );
  }

  /// Gửi yêu cầu nghiệm thu kỳ học từ bản kế hoạch đã được duyệt (SCR-07)
  /// - Khi kết nối Cloud Firestore: KHÔNG tự động ghi vào completed_courses hay cộng tín chỉ ngay,
  ///   mà lưu bảng điểm sinh viên kê khai vào study_plans với status = 'pending_acceptance' để Cố vấn trên Web duyệt.
  /// - Khi chạy Offline Unit Test (_firestore == null): Cập nhật local phục vụ kiểm thử.
  Future<int> completeSemesterFromPlan({
    required String uid,
    required StudyPlanModel plan,
    List<CourseGradeItem>? courseGrades,
  }) async {
    if (plan.selectedCourses.isEmpty) return 0;

    final profile = _localProfiles[uid] ?? await getStudentProfile(uid);
    final existingCompleted = await getCompletedCourses(uid);

    int? plannedSemesterIndex;
    final match = RegExp(
      r'(?:Học kỳ|Kỳ)\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(plan.semesterName);
    if (match != null) {
      plannedSemesterIndex = int.tryParse(match.group(1)!);
    }
    final maxExistingSemester = existingCompleted
        .map((c) => c.semesterIndex ?? 0)
        .fold<int>(0, (prev, elem) => elem > prev ? elem : prev);
    final targetSemester = plannedSemesterIndex ?? (maxExistingSemester + 1);

    final Map<String, CourseGradeItem> gradeMap = {
      if (courseGrades != null)
        for (final item in courseGrades) item.course.code: item,
    };

    final submittedGrades = <Map<String, dynamic>>[];
    for (final course in plan.selectedCourses) {
      final gradeItem = gradeMap[course.code];
      final bool isPassed = gradeItem?.isPassed ?? true;
      final double defaultGrade = course.selectedGradeTarget == 'A'
          ? 8.8
          : (course.selectedGradeTarget == 'B' ? 7.5 : 6.0);
      final double grade = gradeItem?.grade ?? defaultGrade;
      final String gradeLetter = GpaCalculator.grade10ToLetter(grade);
      final bool isActuallyPassed = isPassed && grade >= 4.0;

      submittedGrades.add({
        'courseId': course.id,
        'code': course.code,
        'name': course.name,
        'credits': course.credits,
        'grade': grade,
        'gradeLetter': gradeLetter,
        'isPassed': isActuallyPassed,
        'semesterIndex': targetSemester,
        'semesterName': plan.semesterName,
      });
    }

    // Khi có kết nối Cloud Firestore: Gửi bảng điểm lên study_plans với status = 'pending_acceptance'
    // TUYỆT ĐỐI KHÔNG tự cộng tín chỉ hay ghi thẳng vào completed_courses khi chưa có Cố vấn duyệt trên Web!
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final planRef = firestore.collection('study_plans').doc(plan.id);
        final updatedPlan = plan.copyWith(
          studentName: profile.fullName,
          studentCode: profile.studentId,
          status: 'pending_acceptance',
          isCompleted: false,
          isSaved: true,
          submittedGrades: submittedGrades,
          updatedAt: DateTime.now(),
        );
        await planRef.set({
          ...updatedPlan.toMap(),
          'status': 'pending_acceptance',
          'isCompleted': false,
          'submittedGrades': submittedGrades,
          'reviewReason': null,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        AppLogger.info(
          'Đã gửi bảng điểm nghiệm thu kỳ học ${plan.id} (status=pending_acceptance) chờ Cố vấn duyệt trên Web!',
        );
      } catch (e, st) {
        AppLogger.error('Chi tiết lỗi khi gửi nghiệm thu kỳ học lên Firestore', e, st);
        rethrow;
      }
      return targetSemester;
    }

    // Chế độ Offline / Unit Test (_firestore == null): Cập nhật local phục vụ kiểm thử
    final updatedCompletedMap = <String, CompletedCourseModel>{
      for (final c in existingCompleted)
        '${c.semesterIndex ?? 0}_${c.code}': c,
    };
    final newPassedCodes = Set<String>.from(profile.passedCourseCodes);

    for (final g in submittedGrades) {
      final code = g['code'] as String;
      final isActuallyPassed = g['isPassed'] as bool;
      final docKey = '${targetSemester}_$code';
      updatedCompletedMap[docKey] = CompletedCourseModel(
        code: code,
        name: g['name'] as String,
        credits: g['credits'] as int,
        semesterIndex: targetSemester,
        semesterName: plan.semesterName,
        grade: g['grade'] as double,
        gradeLetter: g['gradeLetter'] as String,
        isPassed: isActuallyPassed,
      );
      if (isActuallyPassed) {
        newPassedCodes.add(code);
      }
    }

    final allCompletedList = updatedCompletedMap.values.toList();
    _localCompletedCourses[uid] = allCompletedList;

    final uniquePassed = <String, CompletedCourseModel>{};
    for (final c in allCompletedList) {
      if (c.isActuallyPassed) {
        uniquePassed[c.code] = c;
      }
    }
    final allCredits = uniquePassed.values
        .fold<int>(0, (int total, c) => total + c.credits);
    final updatedGpa = GpaCalculator.calculateGpa(allCompletedList);

    final latestProfile = _localProfiles[uid] ?? profile;
    _localProfiles[uid] = latestProfile.copyWith(
      accumulatedCredits: allCredits,
      passedCourseCodes: uniquePassed.keys.toList(),
      currentGpa: updatedGpa,
      isNewStudent: false,
    );

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
      await ref
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      AppLogger.info(
        'Đã cập nhật hồ sơ sinh viên ${profile.studentId} lên Firestore',
      );
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
    final current = _localProfiles[uid] ?? await getStudentProfile(uid);
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
        if (notifyLabDeadlines != null) {
          updates['notifyLabDeadlines'] = notifyLabDeadlines;
        }
        if (autoWarnWorkload != null) {
          updates['autoWarnWorkload'] = autoWarnWorkload;
        }
        if (syncGoogleCalendar != null) {
          updates['syncGoogleCalendar'] = syncGoogleCalendar;
        }

        await ref
            .doc(uid)
            .set(updates, SetOptions(merge: true))
            .timeout(const Duration(seconds: 3), onTimeout: () {});
        AppLogger.info('Đã lưu cài đặt thông báo cho $uid');
      } catch (e) {
        AppLogger.warning('Lỗi khi lưu cài đặt: $e');
      }
    }
    return updated;
  }
}
