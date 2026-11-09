class AiPlanAdviceModel {
  final String provider; // 'gemini' | 'deepseek' | 'fallback_rule'
  final String riskLevel; // 'high' | 'medium' | 'safe'
  final String analysis;
  final String recommendedAction; // 'reduce_hours' | 'replace' | 'drop' | 'keep'
  final String? targetCourseCode;
  final String? suggestedCourseCode;
  final String? suggestedGradeTarget;
  final double estimatedHoursAfter;
  final String reason;
  final List<String> strategicTips;
  final Map<String, double> adjustedHours; // Map { 'Mã môn': giờ_tự_học_mới }
  final List<Map<String, dynamic>> hoursReductions; // [ {'code': '...', 'oldHours': 8.0, 'newHours': 5.5, 'saved': 2.5} ]

  const AiPlanAdviceModel({
    required this.provider,
    required this.riskLevel,
    required this.analysis,
    required this.recommendedAction,
    this.targetCourseCode,
    this.suggestedCourseCode,
    this.suggestedGradeTarget,
    required this.estimatedHoursAfter,
    required this.reason,
    this.strategicTips = const [],
    this.adjustedHours = const {},
    this.hoursReductions = const [],
  });

  bool get isGemini => provider == 'gemini';
  bool get isDeepSeek => provider == 'deepseek';
  bool get isFallbackRule => provider == 'fallback_rule';

  bool get isReduceHours =>
      recommendedAction == 'reduce_hours' ||
      recommendedAction == 'lower_target' ||
      adjustedHours.isNotEmpty;
  bool get isReplace => recommendedAction == 'replace';
  bool get isDrop => recommendedAction == 'drop' || recommendedAction == 'remove';

  String get providerDisplayName {
    switch (provider) {
      case 'gemini':
        return 'Google Gemini 3.8 Flash';
      case 'deepseek':
        return 'DeepSeek-V3 AI';
      case 'fallback_rule':
      default:
        return 'EduPlan Rule Engine';
    }
  }

  factory AiPlanAdviceModel.fromMap(
    Map<String, dynamic> map, {
    required String provider,
  }) {
    final tipsRaw = map['strategicTips'];
    final tips = tipsRaw is List
        ? tipsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final rawAdjusted = map['adjustedHours'];
    final adjustedHours = <String, double>{};
    if (rawAdjusted is Map) {
      rawAdjusted.forEach((k, v) {
        final val = (v as num?)?.toDouble();
        if (val != null) {
          adjustedHours[k.toString()] = val;
        }
      });
    }

    final rawReductions = map['hoursReductions'];
    final hoursReductions = <Map<String, dynamic>>[];
    if (rawReductions is List) {
      for (final r in rawReductions) {
        if (r is Map) {
          hoursReductions.add({
            'code': r['code']?.toString() ?? '',
            'name': r['name']?.toString() ?? '',
            'currentGrade': r['currentGrade']?.toString() ?? 'Điểm A',
            'suggestedGrade': r['suggestedGrade']?.toString() ?? 'Điểm B',
            'oldHours': (r['oldHours'] as num?)?.toDouble() ?? 0.0,
            'newHours': (r['newHours'] as num?)?.toDouble() ?? 0.0,
            'saved': (r['saved'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }
    }

    // Tự động phân loại action nếu model trả về reduce_hours
    String action = (map['recommendedAction'] as String?)?.toLowerCase() ?? 'reduce_hours';
    if (adjustedHours.isNotEmpty && action != 'replace' && action != 'drop') {
      action = 'reduce_hours';
    }

    return AiPlanAdviceModel(
      provider: provider,
      riskLevel: (map['riskLevel'] as String?)?.toLowerCase() ?? 'high',
      analysis: map['analysis'] as String? ??
          'Kế hoạch học tập hiện tại cần được tối ưu lại thời gian tự học.',
      recommendedAction: action,
      targetCourseCode: map['targetCourseCode'] as String?,
      suggestedCourseCode: map['suggestedCourseCode'] as String?,
      suggestedGradeTarget: map['suggestedGradeTarget'] as String?,
      estimatedHoursAfter:
          (map['estimatedHoursAfter'] as num?)?.toDouble() ?? 24.0,
      reason: map['reason'] as String? ??
          'Điều chỉnh giảm thời lượng tự học các môn nặng để đưa về ngưỡng an toàn.',
      strategicTips: tips,
      adjustedHours: adjustedHours,
      hoursReductions: hoursReductions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'riskLevel': riskLevel,
      'analysis': analysis,
      'recommendedAction': recommendedAction,
      'targetCourseCode': targetCourseCode,
      'suggestedCourseCode': suggestedCourseCode,
      'suggestedGradeTarget': suggestedGradeTarget,
      'estimatedHoursAfter': estimatedHoursAfter,
      'reason': reason,
      'strategicTips': strategicTips,
      'adjustedHours': adjustedHours,
      'hoursReductions': hoursReductions,
    };
  }
}
