class StudyPlanModel {
  final String id;
  final String userId;
  final String studentName;
  final String studentCode;
  final String studentEmail;
  final String semesterName;
  final List<Map<String, dynamic>> courses;
  final int totalCredits;
  final double totalSelfStudyHours;
  final double maxSafeThresholdHours;
  final int tuitionFee;
  final String status; // 'draft' | 'pending' | 'approved' | 'rejected' | 'pending_acceptance' | 'acceptance_rejected' | 'completed'
  final String? reviewReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final List<Map<String, dynamic>> submittedGrades;

  StudyPlanModel({
    required this.id,
    required this.userId,
    required this.studentName,
    this.studentCode = '',
    this.studentEmail = '',
    required this.semesterName,
    this.courses = const [],
    this.totalCredits = 0,
    this.totalSelfStudyHours = 0.0,
    this.maxSafeThresholdHours = 25.0,
    this.tuitionFee = 0,
    this.status = 'pending',
    this.reviewReason,
    this.reviewedBy,
    this.reviewedAt,
    this.submittedGrades = const [],
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPendingAcceptance => status == 'pending_acceptance';
  bool get isAcceptanceRejected => status == 'acceptance_rejected';
  bool get isCompleted => status == 'completed';

  StudyPlanModel copyWith({
    String? id,
    String? userId,
    String? studentName,
    String? studentCode,
    String? studentEmail,
    String? semesterName,
    List<Map<String, dynamic>>? courses,
    int? totalCredits,
    double? totalSelfStudyHours,
    double? maxSafeThresholdHours,
    int? tuitionFee,
    String? status,
    String? reviewReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    List<Map<String, dynamic>>? submittedGrades,
  }) {
    return StudyPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
      studentEmail: studentEmail ?? this.studentEmail,
      semesterName: semesterName ?? this.semesterName,
      courses: courses ?? this.courses,
      totalCredits: totalCredits ?? this.totalCredits,
      totalSelfStudyHours: totalSelfStudyHours ?? this.totalSelfStudyHours,
      maxSafeThresholdHours: maxSafeThresholdHours ?? this.maxSafeThresholdHours,
      tuitionFee: tuitionFee ?? this.tuitionFee,
      status: status ?? this.status,
      reviewReason: reviewReason ?? this.reviewReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      submittedGrades: submittedGrades ?? this.submittedGrades,
    );
  }

  factory StudyPlanModel.fromMap(Map<String, dynamic> map, String id) {
    final coursesList = (map['courses'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        [];

    final submittedGradesList = (map['submittedGrades'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        [];

    // Parse or auto-calculate total credits from courses if missing or 0
    int parsedCredits = (map['totalCredits'] as num?)?.toInt() ??
        (map['credits'] as num?)?.toInt() ??
        (map['totalCredit'] as num?)?.toInt() ??
        0;

    if (parsedCredits == 0 && coursesList.isNotEmpty) {
      parsedCredits = coursesList.fold<int>(0, (sum, c) {
        final cr = (c['credits'] as num?)?.toInt() ??
            (c['credit'] as num?)?.toInt() ??
            0;
        return sum + cr;
      });
    }

    // Parse or auto-calculate total self study hours from courses if missing or 0
    double parsedHours = (map['totalSelfStudyHours'] as num?)?.toDouble() ??
        (map['totalHours'] as num?)?.toDouble() ??
        (map['weeklyWorkloadHours'] as num?)?.toDouble() ??
        (map['selfStudyHours'] as num?)?.toDouble() ??
        (map['workloadHours'] as num?)?.toDouble() ??
        0.0;

    if (parsedHours == 0.0 && coursesList.isNotEmpty) {
      parsedHours = coursesList.fold<double>(0.0, (sum, c) {
        final h = (c['plannedSelfStudyHours'] as num?)?.toDouble() ??
            (c['defaultSelfStudyHours'] as num?)?.toDouble() ??
            (c['hours'] as num?)?.toDouble() ??
            (c['selfStudyHours'] as num?)?.toDouble() ??
            (c['weeklyHours'] as num?)?.toDouble() ??
            0.0;
        return sum + h;
      });
    }

    final rawUserId = map['userId'] as String? ?? '';

    String resolvedName = (map['studentName'] as String?)?.trim() ??
        (map['fullName'] as String?)?.trim() ??
        (map['displayName'] as String?)?.trim() ??
        '';

    String resolvedCode = (map['studentCode'] as String?)?.trim() ??
        (map['studentId'] as String?)?.trim() ??
        (map['mssv'] as String?)?.trim() ??
        '';

    String resolvedEmail = (map['studentEmail'] as String?)?.trim() ??
        (map['email'] as String?)?.trim() ??
        (map['userEmail'] as String?)?.trim() ??
        '';

    // Fallback thông tin persona mẫu theo userId
    if (rawUserId == 'student_se180504' || rawUserId.contains('se180504')) {
      if (resolvedName.isEmpty || resolvedName == 'Sinh viên' || resolvedName == 'Sinh viên mới') resolvedName = 'Trần Hoàng Long';
      if (resolvedCode.isEmpty) resolvedCode = 'SE180504';
      if (resolvedEmail.isEmpty) resolvedEmail = 'longth.se180504@gmail.com';
    } else if (rawUserId == 'student_se170123' || rawUserId.contains('se170123')) {
      if (resolvedName.isEmpty || resolvedName == 'Sinh viên' || resolvedName == 'Sinh viên mới') resolvedName = 'Nguyễn Mai Linh';
      if (resolvedCode.isEmpty) resolvedCode = 'SE170123';
      if (resolvedEmail.isEmpty) resolvedEmail = 'linhnm.se170123@gmail.com';
    } else if (rawUserId == 'student_se190456' || rawUserId.contains('se190456')) {
      if (resolvedName.isEmpty || resolvedName == 'Sinh viên' || resolvedName == 'Sinh viên mới') resolvedName = 'Lê Minh Tuấn';
      if (resolvedCode.isEmpty) resolvedCode = 'SE190456';
      if (resolvedEmail.isEmpty) resolvedEmail = 'tuanlm.se190456@gmail.com';
    }

    // Tự động trích xuất MSSV từ email hoặc userId nếu MSSV chưa có
    if (resolvedCode.isEmpty) {
      final codeMatch = RegExp(r'(se|sa|ss|sb|cs|ia|he|hs|ha|de)\d{5,7}', caseSensitive: false)
          .firstMatch('$rawUserId $resolvedEmail $resolvedName');
      if (codeMatch != null) {
        resolvedCode = codeMatch.group(0)!.toUpperCase();
      }
    }

    // Tự động nhận diện tên từ email nếu tên trống hoặc mặc định
    if ((resolvedName.isEmpty || resolvedName == 'Sinh viên' || resolvedName == 'Sinh viên mới') && resolvedEmail.isNotEmpty) {
      final prefix = resolvedEmail.split('@').first;
      resolvedName = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ').trim();
    }

    if (resolvedName.isEmpty || resolvedName == 'Sinh viên mới') {
      resolvedName = 'Sinh viên';
    }

    return StudyPlanModel(
      id: id,
      userId: rawUserId,
      studentName: resolvedName,
      studentCode: resolvedCode,
      studentEmail: resolvedEmail,
      semesterName: map['semesterName'] as String? ?? (map['semester'] as String? ?? 'Học kỳ'),
      courses: coursesList,
      totalCredits: parsedCredits,
      totalSelfStudyHours: parsedHours,
      maxSafeThresholdHours: (map['maxSafeThresholdHours'] as num?)?.toDouble() ??
          (map['safeThresholdHours'] as num?)?.toDouble() ??
          25.0,
      tuitionFee: (map['tuitionFee'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      reviewReason: map['reviewReason'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      submittedGrades: submittedGradesList,
    );
  }
}
