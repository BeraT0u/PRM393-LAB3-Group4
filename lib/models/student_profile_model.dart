class StudentProfileModel {
  final String uid;
  final String fullName;
  final String studentId;
  final int accumulatedCredits;
  final int totalGraduationCredits;
  final double currentGpa;
  final double targetGpa;
  final String? avatarUrl;
  final List<String> passedCourseCodes;
  final bool notifyLabDeadlines;
  final bool autoWarnWorkload;
  final bool syncGoogleCalendar;

  const StudentProfileModel({
    required this.uid,
    required this.fullName,
    required this.studentId,
    this.accumulatedCredits = 90,
    this.totalGraduationCredits = 145,
    this.currentGpa = 3.42,
    this.targetGpa = 3.65,
    this.avatarUrl,
    this.passedCourseCodes = const ['PRO192', 'MAD101', 'CSD201', 'DBI202', 'MAS291'],
    this.notifyLabDeadlines = true,
    this.autoWarnWorkload = true,
    this.syncGoogleCalendar = false,
  });

  StudentProfileModel copyWith({
    String? uid,
    String? fullName,
    String? studentId,
    int? accumulatedCredits,
    int? totalGraduationCredits,
    double? currentGpa,
    double? targetGpa,
    String? avatarUrl,
    List<String>? passedCourseCodes,
    bool? notifyLabDeadlines,
    bool? autoWarnWorkload,
    bool? syncGoogleCalendar,
  }) {
    return StudentProfileModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      accumulatedCredits: accumulatedCredits ?? this.accumulatedCredits,
      totalGraduationCredits: totalGraduationCredits ?? this.totalGraduationCredits,
      currentGpa: currentGpa ?? this.currentGpa,
      targetGpa: targetGpa ?? this.targetGpa,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      passedCourseCodes: passedCourseCodes ?? this.passedCourseCodes,
      notifyLabDeadlines: notifyLabDeadlines ?? this.notifyLabDeadlines,
      autoWarnWorkload: autoWarnWorkload ?? this.autoWarnWorkload,
      syncGoogleCalendar: syncGoogleCalendar ?? this.syncGoogleCalendar,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'studentId': studentId,
      'accumulatedCredits': accumulatedCredits,
      'totalGraduationCredits': totalGraduationCredits,
      'currentGpa': currentGpa,
      'targetGpa': targetGpa,
      'avatarUrl': avatarUrl,
      'passedCourseCodes': passedCourseCodes,
      'notifyLabDeadlines': notifyLabDeadlines,
      'autoWarnWorkload': autoWarnWorkload,
      'syncGoogleCalendar': syncGoogleCalendar,
    };
  }

  factory StudentProfileModel.fromMap(Map<String, dynamic> map, String docId) {
    return StudentProfileModel(
      uid: docId,
      fullName: map['fullName'] ?? 'Trần Hoàng Long',
      studentId: map['studentId'] ?? 'SE180504',
      accumulatedCredits: (map['accumulatedCredits'] as num?)?.toInt() ?? 90,
      totalGraduationCredits: (map['totalGraduationCredits'] as num?)?.toInt() ?? 145,
      currentGpa: (map['currentGpa'] as num?)?.toDouble() ?? 3.42,
      targetGpa: (map['targetGpa'] as num?)?.toDouble() ?? 3.65,
      avatarUrl: map['avatarUrl'],
      passedCourseCodes: List<String>.from(map['passedCourseCodes'] ?? ['PRO192', 'MAD101', 'CSD201']),
      notifyLabDeadlines: map['notifyLabDeadlines'] ?? true,
      autoWarnWorkload: map['autoWarnWorkload'] ?? true,
      syncGoogleCalendar: map['syncGoogleCalendar'] ?? false,
    );
  }
}
