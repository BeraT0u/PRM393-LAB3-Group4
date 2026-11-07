class StudentProfileModel {
  final String uid;
  final String fullName;
  final String studentId;
  final String? email;
  final String major;
  final String cohort;
  final int accumulatedCredits;
  final int totalGraduationCredits;
  final double currentGpa;
  final double targetGpa;
  final String? avatarUrl;
  final List<String> passedCourseCodes;
  final bool notifyLabDeadlines;
  final bool autoWarnWorkload;
  final bool syncGoogleCalendar;
  final bool isNewStudent;

  const StudentProfileModel({
    required this.uid,
    required this.fullName,
    required this.studentId,
    this.email,
    this.major = 'Kỹ thuật Phần mềm',
    this.cohort = 'K18',
    this.accumulatedCredits = 90,
    this.totalGraduationCredits = 145,
    this.currentGpa = 3.42,
    this.targetGpa = 3.65,
    this.avatarUrl,
    this.passedCourseCodes = const [
      'PRO192',
      'MAD101',
      'CSD201',
      'DBI202',
      'MAS291',
    ],
    this.notifyLabDeadlines = true,
    this.autoWarnWorkload = true,
    this.syncGoogleCalendar = false,
    this.isNewStudent = false,
  });

  bool get notificationEnabled => notifyLabDeadlines;
  bool get calendarSyncEnabled => syncGoogleCalendar;

  /// Chữ viết tắt 2 ký tự hiển thị trên Avatar (VD: "Trần Hoàng Long" -> "HL")
  String get avatarInitials {
    if (avatarUrl != null &&
        avatarUrl!.trim().isNotEmpty &&
        avatarUrl!.trim().length <= 3) {
      return avatarUrl!.trim().toUpperCase();
    }
    final words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final a = words[words.length - 2];
      final b = words.last;
      if (a.isNotEmpty && b.isNotEmpty) {
        return '${a[0]}${b[0]}'.toUpperCase();
      }
    }
    if (fullName.trim().length >= 2) {
      return fullName.trim().substring(0, 2).toUpperCase();
    }
    return 'SV';
  }

  StudentProfileModel copyWith({
    String? uid,
    String? fullName,
    String? studentId,
    String? email,
    String? major,
    String? cohort,
    int? accumulatedCredits,
    int? totalGraduationCredits,
    double? currentGpa,
    double? targetGpa,
    String? avatarUrl,
    List<String>? passedCourseCodes,
    bool? notifyLabDeadlines,
    bool? autoWarnWorkload,
    bool? syncGoogleCalendar,
    bool? isNewStudent,
  }) {
    return StudentProfileModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      major: major ?? this.major,
      cohort: cohort ?? this.cohort,
      accumulatedCredits: accumulatedCredits ?? this.accumulatedCredits,
      totalGraduationCredits:
          totalGraduationCredits ?? this.totalGraduationCredits,
      currentGpa: currentGpa ?? this.currentGpa,
      targetGpa: targetGpa ?? this.targetGpa,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      passedCourseCodes: passedCourseCodes ?? this.passedCourseCodes,
      notifyLabDeadlines: notifyLabDeadlines ?? this.notifyLabDeadlines,
      autoWarnWorkload: autoWarnWorkload ?? this.autoWarnWorkload,
      syncGoogleCalendar: syncGoogleCalendar ?? this.syncGoogleCalendar,
      isNewStudent: isNewStudent ?? this.isNewStudent,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'studentId': studentId,
      'email': email,
      'major': major,
      'cohort': cohort,
      'accumulatedCredits': accumulatedCredits,
      'totalGraduationCredits': totalGraduationCredits,
      'currentGpa': currentGpa,
      'targetGpa': targetGpa,
      'avatarUrl': avatarUrl,
      'passedCourseCodes': passedCourseCodes,
      'notifyLabDeadlines': notifyLabDeadlines,
      'autoWarnWorkload': autoWarnWorkload,
      'syncGoogleCalendar': syncGoogleCalendar,
      'isNewStudent': isNewStudent,
    };
    if (studentId.trim().isNotEmpty ||
        major.trim().isNotEmpty ||
        cohort.trim().isNotEmpty ||
        targetGpa > 0) {
      map['personalInfo'] = {
        'fullName': fullName,
        'studentId': studentId,
        'email': email,
        'major': major,
        'cohort': cohort,
        'targetGpa': targetGpa,
        'avatarUrl': avatarUrl,
      };
    }
    return map;
  }

  factory StudentProfileModel.fromMap(Map<String, dynamic> map, String docId) {
    final personal = map['personalInfo'] is Map
        ? Map<String, dynamic>.from(map['personalInfo'] as Map)
        : const <String, dynamic>{};

    String pickNonEmpty(String key) {
      final top = (map[key] as String?)?.trim() ?? '';
      if (top.isNotEmpty) return top;
      return (personal[key] as String?)?.trim() ?? '';
    }

    final topTargetGpa = (map['targetGpa'] as num?)?.toDouble() ?? 0.0;
    final backupTargetGpa = (personal['targetGpa'] as num?)?.toDouble() ?? 0.0;
    final resolvedTargetGpa =
        topTargetGpa > 0 ? topTargetGpa : backupTargetGpa;

    final resolvedStudentId = pickNonEmpty('studentId');
    final resolvedMajor = pickNonEmpty('major');
    final resolvedCohort = pickNonEmpty('cohort');

    return StudentProfileModel(
      uid: docId,
      fullName: pickNonEmpty('fullName'),
      studentId: resolvedStudentId,
      email: (map['email'] as String?) ?? (personal['email'] as String?),
      major: resolvedMajor,
      cohort: resolvedCohort,
      accumulatedCredits: (map['accumulatedCredits'] as num?)?.toInt() ?? 0,
      totalGraduationCredits:
          (map['totalGraduationCredits'] as num?)?.toInt() ?? 145,
      currentGpa: (map['currentGpa'] as num?)?.toDouble() ?? 0.0,
      targetGpa: resolvedTargetGpa,
      avatarUrl:
          (map['avatarUrl'] as String?) ?? (personal['avatarUrl'] as String?),
      passedCourseCodes: List<String>.from(
        map['passedCourseCodes'] ?? const <String>[],
      ),
      notifyLabDeadlines: map['notifyLabDeadlines'] ?? true,
      autoWarnWorkload: map['autoWarnWorkload'] ?? true,
      syncGoogleCalendar: map['syncGoogleCalendar'] ?? false,
      isNewStudent: (resolvedStudentId.isNotEmpty ||
              resolvedMajor.isNotEmpty ||
              resolvedCohort.isNotEmpty ||
              resolvedTargetGpa > 0)
          ? false
          : (map['isNewStudent'] ?? false),
    );
  }
}
