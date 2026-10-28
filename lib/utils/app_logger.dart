import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[EduPlan INFO] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[EduPlan ⚠️ WARNING] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[EduPlan 🛑 ERROR] $message: $error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
