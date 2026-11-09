class AiPlanAdviceModel {
  final String provider; // 'gemini' | 'deepseek' | 'fallback_rule'
  final String riskLevel; // 'high' | 'medium' | 'safe'
  final String analysis;
  final String recommendedAction; // 'replace' | 'lower_target' | 'keep'
  final String? targetCourseCode;
  final String? suggestedCourseCode;
  final String? suggestedGradeTarget;
  final double estimatedHoursAfter;
  final String reason;
  final List<String> strategicTips;

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
  });

  bool get isGemini => provider == 'gemini';
  bool get isDeepSeek => provider == 'deepseek';
  bool get isFallbackRule => provider == 'fallback_rule';

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

    return AiPlanAdviceModel(
      provider: provider,
      riskLevel: (map['riskLevel'] as String?)?.toLowerCase() ?? 'high',
      analysis: map['analysis'] as String? ??
          'Kế hoạch học tập hiện tại cần được tối ưu lại thời gian tự học.',
      recommendedAction:
          (map['recommendedAction'] as String?)?.toLowerCase() ?? 'replace',
      targetCourseCode: map['targetCourseCode'] as String?,
      suggestedCourseCode: map['suggestedCourseCode'] as String?,
      suggestedGradeTarget: map['suggestedGradeTarget'] as String?,
      estimatedHoursAfter:
          (map['estimatedHoursAfter'] as num?)?.toDouble() ?? 26.0,
      reason: map['reason'] as String? ??
          'Hoán đổi sang môn học có khối lượng tự học nhẹ hơn để tránh kiệt sức.',
      strategicTips: tips,
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
    };
  }
}
