import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_plan_model.dart';

class WebPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('study_plans');

  final Map<String, Map<String, String>> _studentInfoCache = {};

  Stream<List<StudyPlanModel>> streamPlans() {
    return _plansRef.snapshots().asyncMap((snapshot) async {
      final plans = snapshot.docs.map((doc) {
        return StudyPlanModel.fromMap(doc.data(), doc.id);
      }).toList();

      for (var i = 0; i < plans.length; i++) {
        final p = plans[i];
        if (p.userId.isEmpty) continue;

        if (p.studentEmail.isEmpty ||
            p.studentCode.isEmpty ||
            p.studentName.isEmpty ||
            p.studentName == 'Sinh viên' ||
            p.studentName == 'Sinh viên mới') {
          if (!_studentInfoCache.containsKey(p.userId)) {
            String fetchedName = '';
            String fetchedCode = '';
            String fetchedEmail = '';

            try {
              // 1. Tra cứu trong collection students
              final sDoc =
                  await _firestore.collection('students').doc(p.userId).get();
              if (sDoc.exists && sDoc.data() != null) {
                final d = sDoc.data()!;
                fetchedName = (d['fullName'] as String? ??
                        d['displayName'] as String? ??
                        '')
                    .trim();
                fetchedCode = (d['studentId'] as String? ??
                        d['mssv'] as String? ??
                        '')
                    .trim();
                fetchedEmail = (d['email'] as String? ?? '').trim();
              }
            } catch (_) {}

            try {
              // 2. Tra cứu thêm trong collection users nếu thiếu tên, mssv hoặc email
              if (fetchedName.isEmpty ||
                  fetchedName == 'Sinh viên' ||
                  fetchedName == 'Sinh viên mới' ||
                  fetchedCode.isEmpty ||
                  fetchedEmail.isEmpty) {
                final uDoc =
                    await _firestore.collection('users').doc(p.userId).get();
                if (uDoc.exists && uDoc.data() != null) {
                  final d = uDoc.data()!;
                  final uName = (d['displayName'] as String? ??
                          d['fullName'] as String? ??
                          '')
                      .trim();
                  final uCode = (d['studentId'] as String? ??
                          d['mssv'] as String? ??
                          '')
                      .trim();
                  final uEmail = (d['email'] as String? ?? '').trim();

                  if (fetchedName.isEmpty ||
                      fetchedName == 'Sinh viên' ||
                      fetchedName == 'Sinh viên mới') {
                    fetchedName = uName;
                  }
                  if (fetchedCode.isEmpty) fetchedCode = uCode;
                  if (fetchedEmail.isEmpty) fetchedEmail = uEmail;
                }
              }
            } catch (_) {}

            _studentInfoCache[p.userId] = {
              'name': fetchedName,
              'code': fetchedCode,
              'email': fetchedEmail,
            };
          }

          final cached = _studentInfoCache[p.userId];
          String updatedName = p.studentName;
          String updatedCode = p.studentCode;
          String updatedEmail = p.studentEmail;

          if (cached != null) {
            if ((updatedName.isEmpty ||
                    updatedName == 'Sinh viên' ||
                    updatedName == 'Sinh viên mới') &&
                (cached['name']?.isNotEmpty ?? false) &&
                cached['name'] != 'Sinh viên' &&
                cached['name'] != 'Sinh viên mới') {
              updatedName = cached['name']!;
            }
            if (updatedCode.isEmpty && (cached['code']?.isNotEmpty ?? false)) {
              updatedCode = cached['code']!;
            }
            if (updatedEmail.isEmpty && (cached['email']?.isNotEmpty ?? false)) {
              updatedEmail = cached['email']!;
            }
          }

          // Fallback persona mẫu nếu userId chứa mã
          if (p.userId.contains('se180504') || p.userId == 'student_se180504') {
            if (updatedName.isEmpty || updatedName == 'Sinh viên' || updatedName == 'Sinh viên mới') {
              updatedName = 'Trần Hoàng Long';
            }
            if (updatedCode.isEmpty) updatedCode = 'SE180504';
            if (updatedEmail.isEmpty) updatedEmail = 'longth.se180504@gmail.com';
          } else if (p.userId.contains('se170123') || p.userId == 'student_se170123') {
            if (updatedName.isEmpty || updatedName == 'Sinh viên' || updatedName == 'Sinh viên mới') {
              updatedName = 'Nguyễn Mai Linh';
            }
            if (updatedCode.isEmpty) updatedCode = 'SE170123';
            if (updatedEmail.isEmpty) updatedEmail = 'linhnm.se170123@gmail.com';
          } else if (p.userId.contains('se190456') || p.userId == 'student_se190456') {
            if (updatedName.isEmpty || updatedName == 'Sinh viên' || updatedName == 'Sinh viên mới') {
              updatedName = 'Lê Minh Tuấn';
            }
            if (updatedCode.isEmpty) updatedCode = 'SE190456';
            if (updatedEmail.isEmpty) updatedEmail = 'tuanlm.se190456@gmail.com';
          }

          // Trích xuất mã số sinh viên từ email hoặc userId
          if (updatedCode.isEmpty) {
            final match = RegExp(
              r'(se|sa|ss|sb|cs|ia|he|hs|ha|de)\d{5,7}',
              caseSensitive: false,
            ).firstMatch('${p.userId} $updatedEmail $updatedName');
            if (match != null) {
              updatedCode = match.group(0)!.toUpperCase();
            }
          }

          // Trích xuất tên từ email nếu vẫn trống
          if ((updatedName.isEmpty || updatedName == 'Sinh viên' || updatedName == 'Sinh viên mới') &&
              updatedEmail.isNotEmpty) {
            final prefix = updatedEmail.split('@').first;
            updatedName = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ').trim();
          }

          if (updatedName.isEmpty || updatedName == 'Sinh viên mới') {
            updatedName = 'Sinh viên';
          }

          plans[i] = p.copyWith(
            studentName: updatedName,
            studentCode: updatedCode,
            studentEmail: updatedEmail,
          );
        }
      }

      return plans;
    });
  }

  Future<void> reviewPlan({
    required String planId,
    required bool isApproved,
    required String reviewerEmail,
    required String reviewReason,
  }) async {
    final status = isApproved ? 'approved' : 'rejected';
    await _plansRef.doc(planId).update({
      'status': status,
      'reviewReason': reviewReason,
      'reviewedBy': reviewerEmail,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getCompletedCoursesForStudent(
    String userId, {
    String? semesterName,
  }) async {
    try {
      final snap = await _firestore
          .collection('students')
          .doc(userId)
          .collection('completed_courses')
          .get();

      if (snap.docs.isEmpty) return [];

      final list = snap.docs.map((d) => d.data()).toList();
      if (semesterName != null && semesterName.isNotEmpty) {
        final matches = list.where((c) {
          final sem = c['semesterName'] as String?;
          return sem != null &&
              (sem == semesterName ||
                  semesterName.contains(sem) ||
                  sem.contains(semesterName));
        }).toList();
        if (matches.isNotEmpty) return matches;
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  static int _parseSemesterNumber(String semesterName) {
    final match = RegExp(r'(?:Học kỳ|Kỳ)\s*(\d+)', caseSensitive: false)
        .firstMatch(semesterName);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    return 1;
  }

  static double _score10ToGpa4(double score10) {
    if (score10 >= 8.5) return 4.0;
    if (score10 >= 8.0) return 3.5;
    if (score10 >= 7.0) return 3.0;
    if (score10 >= 6.5) return 2.5;
    if (score10 >= 5.5) return 2.0;
    if (score10 >= 5.0) return 1.5;
    if (score10 >= 4.0) return 1.0;
    return 0.0;
  }

  static String _gradeToLetter(double grade) {
    if (grade >= 8.5) return 'A';
    if (grade >= 8.0) return 'B+';
    if (grade >= 7.0) return 'B';
    if (grade >= 6.5) return 'C+';
    if (grade >= 5.5) return 'C';
    if (grade >= 5.0) return 'D+';
    if (grade >= 4.0) return 'D';
    return 'F';
  }

  /// Duyệt nghiệm thu kết quả học tập học kỳ:
  /// - Nếu [isApproved] == false: chuyển trạng thái kế hoạch sang 'acceptance_rejected' để sinh viên sửa lại điểm.
  /// - Nếu [isApproved] == true: chính thức ghi các môn vào students/{userId}/completed_courses,
  ///   cập nhật accumulatedCredits, passedCourseCodes, currentGpa trên students/{userId},
  ///   và chuyển trạng thái study_plans/{plan.id} sang 'completed'.
  Future<void> reviewSemesterAcceptance({
    required StudyPlanModel plan,
    required bool isApproved,
    required String reviewerEmail,
    required String reviewReason,
  }) async {
    if (!isApproved) {
      await _plansRef.doc(plan.id).update({
        'status': 'acceptance_rejected',
        'isCompleted': false,
        'reviewReason': reviewReason,
        'reviewedBy': reviewerEmail,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final defaultSemIdx = _parseSemesterNumber(plan.semesterName);
    final rawGrades = plan.submittedGrades.isNotEmpty
        ? plan.submittedGrades
        : plan.courses.map((c) {
            final g = (c['grade'] as num?)?.toDouble() ?? 7.5;
            return <String, dynamic>{
              'code': c['code'] ?? '',
              'name': c['name'] ?? '',
              'credits': (c['credits'] as num?)?.toInt() ??
                  (c['credit'] as num?)?.toInt() ??
                  3,
              'semesterIndex': defaultSemIdx,
              'semesterName': plan.semesterName,
              'grade': g,
              'gradeLetter': _gradeToLetter(g),
              'isPassed': g >= 4.0,
            };
          }).toList();

    final studentRef = _firestore.collection('students').doc(plan.userId);
    final completedCol = studentRef.collection('completed_courses');

    final existingSnap = await completedCol.get();
    final mergedByDocId = <String, Map<String, dynamic>>{};
    for (final doc in existingSnap.docs) {
      mergedByDocId[doc.id] = Map<String, dynamic>.from(doc.data());
    }

    final batch = _firestore.batch();

    for (final item in rawGrades) {
      final code = (item['code'] as String? ?? '').trim();
      if (code.isEmpty) continue;
      final semIdx = (item['semesterIndex'] as num?)?.toInt() ?? defaultSemIdx;
      final semName = (item['semesterName'] as String?)?.isNotEmpty == true
          ? item['semesterName'] as String
          : plan.semesterName;
      final credits = (item['credits'] as num?)?.toInt() ?? 3;
      final grade = (item['grade'] as num?)?.toDouble() ?? 7.5;
      final letter = item['gradeLetter'] as String? ?? _gradeToLetter(grade);
      final isPassed = item['isPassed'] as bool? ?? (grade >= 4.0);

      final docId = '${semIdx}_$code';
      final courseData = <String, dynamic>{
        'code': code,
        'name': item['name'] as String? ?? code,
        'credits': credits,
        'semesterIndex': semIdx,
        'semesterName': semName,
        'grade': grade,
        'gradeLetter': letter,
        'isPassed': isPassed,
        'completedAt': DateTime.now().toIso8601String(),
      };

      mergedByDocId[docId] = courseData;
      batch.set(completedCol.doc(docId), courseData, SetOptions(merge: true));
    }

    // Tính toán lại tổng tín chỉ tích lũy, danh sách môn qua, và GPA hệ 4.0
    final passedCodeSet = <String>{};
    final passedCreditsByCode = <String, int>{};
    double totalWeightedGpa4 = 0.0;
    int totalGradedCredits = 0;

    for (final c in mergedByDocId.values) {
      final code = (c['code'] as String? ?? '').trim();
      final cr = (c['credits'] as num?)?.toInt() ?? 3;
      final g = (c['grade'] as num?)?.toDouble() ?? 0.0;
      final isPass = c['isPassed'] as bool? ?? (g >= 4.0);
      if (code.isNotEmpty && isPass) {
        passedCodeSet.add(code);
        passedCreditsByCode[code] = cr;
      }
      if (cr > 0) {
        totalWeightedGpa4 += _score10ToGpa4(g) * cr;
        totalGradedCredits += cr;
      }
    }

    final newAccumulatedCredits =
        passedCreditsByCode.values.fold<int>(0, (acc, v) => acc + v);
    final newCurrentGpa = totalGradedCredits > 0
        ? double.parse(
            (totalWeightedGpa4 / totalGradedCredits).toStringAsFixed(2))
        : 0.0;

    batch.set(
      studentRef,
      {
        'accumulatedCredits': newAccumulatedCredits,
        'passedCourseCodes': passedCodeSet.toList(),
        'currentGpa': newCurrentGpa,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.update(_plansRef.doc(plan.id), {
      'status': 'completed',
      'isCompleted': true,
      'reviewReason': reviewReason,
      'reviewedBy': reviewerEmail,
      'reviewedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> confirmSemesterAcceptance({
    required String planId,
    required String reviewerEmail,
    required String reviewReason,
  }) async {
    final snap = await _plansRef.doc(planId).get();
    if (snap.exists && snap.data() != null) {
      final plan = StudyPlanModel.fromMap(snap.data()!, snap.id);
      await reviewSemesterAcceptance(
        plan: plan,
        isApproved: true,
        reviewerEmail: reviewerEmail,
        reviewReason: reviewReason,
      );
      return;
    }
    await _plansRef.doc(planId).update({
      'status': 'completed',
      'isCompleted': true,
      'reviewReason': reviewReason,
      'reviewedBy': reviewerEmail,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
