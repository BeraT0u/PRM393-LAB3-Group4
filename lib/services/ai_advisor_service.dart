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
          return geminiResult;
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
          return deepSeekResult;
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

  /// Tạo prompt ẩn danh chuẩn kỹ thuật (No PII)
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

Hãy phân tích và trả về DUY NHẤT một chuỗi JSON hợp lệ theo cấu trúc sau (không kèm văn bản thừa ngoài JSON):
{
  "riskLevel": "high" (nếu >25h hoặc lỗi tiên quyết) hoặc "safe",
  "analysis": "Lời nhận xét chi tiết về lộ trình kỳ học",
  "recommendedAction": "replace" (hoán đổi môn) hoặc "lower_target" (hạ điểm mục tiêu) hoặc "keep",
  "targetCourseCode": "Mã môn cần thay đổi (ví dụ: IAE201)",
  "suggestedCourseCode": "Mã môn thay thế gợi ý (ví dụ: PRM323)",
  "suggestedGradeTarget": "Mục tiêu điểm gợi ý (A, B hoặc Qua môn)",
  "estimatedHoursAfter": 26.0,
  "reason": "Lý do vì sao phương án này giúp cân bằng giờ tự học",
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
    final conflictCourse = state.conflictCourse;
    String targetCode = conflictCourse?.code ?? 'IAE201';

    // Tìm môn thay thế tối ưu trong catalog
    CourseModel? suggestedCourse;
    for (final c in allCourses) {
      if (c.code != targetCode &&
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
    final conflictHours = conflictCourse?.plannedSelfStudyHours ?? 12.0;
    final calculatedAfter =
        (state.totalHours - conflictHours + suggestedHours).clamp(15.0, 40.0);

    return AiPlanAdviceModel(
      provider: 'fallback_rule',
      riskLevel: state.hasConflict ? 'high' : 'safe',
      analysis: state.isOverloaded
          ? 'Kế hoạch học tập hiện tại bị quá tải (${state.totalHours.toInt()}h/tuần > ${state.maxSafeThresholdHours.toInt()}h). '
              'Môn $targetCode chiếm thời lượng tự học lớn gây áp lực cao.'
          : 'Kế hoạch học tập đang ở mức cân đối tốt.',
      recommendedAction: 'replace',
      targetCourseCode: targetCode,
      suggestedCourseCode: suggestedCode,
      suggestedGradeTarget: 'B',
      estimatedHoursAfter: calculatedAfter,
      reason:
          'Hoán đổi $targetCode sang môn $suggestedCode giúp giảm ${conflictHours.toInt() - suggestedHours.toInt()}h tự học mỗi tuần, '
          'đưa khối lượng tự học về mức an toàn (${calculatedAfter.toInt()}h/tuần) mà vẫn đảm bảo tiến độ tích lũy tín chỉ.',
      strategicTips: [
        'Ưu tiên hoàn thành các bài thực hành và đồ án sớm ngay trong 4 tuần đầu.',
        'Duy trì thời gian tự học đều đặn mỗi ngày, tránh dồn bài tập vào tuần thi cuối kỳ.',
      ],
    );
  }
}
