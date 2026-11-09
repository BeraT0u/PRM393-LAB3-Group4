import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;
import '../config/ai_api_keys.dart';
import '../models/ai_plan_advice_model.dart';
import '../models/course_model.dart';
import '../utils/app_logger.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';

class AiAdvisorService {
  final http.Client _httpClient;

  AiAdvisorService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Phân tích kế hoạch học tập với cơ chế Multi-AI Fallback:
  /// 1. Ưu tiên: Google Gemini (theo model từ Remote Config, mặc định gemini-3.8-flash)
  /// 2. Dự phòng 1: DeepSeek AI (deepseek-chat qua OpenAI-compatible API)
  /// 3. Dự phòng 2: EduPlan Local Rule Engine (Đảm bảo 100% không bao giờ crash nếu mất mạng/hết key)
  Future<AiPlanAdviceModel> analyzePlanAndAdvise({
    required PlanAnalyzerState state,
    required List<CourseModel> allCourses,
  }) async {
    // 1. Đọc Remote Config cấu hình AI
    bool isAiEnabled = true;
    String geminiModelName = 'gemini-3.8-flash';
    String systemPrompt =
        'Bạn là Cố vấn học tập đại học FPT chuyên ngành Kỹ thuật Phần mềm (SE). '
        'Hãy phân tích lộ trình học tập, phát hiện nguy cơ quá tải học tập (>25h tự học/tuần) '
        'và đề xuất giải pháp cân bằng thời gian tự học tối ưu.';

    try {
      if (Firebase.apps.isNotEmpty) {
        final rc = FirebaseRemoteConfig.instance;
        isAiEnabled = rc.getBool('ai_feature_enabled');
        final rcModel = rc.getString('ai_model_name');
        if (rcModel.trim().isNotEmpty) {
          geminiModelName = rcModel.trim();
        }
        final rcPrompt = rc.getString('ai_system_prompt');
        if (rcPrompt.trim().isNotEmpty) {
          systemPrompt = rcPrompt.trim();
        }
      }
    } catch (e) {
      AppLogger.warning('Không thể đọc Remote Config cho AI: $e');
    }

    if (!isAiEnabled) {
      AppLogger.info('AI feature đang bị tắt từ Remote Config. Sử dụng Rule Engine.');
      return _buildRuleEngineFallback(state, allCourses);
    }

    // 2. Chuẩn bị dữ liệu ẩn danh (Zero PII - Không gửi tên, email hay MSSV)
    final prompt = _buildAnonymousPrompt(state, allCourses, systemPrompt);

    // 3. Bước 1: Thử gọi Google Gemini API
    if (_isValidKey(AiApiKeys.geminiApiKey)) {
      try {
        AppLogger.info('Đang kết nối Google Gemini API (model: $geminiModelName)...');
        final geminiResult = await _callGeminiApi(
          modelName: geminiModelName,
          apiKey: AiApiKeys.geminiApiKey,
          prompt: prompt,
        );
        if (geminiResult != null) {
          AppLogger.info('Google Gemini phản hồi thành công!');
          final enriched = _enrichAdviceWithPlanDetails(geminiResult, state);
          if (state.isOverloaded &&
              (enriched.recommendedAction == 'keep' ||
                  enriched.estimatedHoursAfter > state.maxSafeThresholdHours)) {
            AppLogger.info(
              'Gemini khuyên giữ nguyên hoặc giờ vẫn quá tải (${enriched.estimatedHoursAfter}h > ${state.maxSafeThresholdHours}h). '
              'Tự động kích hoạt Rule Engine để tính toán giảm giờ chi tiết.',
            );
            return _buildRuleEngineFallback(state, allCourses);
          }
          return enriched;
        }
      } catch (e) {
        AppLogger.warning('Gemini API gọi không thành công: $e. Đang chuyển sang Fallback DeepSeek...');
      }
    } else {
      AppLogger.info('Gemini API Key chưa được cấu hình. Chuyển sang DeepSeek...');
    }

    // 4. Bước 2: Thử gọi DeepSeek API (Fallback)
    if (_isValidKey(AiApiKeys.deepSeekApiKey)) {
      try {
        AppLogger.info('Đang kết nối DeepSeek AI API (deepseek-chat)...');
        final deepSeekResult = await _callDeepSeekApi(
          apiKey: AiApiKeys.deepSeekApiKey,
          systemPrompt: systemPrompt,
          prompt: prompt,
        );
        if (deepSeekResult != null) {
          AppLogger.info('DeepSeek AI phản hồi thành công!');
          final enriched = _enrichAdviceWithPlanDetails(deepSeekResult, state);
          if (state.isOverloaded &&
              (enriched.recommendedAction == 'keep' ||
                  enriched.estimatedHoursAfter > state.maxSafeThresholdHours)) {
            AppLogger.info('DeepSeek khuyên giữ nguyên. Chuyển sang Rule Engine...');
            return _buildRuleEngineFallback(state, allCourses);
          }
          return enriched;
        }
      } catch (e) {
        AppLogger.warning('DeepSeek API gọi không thành công: $e. Chuyển sang Rule Engine cục bộ...');
      }
    } else {
      AppLogger.info('DeepSeek API Key chưa được cấu hình. Sử dụng Rule Engine cục bộ...');
    }

    // 5. Bước 3: Thuật toán quy tắc cục bộ (100% an toàn)
    return _buildRuleEngineFallback(state, allCourses);
  }

