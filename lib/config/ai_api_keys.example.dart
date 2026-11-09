/// Mẫu file cấu hình API Keys cho các dịch vụ AI (Gemini & DeepSeek).
/// Hãy copy nội dung file này vào `lib/config/ai_api_keys.dart` và điền key của bạn.
class AiApiKeys {
  /// Google Gemini API Key:
  /// Lấy miễn phí tại Google AI Studio: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  /// DeepSeek API Key (Dùng làm Fallback khi Gemini quá tải hoặc hết hạn mức):
  /// Lấy tại DeepSeek Platform: https://platform.deepseek.com/api_keys
  static const String deepSeekApiKey = 'YOUR_DEEPSEEK_API_KEY_HERE';
}
