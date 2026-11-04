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
    return {
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
  }

  factory StudentProfileModel.fromMap(Map<String, dynamic> map, String docId) {
    return StudentProfileModel(
      uid: docId,
      fullName: map['fullName'] ?? 'Trần Hoàng Long',
      studentId: map['studentId'] ?? 'SE180504',
      email: map['email'],
      major: map['major'] ?? 'Kỹ thuật Phần mềm',
      cohort: map['cohort'] ?? 'K18',
      accumulatedCredits: (map['accumulatedCredits'] as num?)?.toInt() ?? 90,
      totalGraduationCredits:
          (map['totalGraduationCredits'] as num?)?.toInt() ?? 145,
      currentGpa: (map['currentGpa'] as num?)?.toDouble() ?? 3.42,
      targetGpa: (map['targetGpa'] as num?)?.toDouble() ?? 3.65,
      avatarUrl: map['avatarUrl'],
      passedCourseCodes: List<String>.from(
        map['passedCourseCodes'] ?? ['PRO192', 'MAD101', 'CSD201'],
      ),
      notifyLabDeadlines: map['notifyLabDeadlines'] ?? true,
      autoWarnWorkload: map['autoWarnWorkload'] ?? true,
      syncGoogleCalendar: map['syncGoogleCalendar'] ?? false,
      isNewStudent: map['isNewStudent'] ?? false,
    );
  }
}