  bool _isValidKey(String key) {
    final k = key.trim();
    return k.isNotEmpty &&
        k != 'YOUR_GEMINI_API_KEY_HERE' &&
        k != 'YOUR_DEEPSEEK_API_KEY_HERE';
  }

  /// Gọi Gemini REST API với Structured JSON Output
  Future<AiPlanAdviceModel?> _callGeminiApi({
    required String modelName,
    required String apiKey,
    required String prompt,
  }) async {
    // Model fallback chain: ưu tiên model hiện tại được Google hỗ trợ (thế hệ 3.x)
    final modelsToTry = {
      modelName,
      'gemini-3.8-flash',
      'gemini-3.5-flash-lite',
      'gemini-flash-latest',
    }.toList();

    for (final currentModel in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent?key=$apiKey',
        );

        final requestBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'temperature': 0.2,
          }
        });

        final response = await _httpClient
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content']?['parts']?[0]?['text'] as String?;
            if (content != null && content.isNotEmpty) {
              final jsonText = _cleanJsonText(content);
              final map = jsonDecode(jsonText) as Map<String, dynamic>;
              return AiPlanAdviceModel.fromMap(map, provider: 'gemini');
            }
          }
        } else {
          AppLogger.warning('Gemini model $currentModel trả về status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        AppLogger.warning('Lỗi khi gọi model $currentModel: $e');
      }
    }
    return null;
  }

  /// Gọi DeepSeek Chat Completions API (OpenAI-compatible)
  Future<AiPlanAdviceModel?> _callDeepSeekApi({
    required String apiKey,
    required String systemPrompt,
    required String prompt,
  }) async {
    final url = Uri.parse('https://api.deepseek.com/chat/completions');

    final requestBody = jsonEncode({
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content': '$systemPrompt\nBạn bắt buộc phải trả lời duy nhất định dạng JSON thuần túy.',
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.2,
    });

    final response = await _httpClient
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = decoded['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices[0]['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          final jsonText = _cleanJsonText(content);
          final map = jsonDecode(jsonText) as Map<String, dynamic>;
          return AiPlanAdviceModel.fromMap(map, provider: 'deepseek');
        }
      }
    } else {
      AppLogger.warning('DeepSeek API trả về status ${response.statusCode}: ${response.body}');
    }
    return null;
  }

  /// Làm sạch chuỗi markdown code block ```json ... ```
  String _cleanJsonText(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  /// Bổ sung chi tiết các môn cần giảm giờ nếu model chỉ trả về adjustedHours
  AiPlanAdviceModel _enrichAdviceWithPlanDetails(
    AiPlanAdviceModel advice,
    PlanAnalyzerState state,
  ) {
    if (advice.isReduceHours &&
        advice.hoursReductions.isEmpty &&
        advice.adjustedHours.isNotEmpty) {
      final reductions = <Map<String, dynamic>>[];
      double newSum = 0.0;

      for (final c in state.plan.selectedCourses) {
        if (advice.adjustedHours.containsKey(c.code)) {
          final newH = advice.adjustedHours[c.code]!;
          final oldH = c.plannedSelfStudyHours;
          final saved = (oldH - newH);
          reductions.add({
            'code': c.code,
            'oldHours': oldH,
            'newHours': newH,
            'saved': saved > 0 ? ((saved * 2).round() / 2.0) : 0.0,
          });
          newSum += newH;
        } else {
          newSum += c.plannedSelfStudyHours;
        }
      }

      return AiPlanAdviceModel(
        provider: advice.provider,
        riskLevel: newSum <= state.maxSafeThresholdHours ? 'safe' : 'medium',
        analysis: advice.analysis,
        recommendedAction: advice.recommendedAction,
        targetCourseCode: advice.targetCourseCode,
        suggestedCourseCode: advice.suggestedCourseCode,
        suggestedGradeTarget: advice.suggestedGradeTarget,
        estimatedHoursAfter: newSum,
        reason: advice.reason,
        strategicTips: advice.strategicTips,
        adjustedHours: advice.adjustedHours,
        hoursReductions: reductions,
      );
    }
    return advice;
  }

  /// Tạo prompt ẩn danh chuẩn kỹ thuật (No PII) với chỉ dẫn nghiêm ngặt ưu tiên giảm giờ học
  String _buildAnonymousPrompt(
    PlanAnalyzerState state,
    List<CourseModel> allCourses,
    String systemPrompt,
  ) {
    final selectedCoursesData = state.plan.selectedCourses.map((c) => {
          'code': c.code,
          'name': c.name,
          'credits': c.credits,
          'plannedSelfStudyHours': c.plannedSelfStudyHours,
          'selectedGradeTarget': c.selectedGradeTarget,
          'prerequisiteCode': c.prerequisiteCode,
        }).toList();

    // Các môn trong catalog mà sinh viên đủ điều kiện tiên quyết và chưa chọn
    final eligibleCatalog = allCourses.where((c) {
      final notSelected = !state.plan.selectedCourses.any((sc) => sc.code == c.code);
      final prereqMet = c.prerequisiteCode == null ||
          state.passedCourseCodes.contains(c.prerequisiteCode);
      return notSelected && prereqMet;
    }).map((c) => {
          'code': c.code,
          'name': c.name,
          'credits': c.credits,
          'defaultHours': c.defaultSelfStudyHours,
        }).take(6).toList();

    return '''
$systemPrompt

Dưới đây là thông số học tập ẩn danh của sinh viên:
- Các môn đã hoàn thành (tiên quyết đã đạt): ${jsonEncode(state.passedCourseCodes)}
- Danh sách môn sinh viên đang chọn cho học kỳ:
${jsonEncode(selectedCoursesData)}
- Tổng số giờ tự học hiện tại: ${state.totalHours} giờ/tuần
- Ngưỡng an toàn khuyến cáo: ${state.maxSafeThresholdHours} giờ/tuần
- Danh sách môn thay thế khả dụng (đủ tiên quyết):
${jsonEncode(eligibleCatalog)}

QUY TẮC BẮT BUỘC KHI PHÂN TÍCH (TUÂN THỦ THEO ĐÚNG THỨ TỰ ƯU TIÊN):
1. ƯU TIÊN SỐ 1 (KHI QUÁ TẢI TỪ ${state.maxSafeThresholdHours}h ĐẾN 31h/TUẦN VÀ KHÔNG BỊ LỖI TIÊN QUYẾT):
   - BẮT BUỘC chọn "recommendedAction": "reduce_hours".
   - Bạn PHẢI đề xuất GIẢM GIỜ TỰ HỌC của các môn học đang chiếm nhiều giờ nhất (>= 7h/tuần).
   - "adjustedHours": { "MÃ_MÔN_1": GIỜ_MỚI, "MÃ_MÔN_2": GIỜ_MỚI }
   - "hoursReductions": [
       { "code": "MÃ_MÔN_1", "oldHours": GIỜ_CŨ, "newHours": GIỜ_MỚI, "saved": SỐ_GIỜ_GIẢM }
     ]
   - BẮT BUỘC: Tổng số giờ sau khi giảm ("estimatedHoursAfter") PHẢI NHỎ HƠN HOẶC BẰNG 24.5 giờ/tuần!
   - Trong "reason" và "analysis": Nêu ĐÍCH DANH mã môn học và mức giảm cụ thể (ví dụ: "Giảm giờ tự học môn A từ 8h xuống 6h (-2h), môn B từ 7h xuống 5.5h (-1.5h) để đưa tổng giờ về 23.5h/tuần").
   - KHÔNG ĐƯỢC khuyên "giữ nguyên" hay "keep" khi tổng giờ > ${state.maxSafeThresholdHours}h.

2. ƯU TIÊN SỐ 2 (KHI CỰC KỲ QUÁ TẢI > 31h/TUẦN HOẶC CÓ MÔN VI PHẠM ĐIỀU KIỆN TIÊN QUYẾT):
   - Nếu có môn vi phạm tiên quyết hoặc số giờ quá tải cực lớn không thể cân bằng bằng giảm giờ:
     Chọn "recommendedAction": "replace" (hoán đổi sang môn nhẹ hơn trong danh sách môn khả dụng) HOẶC "drop" (bớt 1 môn sang kỳ sau).
   - Chỉ rõ "targetCourseCode" (môn cần thay/bỏ) và "suggestedCourseCode" (môn thay thế).
   - "estimatedHoursAfter" cũng BẮT BUỘC PHẢI <= 25.0 giờ/tuần.

3. TRƯỜNG HỢP KẾ HOẠCH ĐÃ CÂN BẰNG (<= ${state.maxSafeThresholdHours}h/tuần và hợp lệ tiên quyết):
   - "recommendedAction": "keep", "estimatedHoursAfter": ${state.totalHours}.

Hãy phân tích và trả về DUY NHẤT một chuỗi JSON hợp lệ theo cấu trúc sau (không kèm văn bản thừa ngoài JSON):
{
  "riskLevel": "high" hoặc "safe",
  "analysis": "Lời nhận xét chi tiết về lộ trình kỳ học và cảnh báo quá tải",
  "recommendedAction": "reduce_hours" hoặc "replace" hoặc "drop" hoặc "keep",
  "targetCourseCode": "Mã môn cần thay đổi hoặc bớt (nếu action là replace/drop, ngược lại null)",
  "suggestedCourseCode": "Mã môn thay thế (nếu action là replace, ngược lại null)",
  "suggestedGradeTarget": "Mục tiêu điểm gợi ý (ví dụ: B)",
  "estimatedHoursAfter": 24.0,
  "adjustedHours": {
    "MÃ_MÔN": 6.0
  },
  "hoursReductions": [
    {
      "code": "MÃ_MÔN",
      "oldHours": 8.0,
      "newHours": 6.0,
      "saved": 2.0
    }
  ],
  "reason": "Giải thích chi tiết môn nào được giảm bao nhiêu giờ và tổng giờ sau giảm",
  "strategicTips": [
    "Mẹo 1 phân bổ thời gian học tập",
    "Mẹo 2 chuẩn bị đồ án môn học"
  ]
}
''';
  }

  /// Thuật toán quy tắc cục bộ (Offline / Fallback Rule)
  AiPlanAdviceModel _buildRuleEngineFallback(
    PlanAnalyzerState state,
    List<CourseModel> allCourses,
  ) {
    // 1. Kiểm tra lỗi môn tiên quyết bắt buộc trước
    final prereqConflictCourse = state.plan.selectedCourses.cast<CourseModel?>().firstWhere(
      (c) =>
          c != null &&
          c.prerequisiteCode != null &&
          !state.passedCourseCodes.contains(c.prerequisiteCode),
      orElse: () => null,
    );

    if (prereqConflictCourse != null) {
      // Có môn vi phạm tiên quyết -> BẮT BUỘC ĐỔI MÔN (replace)
      CourseModel? suggestedCourse;
      for (final c in allCourses) {
        if (c.code != prereqConflictCourse.code &&
            !state.plan.selectedCourses.any((sc) => sc.code == c.code)) {
          final prereqMet = c.prerequisiteCode == null ||
              state.passedCourseCodes.contains(c.prerequisiteCode);
          if (prereqMet && c.defaultSelfStudyHours <= 6.0) {
            suggestedCourse = c;
            break;
          }
        }
      }

      final suggestedCode = suggestedCourse?.code ?? 'PRM323';
      final suggestedHours = suggestedCourse?.defaultSelfStudyHours ?? 4.0;
      final conflictHours = prereqConflictCourse.plannedSelfStudyHours;
      final calculatedAfter =
          (state.totalHours - conflictHours + suggestedHours).clamp(12.0, 35.0);

      return AiPlanAdviceModel(
        provider: 'fallback_rule',
        riskLevel: 'high',
        analysis:
            'Phát hiện môn ${prereqConflictCourse.code} (${prereqConflictCourse.name}) '
            'chưa hoàn thành môn tiên quyết bắt buộc [${prereqConflictCourse.prerequisiteCode}]. '
            'Bạn không đủ điều kiện học môn này trong kỳ hiện tại.',
        recommendedAction: 'replace',
        targetCourseCode: prereqConflictCourse.code,
        suggestedCourseCode: suggestedCode,
        suggestedGradeTarget: 'B',
        estimatedHoursAfter: calculatedAfter,
        reason:
            'Hoán đổi môn ${prereqConflictCourse.code} sang môn thay thế $suggestedCode '
            '(khối lượng nhẹ ${suggestedHours.toInt()}h/tuần, đủ điều kiện tiên quyết) '
            'giúp đưa tổng giờ tự học về ${calculatedAfter.toInt()}h/tuần (Cân bằng ✅).',
        strategicTips: [
          'Học trước môn tiên quyết ${prereqConflictCourse.prerequisiteCode} ở kỳ sau để kịp tiến độ chuyên ngành.',
          'Dành thêm thời gian ôn tập nền tảng trước khi đăng ký lại môn ${prereqConflictCourse.code}.',
        ],
      );
    }

    // 2. Không vi phạm tiên quyết: Kiểm tra quá tải giờ tự học
    if (state.isOverloaded) {
      final totalH = state.totalHours;

      // TRƯỜNG HỢP 1: ƯU TIÊN HÀNG ĐẦU -> GIẢM GIỜ TỰ HỌC CÁC MÔN NẶNG (khi <= 31.5h)
      if (totalH <= 31.5) {
        const double targetSafeTotal = 24.0;
        final double neededReduction = totalH - targetSafeTotal;

        final sortedCourses = List<CourseModel>.from(state.plan.selectedCourses)
          ..sort((a, b) => b.plannedSelfStudyHours.compareTo(a.plannedSelfStudyHours));

        final adjustedHours = <String, double>{};
        final hoursReductions = <Map<String, dynamic>>[];
        double remainingReduction = neededReduction;

        for (final c in sortedCourses) {
          if (remainingReduction <= 0) break;
          // Mức sàn giờ tự học tối thiểu cho mỗi môn
          final double minFloor = (c.credits * 1.5).clamp(3.0, 5.0);
          final double maxCanReduce = (c.plannedSelfStudyHours - minFloor).clamp(0.0, 10.0);
          if (maxCanReduce <= 0) continue;

          double reduceAmount = remainingReduction > maxCanReduce ? maxCanReduce : remainingReduction;
          reduceAmount = (reduceAmount * 2).round() / 2.0; // Làm tròn bước 0.5h
          if (reduceAmount <= 0) continue;

          final double newHours = c.plannedSelfStudyHours - reduceAmount;
          adjustedHours[c.code] = newHours;
          hoursReductions.add({
            'code': c.code,
            'oldHours': c.plannedSelfStudyHours,
            'newHours': newHours,
            'saved': reduceAmount,
          });
          remainingReduction -= reduceAmount;
        }

        if (hoursReductions.isNotEmpty) {
          final totalReduced = hoursReductions.fold<double>(
            0.0,
            (acc, r) => acc + (r['saved'] as double),
          );
          final double calculatedAfter = (totalH - totalReduced).clamp(12.0, 25.0);

          final reductionDesc = hoursReductions
              .map((r) =>
                  '${r['code']} (giảm từ ${r['oldHours']}h xuống ${r['newHours']}h/tuần, -${r['saved']}h)')
              .join('; ');

          return AiPlanAdviceModel(
            provider: 'fallback_rule',
            riskLevel: 'high',
            analysis:
                'Tổng khối lượng tự học hiện tại là ${totalH.toStringAsFixed(1)}h/tuần, '
                'vượt ngưỡng an toàn khuyến cáo (${state.maxSafeThresholdHours.toInt()}h/tuần). '
                'Các môn học đều đạt điều kiện tiên quyết, giải pháp tối ưu là điều chỉnh giảm bớt thời lượng tự học của các môn nặng.',
            recommendedAction: 'reduce_hours',
            estimatedHoursAfter: calculatedAfter,
            adjustedHours: adjustedHours,
            hoursReductions: hoursReductions,
            reason:
                'Điều chỉnh giảm thời gian tự học: $reductionDesc. '
                'Giúp hạ tổng khối lượng tự học về ${calculatedAfter.toStringAsFixed(1)}h/tuần, đạt chuẩn cân bằng an toàn.',
            strategicTips: [
              'Tối ưu hóa thời gian bằng phương pháp Pomodoro và học nhóm để hoàn thành bài tập nhanh hơn.',
              'Tận dụng tài liệu tóm tắt và slide bài giảng để nắm chắc cốt lõi thay vì phân bổ quá nhiều giờ tự bơi.',
            ],
          );
        }
      }

      // TRƯỜNG HỢP 2: CỰC KỲ QUÁ TẢI (> 31.5h) -> Gợi ý Đổi môn nhẹ hơn hoặc Bớt môn
      final heaviestCourse = state.plan.selectedCourses.reduce(
        (a, b) => a.plannedSelfStudyHours >= b.plannedSelfStudyHours ? a : b,
      );

      // Tìm môn thay thế nhẹ trong catalog
      CourseModel? lightCourse;
      for (final c in allCourses) {
        if (c.code != heaviestCourse.code &&
            !state.plan.selectedCourses.any((sc) => sc.code == c.code)) {
          final prereqMet = c.prerequisiteCode == null ||
              state.passedCourseCodes.contains(c.prerequisiteCode);
          if (prereqMet && c.defaultSelfStudyHours <= 5.0) {
            lightCourse = c;
            break;
          }
        }
      }

      if (lightCourse != null) {
        final afterSwap =
            (totalH - heaviestCourse.plannedSelfStudyHours + lightCourse.defaultSelfStudyHours);
        if (afterSwap <= state.maxSafeThresholdHours + 1.0) {
          return AiPlanAdviceModel(
            provider: 'fallback_rule',
            riskLevel: 'high',
            analysis:
                'Kế hoạch bị cực kỳ quá tải (${totalH.toStringAsFixed(1)}h/tuần >> 25h). '
                'Môn ${heaviestCourse.code} chiếm tới ${heaviestCourse.plannedSelfStudyHours.toInt()}h tự học gây nguy cơ kiệt sức.',
            recommendedAction: 'replace',
            targetCourseCode: heaviestCourse.code,
            suggestedCourseCode: lightCourse.code,
            suggestedGradeTarget: 'B',
            estimatedHoursAfter: afterSwap,
            reason:
                'Đổi môn nặng ${heaviestCourse.code} sang môn ${lightCourse.code} (${lightCourse.defaultSelfStudyHours.toInt()}h) '
                'giúp giảm ${heaviestCourse.plannedSelfStudyHours.toInt() - lightCourse.defaultSelfStudyHours.toInt()}h tự học, '
                'đưa tổng tải về ${afterSwap.toInt()}h/tuần (Cân bằng ✅).',
            strategicTips: [
              'Dời môn ${heaviestCourse.code} sang kỳ học có khối lượng nhẹ hơn để tập trung đạt điểm cao.',
            ],
          );
        }
      }

      // Nếu không có môn thay thế phù hợp hoặc đã quá nhiều môn -> Bớt 1 môn
      final afterDrop = totalH - heaviestCourse.plannedSelfStudyHours;
      return AiPlanAdviceModel(
        provider: 'fallback_rule',
        riskLevel: 'high',
        analysis:
            'Kế hoạch đăng ký quá nhiều môn gây cực kỳ quá tải (${totalH.toStringAsFixed(1)}h/tuần). '
            'Việc giảm giờ không đủ để đảm bảo chất lượng tiếp thu kiến thức.',
        recommendedAction: 'drop',
        targetCourseCode: heaviestCourse.code,
        estimatedHoursAfter: afterDrop,
        reason:
            'Bớt môn ${heaviestCourse.code} (${heaviestCourse.plannedSelfStudyHours.toInt()}h tự học) '
            'chuyển sang kỳ học tiếp theo, đưa tổng tải về ${afterDrop.toInt()}h/tuần an toàn.',
        strategicTips: [
          'Học kỳ chỉ nên đăng ký từ 12 đến 15 tín chỉ để cân bằng giữa học tập và các hoạt động phát triển cá nhân.',
        ],
      );
    }

    // 3. Kế hoạch hợp lệ và cân bằng tốt
    return AiPlanAdviceModel(
      provider: 'fallback_rule',
      riskLevel: 'safe',
      analysis:
          'Kế hoạch học tập hiện tại của bạn đã rất cân đối (${state.totalHours.toInt()}h/tuần <= 25h) '
          'và đáp ứng đầy đủ tất cả các điều kiện tiên quyết.',
      recommendedAction: 'keep',
      estimatedHoursAfter: state.totalHours,
      reason: 'Tiếp tục duy trì kế hoạch học tập hiện tại để đạt tiến độ chương trình.',
      strategicTips: [
        'Duy trì lịch tự học cố định mỗi ngày để đạt mục tiêu GPA ${state.plan.targetGpa > 0 ? state.plan.targetGpa.toStringAsFixed(1) : '3.6+'}!',
      ],
    );
  }
}
